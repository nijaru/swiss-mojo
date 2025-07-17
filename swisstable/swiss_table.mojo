# ===----------------------------------------------------------------------=== #
# Copyright 2025 Nick Russo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #

"""Pure performance SwissTable implementation for Mojo.

This module provides `SwissTable`, a high-performance hash table that implements
the Swiss table design optimized for maximum speed. This is the "pure" Swiss table
algorithm as originally designed, without Dict compatibility overhead.

SwissTable separates metadata (control bytes) from data (key-value pairs),
allowing SIMD instructions to scan multiple slots simultaneously. This design
provides:

- O(1) average-case lookup, insertion, and deletion
- Cache-friendly memory layout with metadata locality
- SIMD-optimized scanning of 8-16 slots per instruction
- Load factor of 7/8 for improved memory efficiency
- Minimal memory overhead and maximum performance

Key elements must implement the `KeyElement` trait. Value elements must be 
Copyable and Movable.

Example usage:
```mojo
var table = SwissTable[String, Int]()
_ = table.insert("hello", 42)
_ = table.insert("world", 100)

var value = table.lookup("hello")  # Returns Optional[Int]
if value:
    print(value.value())  # Prints: 42

var size = table.size()  # Returns: 2
```

This implementation focuses solely on maximum performance.
"""

from collections import KeyElement, Optional
from builtin.len import Sized
from memory import UnsafePointer, memcpy
from os import abort
from .hash import EMPTY, DELETED, SENTINEL, make_ctrl_byte, is_full
from .hash import HashFunction, MojoHashFunction
from .unified_ops import specialized_hash, unified_lookup, unified_find_slot, unified_delete, unified_resize_insert
# Removed simple_ops import - using unified_ops for all operations
from .data_structures import DictEntry
from .iterators import SwissTableKeyIterator, SwissTableValueIterator, SwissTableItemIterator


struct SwissTable[K: KeyElement, V: Copyable & Movable, H: HashFunction = MojoHashFunction](Movable, Sized, Copyable):
    """A high-performance hash table using Swiss table design optimized for maximum speed.

    SwissTable provides O(1) average-case performance for insertion, lookup, and
    deletion operations through a cache-friendly memory layout and parallel
    metadata scanning. This is the pure Swiss table algorithm without Dict
    compatibility overhead.

    Memory layout: [control_bytes][padding][slots]
    - control_bytes: 1-byte metadata per slot (empty=255, deleted=128, full=0-127)
    - padding: EMPTY bytes for SIMD safety and alignment
    - slots: Key-value pairs stored in flat array

    Performance characteristics:
    - Average case: O(1) insertion, lookup, deletion
    - Worst case: O(n) under adversarial hash collisions
    - Load factor: 7/8 (87.5%) before resize
    - Memory overhead: ~12.5% for metadata + alignment

    Thread safety: SwissTable is not thread-safe. External synchronization
    is required for concurrent access.

    Parameters:
        K: Key type that must implement KeyElement trait.
        V: Value type that must be Copyable and Movable.
        H: Hash function type (defaults to MojoHashFunction).
    """
    
    # PERFORMANCE OPTIMIZATION: Minimal field layout for cache efficiency
    # Pack frequently accessed fields together in memory
    var _capacity: Int32        # Table capacity (smaller int for cache efficiency)
    var _size: Int32           # Current number of elements  
    var _growth_left: Int32    # Slots available before resize
    var _bucket_mask: Int32    # capacity - 1, for fast modulo
    
    # Memory pointers (accessed less frequently)
    var _control_bytes: UnsafePointer[UInt8]
    var _slots: UnsafePointer[DictEntry[K, V]]
    
    # Hash function (cold field)
    var _hasher: H

    # Simplified: single algorithm for all table sizes
    alias GROUP_WIDTH = 16  # Still needed for memory allocation padding


    fn __init__(out self, hasher: H):
        """Initialize an empty Swiss table with default capacity.

        Creates a new SwissTable with an initial capacity of 16 slots,
        optimized for maximum performance.

        Args:
            hasher: Hash function instance.
        """
        # Initialize with efficient defaults
        self._capacity = 0
        self._size = 0  
        self._growth_left = 0
        self._bucket_mask = 0
        self._control_bytes = UnsafePointer[UInt8]()
        self._slots = UnsafePointer[DictEntry[K, V]]()
        self._hasher = hasher
        
        # Allocate initial capacity - start small for optimization
        self._allocate_table(16)

    
    fn __init__(out self, capacity: Int, hasher: H):
        """Initialize an empty Swiss table with specified capacity.

        Args:
            capacity: Minimum number of slots to allocate.
            hasher: Hash function instance.
        """
        # Initialize core fields
        self._capacity = 0
        self._size = 0
        self._growth_left = 0
        self._bucket_mask = 0
        self._control_bytes = UnsafePointer[UInt8]()
        self._slots = UnsafePointer[DictEntry[K, V]]()
        self._hasher = hasher
        
        # Allocate requested capacity
        var target_capacity = self._normalize_capacity(capacity)
        self._allocate_table(target_capacity)

    fn __moveinit__(out self, owned existing: Self):
        """Move constructor."""
        # Transfer all fields directly
        self._capacity = existing._capacity
        self._size = existing._size
        self._growth_left = existing._growth_left
        self._bucket_mask = existing._bucket_mask
        self._control_bytes = existing._control_bytes
        self._slots = existing._slots
        self._hasher = existing._hasher^
        
        # Reset existing to safe state
        existing._capacity = 0
        existing._size = 0
        existing._growth_left = 0
        existing._bucket_mask = 0
        existing._control_bytes = UnsafePointer[UInt8]()
        existing._slots = UnsafePointer[DictEntry[K, V]]()

    fn __copyinit__(out self, existing: Self):
        """Copy constructor - creates a deep copy of the table."""
        # Initialize basic fields
        self._capacity = existing._capacity
        self._size = existing._size
        self._growth_left = existing._growth_left
        self._bucket_mask = existing._bucket_mask
        self._hasher = existing._hasher
        
        # Allocate new memory
        if existing._capacity > 0:
            # Allocate control bytes
            var ctrl_size = Int(existing._capacity) + Self.GROUP_WIDTH
            self._control_bytes = UnsafePointer[UInt8].alloc(ctrl_size)
            
            # Copy control bytes
            for i in range(ctrl_size):
                self._control_bytes[i] = existing._control_bytes[i]
            
            # Allocate and copy slots
            self._slots = UnsafePointer[DictEntry[K, V]].alloc(Int(existing._capacity))
            for i in range(Int(existing._capacity)):
                if is_full(existing._control_bytes[i]):  # FIXED: Use proper is_full check
                    var entry = existing._slots[i]
                    (self._slots + i).init_pointee_copy(entry)
        else:
            self._control_bytes = UnsafePointer[UInt8]()
            self._slots = UnsafePointer[DictEntry[K, V]]()

    fn __del__(owned self):
        """Clean up allocated memory."""
        if self._control_bytes:
            self._control_bytes.free()
        if self._slots:
            self._slots.free()

    @always_inline
    fn size(self) -> Int:
        """Return the number of elements in the table."""
        return Int(self._size)

    @always_inline  
    fn capacity(self) -> Int:
        """Return the current capacity of the table."""
        return Int(self._capacity)

    @always_inline
    fn is_empty(self) -> Bool:
        """Return True if the table contains no elements."""
        return self._size == 0

    fn clear(mut self):
        """Remove all elements from the table."""
        if self._control_bytes:
            # Reset all control bytes to EMPTY
            for i in range(self._capacity):
                self._control_bytes[i] = EMPTY
            self._size = 0
            self._growth_left = Int32((Int(self._capacity) * 7) // 8)  # 7/8 load factor

    @always_inline
    fn insert(mut self, owned key: K, owned value: V) -> Bool:
        """Insert key-value pair into table.

        Args:
            key: The key to insert.
            value: The value to associate with the key.

        Returns:
            True if the key was newly inserted, False if updated.
        """
        return self._insert(key^, value^, False)

    @always_inline  
    fn lookup(self, key: K) -> Optional[V]:
        """Look up value for key.

        Args:
            key: The key to look up.

        Returns:
            Optional containing the value if found, None otherwise.
        """
        return self._lookup_readonly(key)

    @always_inline
    fn delete(mut self, key: K) -> Bool:
        """Delete key from table.

        Args:
            key: The key to delete.

        Returns:
            True if the key was deleted, False if not found.
        """
        return self._delete(key)

    @always_inline
    fn get(self, key: K, default: V) -> V:
        """Get value for key with default fallback.
        
        Args:
            key: The key to look up.
            default: Value to return if key not found.
            
        Returns:
            The value for the key, or default if not found.
        """
        var result = self.lookup(key)
        if result:
            return result.value()
        else:
            return default

    @always_inline
    fn contains(self, key: K) -> Bool:
        """Check if key exists in table.
        
        Args:
            key: The key to check for.
            
        Returns:
            True if key exists, False otherwise.
        """
        var result = self.lookup(key)
        return result.__bool__()

    @always_inline
    fn __len__(self) -> Int:
        """Return number of elements for len() builtin."""
        return self.size()

    @always_inline
    fn __bool__(self) -> Bool:
        """Return True if table is non-empty."""
        return not self.is_empty()

    fn pop(mut self, key: K, default: V) -> V:
        """Remove and return value for key with default fallback.
        
        Args:
            key: The key to remove.
            default: Value to return if key not found.
            
        Returns:
            The value for the key, or default if not found.
        """
        var result = self.lookup(key)
        if result:
            var value = result.value()
            _ = self.delete(key)
            return value
        else:
            return default

    fn reserve(mut self, min_capacity: Int):
        """Pre-allocate capacity to avoid resizes.
        
        Args:
            min_capacity: Minimum capacity to ensure.
        """
        if min_capacity > Int(self._capacity):
            var target_capacity = self._normalize_capacity(min_capacity)
            if target_capacity > Int(self._capacity):
                self._resize_to_capacity(target_capacity)

    # ===----------------------------------------------------------------------=== #
    # Dict API Compatibility Methods
    # ===----------------------------------------------------------------------=== #

    @always_inline
    fn __getitem__(self, key: K) raises -> V:
        """Get value for key, raising KeyError if not found (Dict API compatibility).
        
        Args:
            key: The key to look up.
            
        Returns:
            The value associated with the key.
            
        Raises:
            Error: If key is not found.
        """
        var result = self.lookup(key)
        if result:
            return result.value()
        else:
            raise Error("KeyError: key not found in SwissTable (size=" + String(Int(self._size)) + ")")

    @always_inline
    fn __setitem__(mut self, key: K, value: V):
        """Set value for key (Dict API compatibility).
        
        Args:
            key: The key to set.
            value: The value to associate with the key.
        """
        _ = self.insert(key, value)

    @always_inline
    fn __delitem__(mut self, key: K) raises:
        """Delete key from table, raising KeyError if not found (Dict API compatibility).
        
        Args:
            key: The key to delete.
            
        Raises:
            Error: If key is not found.
        """
        if not self.delete(key):
            raise Error("KeyError: key not found in SwissTable for deletion (size=" + String(Int(self._size)) + ")")

    @always_inline
    fn __contains__(self, key: K) -> Bool:
        """Check if key exists in table (Dict API compatibility).
        
        Args:
            key: The key to check.
            
        Returns:
            True if key exists, False otherwise.
        """
        return self.contains(key)

    fn setdefault(mut self, key: K, default: V) -> V:
        """Get value for key, or set and return default if not found (Dict API compatibility).
        
        Args:
            key: The key to look up.
            default: Default value to set if key not found.
            
        Returns:
            The existing value or the default value.
        """
        # Optimized single-pass implementation
        return self._setdefault_optimized(key, default)

    fn update(mut self, other: Self):
        """Update table with key-value pairs from another SwissTable (Dict API compatibility).
        
        Args:
            other: SwissTable to update from.
        """
        # Iterate through all slots in the other table
        for i in range(other._capacity):
            var ctrl = other._control_bytes[i]
            if is_full(ctrl):
                var entry = other._slots[i]
                _ = self.insert(entry.key, entry.value)

    fn has_key(self, key: K) -> Bool:
        """Check if key exists in table (deprecated Dict API method).
        
        Args:
            key: The key to check.
            
        Returns:
            True if key exists, False otherwise.
            
        Note:
            This method is deprecated in favor of 'key in table' or contains().
        """
        return self.contains(key)

    fn keys(self) -> SwissTableKeyIterator[K, V]:
        """Return iterator over keys (Dict API compatibility).
        
        Returns:
            Iterator over all keys in the table.
        """
        return SwissTableKeyIterator[K, V](
            self._control_bytes, self._slots, 
            Int(self._capacity), Int(self._size)
        )

    fn values(self) -> SwissTableValueIterator[K, V]:
        """Return iterator over values (Dict API compatibility).
        
        Returns:
            Iterator over all values in the table.
        """
        return SwissTableValueIterator[K, V](
            self._control_bytes, self._slots, 
            Int(self._capacity), Int(self._size)
        )

    fn items(self) -> SwissTableItemIterator[K, V]:
        """Return iterator over key-value pairs (Dict API compatibility).
        
        Returns:
            Iterator over all key-value pairs in the table.
        """
        return SwissTableItemIterator[K, V](
            self._control_bytes, self._slots, 
            Int(self._capacity), Int(self._size)
        )


    
    @staticmethod
    fn fromkeys(keys: List[K], default_value: V, hasher: H) -> Self:
        """Create a new SwissTable with keys from iterable and values set to default_value.
        
        Args:
            keys: List of keys to insert.
            default_value: Default value for all keys.
            hasher: Hash function to use.
            
        Returns:
            New SwissTable with specified keys and default values.
        """
        var table = SwissTable[K, V, H](len(keys), hasher)
        for i in range(len(keys)):
            _ = table.insert(keys[i], default_value)
        return table
    
    fn copy(self) -> Self:
        """Create a shallow copy of the table.
        
        Returns:
            New SwissTable with same key-value pairs.
        """
        var new_table = SwissTable[K, V, H](Int(self._capacity), self._hasher)
        
        # Copy all entries
        for i in range(Int(self._capacity)):
            var ctrl = self._control_bytes[i]
            if is_full(ctrl):
                var entry = self._slots[i]
                _ = new_table.insert(entry.key, entry.value)
        
        return new_table

    # ===----------------------------------------------------------------------=== #
    # Batch Operations for Algorithmic Performance Improvements
    # ===----------------------------------------------------------------------=== #
    
    fn bulk_lookup(self, keys: List[K]) -> List[Optional[V]]:
        """Perform bulk lookup operations for improved throughput.
        
        Optimized batch processing reduces per-operation overhead by amortizing
        function call costs and improving cache locality.
        
        Args:
            keys: List of keys to look up.
            
        Returns:
            List of Optional values corresponding to each key.
        """
        var results = List[Optional[V]]()
        
        # Pre-allocate result list for better performance
        for i in range(len(keys)):
            results.append(None)
        
        # Process in cache-friendly chunks to improve locality
        alias BATCH_SIZE = 8  # Optimize for cache line size
        var i = 0
        
        while i < len(keys):
            var end_idx = i + BATCH_SIZE
            if end_idx > len(keys):
                end_idx = len(keys)
            
            # Process batch with reduced overhead
            for j in range(i, end_idx):
                if self._capacity == 0:
                    results[j] = None
                else:
                    # Use optimized lookup path
                    if self._size < 16 and self._capacity < 32:
                        results[j] = self._lookup_small_table(keys[j])
                    else:
                        var hash_val = self._compute_hash(keys[j])
                        results[j] = unified_lookup[K, V](
                            self._control_bytes, self._slots, Int(self._capacity), 
                            keys[j], hash_val
                        )
            
            i = end_idx
        
        return results

    fn bulk_insert(mut self, keys: List[K], values: List[V]) -> List[Bool]:
        """Perform bulk insertion operations for improved throughput.
        
        Optimized batch processing reduces per-operation overhead and improves
        cache locality. Handles resizing efficiently for large batches.
        
        Args:
            keys: List of keys to insert.
            values: List of values to insert.
            
        Returns:
            List of Bool indicating if each key was newly inserted (True) or updated (False).
            
        Note:
            keys and values lists must have the same length.
        """
        var results = List[Bool]()
        
        # Pre-allocate result list
        for i in range(len(keys)):
            results.append(False)
        
        # Check if we need to pre-resize for the entire batch
        var needed_capacity = Int(self._size) + len(keys)
        if needed_capacity > Int(self._capacity):
            var target_capacity = self._normalize_capacity(needed_capacity)
            if target_capacity > Int(self._capacity):
                self._resize_to_capacity(target_capacity)
        
        # Process in cache-friendly chunks
        alias BATCH_SIZE = 8
        var i = 0
        
        while i < len(keys):
            var end_idx = i + BATCH_SIZE
            if end_idx > len(keys):
                end_idx = len(keys)
            
            # Process batch with reduced overhead
            for j in range(i, end_idx):
                # Check for resize periodically (less frequent than individual ops)
                if self._growth_left == 0:
                    self._resize()
                
                results[j] = self._insert(keys[j], values[j], True)  # safe_context=True
            
            i = end_idx
        
        return results

    fn bulk_update(mut self, other: Self):
        """Bulk update from another SwissTable with optimized batch processing.
        
        More efficient than iterating and calling insert() individually.
        
        Args:
            other: SwissTable to update from.
        """
        # Pre-resize if needed for the entire batch
        var needed_capacity = Int(self._size) + Int(other._size)
        if needed_capacity > Int(self._capacity):
            var target_capacity = self._normalize_capacity(needed_capacity)
            if target_capacity > Int(self._capacity):
                self._resize_to_capacity(target_capacity)
        
        # Batch process all entries from other table
        for i in range(other._capacity):
            var ctrl = other._control_bytes[i]
            if is_full(ctrl):
                var entry = other._slots[i]
                
                # Batch insert with reduced resize checking
                if self._growth_left == 0:
                    self._resize()
                
                _ = self._insert(entry.key, entry.value, True)  # safe_context=True

    # ===----------------------------------------------------------------------=== #
    # High-Performance Batch Operations (No Result Collection)
    # ===----------------------------------------------------------------------=== #
    
    fn bulk_insert_fast(mut self, keys: List[K], values: List[V]):
        """High-performance bulk insertion without result collection.
        
        Optimized for pure throughput - does not return insertion results.
        Reduces overhead by eliminating result list allocation and management.
        
        Args:
            keys: List of keys to insert.
            values: List of values to insert.
        """
        # Pre-resize for entire batch to eliminate resize overhead
        var needed_capacity = Int(self._size) + len(keys)
        if needed_capacity > Int(self._capacity):
            var target_capacity = self._normalize_capacity(needed_capacity)
            if target_capacity > Int(self._capacity):
                self._resize_to_capacity(target_capacity)
        
        # Process entire batch without result collection overhead
        for i in range(len(keys)):
            # Skip resize checks since we pre-allocated
            _ = self._insert(keys[i], values[i], True)  # safe_context=True
    
    fn bulk_contains_fast(self, keys: List[K]) -> Int:
        """High-performance bulk contains check returning only count.
        
        Optimized for pure throughput - returns only the count of found keys.
        Much faster than bulk_lookup as it avoids value copying and Optional overhead.
        
        Args:
            keys: List of keys to check.
            
        Returns:
            Number of keys that exist in the table.
        """
        var found_count = 0
        
        if self._capacity == 0:
            return 0
        
        # Process in tight loop without result allocation
        for i in range(len(keys)):
            # Use optimized lookup path without value extraction
            if self._size < 16 and self._capacity < 32:
                # Small table linear search
                for j in range(Int(self._capacity)):
                    var ctrl = self._control_bytes[j]
                    if is_full(ctrl):
                        var entry = self._slots[j]
                        if entry.key == keys[i]:
                            found_count += 1
                            break
            else:
                # Use unified algorithm
                var hash_val = self._compute_hash(keys[i])
                var result = unified_lookup[K, V](
                    self._control_bytes, self._slots, Int(self._capacity), 
                    keys[i], hash_val
                )
                if result:
                    found_count += 1
        
        return found_count

    fn __str__(self) -> String:
        """String representation of the table for debugging.
        
        Returns:
            String representation showing table info.
        """
        if self._size == 0:
            return "SwissTable(empty)"
        
        var result = "SwissTable(size=" + String(Int(self._size)) + ", items=[...])"
        return result
    
    fn __repr__(self) -> String:
        """Detailed representation of the table for debugging.
        
        Returns:
            Detailed string representation with capacity and size info.
        """
        var result = "SwissTable(size=" + String(Int(self._size)) + ", capacity=" + String(Int(self._capacity)) + ", load_factor=" + String(Float64(self._size) / Float64(self._capacity)) + ")"
        return result

    # ===----------------------------------------------------------------------=== #
    # Internal Implementation
    # ===----------------------------------------------------------------------=== #

    @always_inline
    fn _setdefault_optimized(mut self, key: K, default: V) -> V:
        """Optimized single-pass setdefault implementation."""
        # Check for resize
        if self._growth_left == 0:
            self._resize()
        
        var hash_val = self._compute_hash(key)
        var result = unified_find_slot[K, V](
            self._control_bytes, self._slots, Int(self._capacity), key, hash_val
        )
        var found_existing = result[0]
        var slot_index = result[1]
        
        if found_existing:
            # Key exists, return existing value
            return self._slots[slot_index].value
        else:
            # Key doesn't exist, insert default and return it
            var h2 = UInt8(hash_val & 0x7F)
            var old_ctrl = self._control_bytes[slot_index]
            self._set_ctrl_byte(slot_index, make_ctrl_byte(h2))
            
            var entry = DictEntry(key, default)
            (self._slots + slot_index).init_pointee_move(entry^)
            
            # Update counters
            self._size += 1
            if old_ctrl == EMPTY:
                self._growth_left -= 1
            
            return default

    @always_inline
    fn _insert(mut self, owned key: K, owned value: V, safe_context: Bool) -> Bool:
        """Optimized insert with small table fast path."""
        # Check for resize
        if not safe_context and self._growth_left == 0:
            self._resize()
        
        # Small table optimization: use linear search for tables < 16 elements AND capacity < 32
        # This ensures consistency - once we resize to 32+, always use unified algorithm
        if self._size < 16 and self._capacity < 32:
            return self._insert_small_table(key^, value^)
        
        var hash_val = self._compute_hash(key)
        var result = unified_find_slot[K, V](
            self._control_bytes, self._slots, Int(self._capacity), key, hash_val
        )
        var found_existing = result[0]
        var slot_index = result[1]
        
        if found_existing:
            # Update existing key
            self._slots[slot_index].value = value^
            return False
        else:
            # Insert new key
            var h2 = UInt8(hash_val & 0x7F)
            var old_ctrl = self._control_bytes[slot_index]
            self._set_ctrl_byte(slot_index, make_ctrl_byte(h2))
            
            var entry = DictEntry(key^, value^)
            (self._slots + slot_index).init_pointee_move(entry^)
            
            # Update counters
            self._size += 1
            if old_ctrl == EMPTY:
                self._growth_left -= 1
            
            return True

# Removed _insert_simple - using unified algorithm for all table sizes

    fn _insert_small_table(mut self, owned key: K, owned value: V) -> Bool:
        """Optimized insertion for small tables."""
        var insert_slot: Int = -1
        
        # Single pass: check for existing key and find insert position
        for i in range(Int(self._capacity)):
            var ctrl = self._control_bytes[i]
            
            if is_full(ctrl):
                var entry = self._slots[i]
                if entry.key == key:
                    # Key exists, update value
                    self._slots[i].value = value^
                    return False
            
            elif (ctrl == EMPTY or ctrl == DELETED) and insert_slot == -1:
                insert_slot = i
        
        # Insert at found slot
        if insert_slot != -1:
            var hash_val = self._compute_hash(key)
            var h2 = UInt8(hash_val & 0x7F)  # FIXED: Use consistent hash computation
            var old_ctrl = self._control_bytes[insert_slot]
            self._set_ctrl_byte(insert_slot, make_ctrl_byte(h2))
            
            var entry = DictEntry(key^, value^)
            (self._slots + insert_slot).init_pointee_move(entry^)
            
            self._size += 1
            if old_ctrl == EMPTY:
                self._growth_left -= 1
            
            return True
        
        return False

# Removed _insert_simd - using unified algorithm for all table sizes


    @always_inline
    fn _lookup_readonly(self, key: K) -> Optional[V]:
        """Optimized lookup with small table fast path."""
        if self._capacity == 0:
            return None
        
        # Small table optimization: use linear search for tables < 16 elements AND capacity < 32
        # This ensures consistency - once we resize to 32+, always use unified algorithm
        if self._size < 16 and self._capacity < 32:
            return self._lookup_small_table(key)
        
        var hash_val = self._compute_hash(key)
        return unified_lookup[K, V](self._control_bytes, self._slots, Int(self._capacity), key, hash_val)

    fn _lookup_small_table(self, key: K) -> Optional[V]:
        """Optimized lookup for small tables."""
        for i in range(Int(self._capacity)):
            var ctrl = self._control_bytes[i]
            if is_full(ctrl):
                var entry = self._slots[i]
                if entry.key == key:
                    return entry.value
        return None

# Removed _lookup_simd - using unified algorithm for all table sizes

    @always_inline
    fn _delete(mut self, key: K) -> Bool:
        """Optimized deletion with small table fast path."""
        if self._capacity == 0:
            return False
        
        # Small table optimization: use linear search for tables < 16 elements AND capacity < 32
        # This ensures consistency - once we resize to 32+, always use unified algorithm
        if self._size < 16 and self._capacity < 32:
            return self._delete_small_table(key)
        
        var hash_val = self._compute_hash(key)
        var result = unified_delete[K, V](
            self._control_bytes, self._slots, Int(self._capacity), key, hash_val
        )
        var found = result[0]
        var slot_index = result[1]
        
        if found:
            # Mark the slot as deleted
            self._set_ctrl_byte(slot_index, DELETED)
            self._size -= 1
            return True
        return False

# Removed _delete_simple - using unified algorithm for all table sizes

    fn _delete_small_table(mut self, key: K) -> Bool:
        """Optimized deletion for small tables."""
        for i in range(Int(self._capacity)):
            var ctrl = self._control_bytes[i]
            if is_full(ctrl):
                var entry = self._slots[i]
                if entry.key == key:
                    # Mark as empty for small tables (always safe)
                    self._set_ctrl_byte(i, EMPTY)
                    self._size -= 1
                    self._growth_left += 1
                    return True
        return False

    # ===----------------------------------------------------------------------=== #
    # Memory Management
    # ===----------------------------------------------------------------------=== #

    fn _allocate_table(mut self, min_capacity: Int):
        """Allocate table with given capacity."""
        var capacity = min_capacity
        if capacity < 4:
            capacity = 4
        
        # Ensure capacity is power of 2 for efficient modulo
        var actual_capacity = capacity
        if actual_capacity & (actual_capacity - 1) != 0:
            # Round up to next power of 2
            actual_capacity = 1
            while actual_capacity < capacity:
                actual_capacity <<= 1
        
        # Store as Int32 for cache efficiency
        self._capacity = Int32(actual_capacity)
        self._bucket_mask = Int32(actual_capacity - 1)
        
        # Allocate control bytes with padding for SIMD safety
        var ctrl_size = actual_capacity + Self.GROUP_WIDTH
        self._control_bytes = UnsafePointer[UInt8].alloc(ctrl_size)
        
        # Initialize control bytes to EMPTY
        for i in range(ctrl_size):
            self._control_bytes[i] = EMPTY
        
        # Allocate slots
        self._slots = UnsafePointer[DictEntry[K, V]].alloc(actual_capacity)
        
        # Set growth threshold (7/8 load factor)
        self._growth_left = Int32((actual_capacity * 7) // 8)
        self._size = 0

    fn _resize(mut self):
        """Resize table to double capacity."""
        var old_capacity = self._capacity
        var old_control_bytes = self._control_bytes
        var old_slots = self._slots
        var old_size = self._size

        # Allocate new table with double capacity
        self._allocate_table(Int(old_capacity * 2))

        # Rehash all entries using unified algorithm to ensure consistency
        for old_slot_idx in range(Int(old_capacity)):
            var ctrl = old_control_bytes[old_slot_idx]
            if is_full(ctrl):
                var entry = old_slots[old_slot_idx]
                # Use unified algorithm directly to ensure consistency with future lookups
                var hash_val = self._hasher.hash(entry.key)
                var slot_index = unified_resize_insert[K, V](
                    self._control_bytes, self._slots, Int(self._capacity),
                    entry.key, entry.value, hash_val
                )
                # Set control byte
                var h2 = UInt8(hash_val & 0x7F)
                self._set_ctrl_byte(slot_index, make_ctrl_byte(h2))
        
        # Restore the original size and adjust growth counter
        self._size = old_size
        self._growth_left = Int32(((Int(self._capacity) * 7) // 8) - Int(old_size))

        # Clean up old table
        if old_control_bytes:
            old_control_bytes.free()
        if old_slots:
            old_slots.free()

    fn _resize_to_capacity(mut self, target_capacity: Int):
        """Resize table to specific capacity."""
        var old_capacity = self._capacity
        var old_control_bytes = self._control_bytes
        var old_slots = self._slots
        var old_size = self._size

        # Allocate new table with target capacity
        self._allocate_table(target_capacity)

        # Rehash all entries using unified algorithm to ensure consistency
        for old_slot_idx in range(Int(old_capacity)):
            var ctrl = old_control_bytes[old_slot_idx]
            if is_full(ctrl):
                var entry = old_slots[old_slot_idx]
                # Use unified algorithm directly to ensure consistency with future lookups
                var hash_val = self._hasher.hash(entry.key)
                var slot_index = unified_resize_insert[K, V](
                    self._control_bytes, self._slots, Int(self._capacity),
                    entry.key, entry.value, hash_val
                )
                # Set control byte
                var h2 = UInt8(hash_val & 0x7F)
                self._set_ctrl_byte(slot_index, make_ctrl_byte(h2))
        
        # Restore the original size and adjust growth counter
        self._size = old_size
        self._growth_left = Int32(((Int(self._capacity) * 7) // 8) - Int(old_size))

        # Clean up old table
        if old_control_bytes:
            old_control_bytes.free()
        if old_slots:
            old_slots.free()

    @always_inline
    fn _normalize_capacity(self, min_capacity: Int) -> Int:
        """Normalize capacity to next power of 2."""
        if min_capacity <= 4:
            return 4
        
        var capacity = 4
        while capacity < min_capacity:
            capacity <<= 1
        return capacity

    @always_inline
    fn _set_ctrl_byte(mut self, index: Int, value: UInt8):
        """Set control byte with SIMD safety."""
        self._control_bytes[index] = value
        # Set mirror bytes for SIMD wraparound
        if index < Self.GROUP_WIDTH:
            self._control_bytes[Int(self._capacity) + index] = value

    @always_inline
    fn _compute_hash(self, key: K) -> UInt64:
        """Compute hash using the table's hash function."""
        return self._hasher.hash(key)
    
