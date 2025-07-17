"""Specialized SwissTable for Int->Int mappings.

Eliminates generic overhead by using concrete types instead of generic parameters.
Expected performance improvement: 10-30% over generic SwissTable[Int, Int].
"""

from collections import Optional
from builtin.len import Sized
from memory import UnsafePointer
from .hash import EMPTY, DELETED, make_ctrl_byte, is_full, MojoHashFunction
from .unified_ops import unified_lookup, unified_find_slot, unified_delete, unified_resize_insert
from .data_structures import DictEntry

struct FastIntIntTable(Movable, Sized, Copyable):
    """Specialized high-performance SwissTable for Int->Int mappings.
    
    Eliminates generic overhead by using concrete Int/Int types.
    Should be faster than SwissTable[Int, Int, MojoHashFunction] by avoiding
    generic trait dispatching and type parameter overhead.
    """
    
    # Same memory layout as generic version - but concrete types
    var _capacity: Int32
    var _size: Int32           
    var _growth_left: Int32    
    var _bucket_mask: Int32    
    var _control_bytes: UnsafePointer[UInt8]
    var _slots: UnsafePointer[DictEntry[Int, Int]]
    var _hasher: MojoHashFunction  # Concrete hasher type
    
    alias GROUP_WIDTH = 16

    fn __init__(out self):
        """Initialize empty specialized table."""
        self._capacity = 0
        self._size = 0  
        self._growth_left = 0
        self._bucket_mask = 0
        self._control_bytes = UnsafePointer[UInt8]()
        self._slots = UnsafePointer[DictEntry[Int, Int]]()
        self._hasher = MojoHashFunction()
        self._allocate_table(16)

    fn __init__(out self, capacity: Int):
        """Initialize with specified capacity."""
        self._capacity = 0
        self._size = 0
        self._growth_left = 0
        self._bucket_mask = 0
        self._control_bytes = UnsafePointer[UInt8]()
        self._slots = UnsafePointer[DictEntry[Int, Int]]()
        self._hasher = MojoHashFunction()
        var target_capacity = self._normalize_capacity(capacity)
        self._allocate_table(target_capacity)

    fn __moveinit__(out self, owned existing: Self):
        """Move constructor."""
        self._capacity = existing._capacity
        self._size = existing._size
        self._growth_left = existing._growth_left
        self._bucket_mask = existing._bucket_mask
        self._control_bytes = existing._control_bytes
        self._slots = existing._slots
        self._hasher = existing._hasher^
        
        # Reset existing
        existing._capacity = 0
        existing._size = 0
        existing._growth_left = 0
        existing._bucket_mask = 0
        existing._control_bytes = UnsafePointer[UInt8]()
        existing._slots = UnsafePointer[DictEntry[Int, Int]]()

    fn __copyinit__(out self, existing: Self):
        """Copy constructor."""
        self._capacity = existing._capacity
        self._size = existing._size
        self._growth_left = existing._growth_left
        self._bucket_mask = existing._bucket_mask
        self._hasher = existing._hasher
        
        if existing._capacity > 0:
            var ctrl_size = Int(existing._capacity) + Self.GROUP_WIDTH
            self._control_bytes = UnsafePointer[UInt8].alloc(ctrl_size)
            
            for i in range(ctrl_size):
                self._control_bytes[i] = existing._control_bytes[i]
            
            self._slots = UnsafePointer[DictEntry[Int, Int]].alloc(Int(existing._capacity))
            for i in range(Int(existing._capacity)):
                if is_full(existing._control_bytes[i]):
                    var entry = existing._slots[i]
                    (self._slots + i).init_pointee_copy(entry)
        else:
            self._control_bytes = UnsafePointer[UInt8]()
            self._slots = UnsafePointer[DictEntry[Int, Int]]()

    fn __del__(owned self):
        """Clean up memory."""
        if self._control_bytes:
            self._control_bytes.free()
        if self._slots:
            self._slots.free()

    @always_inline
    fn size(self) -> Int:
        """Return number of elements."""
        return Int(self._size)

    @always_inline  
    fn capacity(self) -> Int:
        """Return current capacity."""
        return Int(self._capacity)

    @always_inline
    fn is_empty(self) -> Bool:
        """Return True if empty."""
        return self._size == 0

    @always_inline
    fn insert(mut self, key: Int, value: Int) -> Bool:
        """Insert key-value pair. Returns True if newly inserted."""
        # Check for resize
        if self._growth_left == 0:
            self._resize()
        
        # Use specialized hash computation - no generic overhead
        var hash_val = UInt64(hash(key))  # Direct hash() call, no trait dispatch
        var result = unified_find_slot[Int, Int](
            self._control_bytes, 
            self._slots,
            Int(self._capacity), 
            key, 
            hash_val
        )
        var found_existing = result[0]
        var slot_index = result[1]
        
        if found_existing:
            # Update existing
            self._slots[slot_index].value = value
            return False
        else:
            # Insert new
            var h2 = UInt8(hash_val & 0x7F)
            var old_ctrl = self._control_bytes[slot_index]
            self._set_ctrl_byte(slot_index, make_ctrl_byte(h2))
            
            var entry = DictEntry(key, value)
            (self._slots + slot_index).init_pointee_move(entry^)
            
            self._size += 1
            if old_ctrl == EMPTY:
                self._growth_left -= 1
            
            return True

    @always_inline  
    fn lookup(self, key: Int) -> Optional[Int]:
        """Look up value for key."""
        if self._capacity == 0:
            return None
        
        # Specialized hash computation - no generic overhead  
        var hash_val = UInt64(hash(key))  # Direct hash() call
        return unified_lookup[Int, Int](
            self._control_bytes,
            self._slots,
            Int(self._capacity),
            key,
            hash_val
        )

    @always_inline
    fn delete(mut self, key: Int) -> Bool:
        """Delete key. Returns True if deleted."""
        if self._capacity == 0:
            return False
        
        var hash_val = UInt64(hash(key))
        var result = unified_delete[Int, Int](
            self._control_bytes,
            self._slots,
            Int(self._capacity),
            key,
            hash_val
        )
        var found = result[0]
        var slot_index = result[1]
        
        if found:
            self._set_ctrl_byte(slot_index, DELETED)
            self._size -= 1
            return True
        return False

    @always_inline
    fn contains(self, key: Int) -> Bool:
        """Check if key exists."""
        var result = self.lookup(key)
        return result.__bool__()

    @always_inline
    fn get(self, key: Int, default: Int) -> Int:
        """Get value with default."""
        var result = self.lookup(key)
        if result:
            return result.value()
        else:
            return default

    @always_inline
    fn __len__(self) -> Int:
        """Length for builtin len()."""
        return self.size()

    @always_inline
    fn __bool__(self) -> Bool:
        """Boolean context."""
        return not self.is_empty()

    # Internal methods - same as generic version
    fn _allocate_table(mut self, min_capacity: Int):
        """Allocate table with given capacity."""
        var capacity = min_capacity
        if capacity < 4:
            capacity = 4
        
        var actual_capacity = capacity
        if actual_capacity & (actual_capacity - 1) != 0:
            actual_capacity = 1
            while actual_capacity < capacity:
                actual_capacity <<= 1
        
        self._capacity = Int32(actual_capacity)
        self._bucket_mask = Int32(actual_capacity - 1)
        
        var ctrl_size = actual_capacity + Self.GROUP_WIDTH
        self._control_bytes = UnsafePointer[UInt8].alloc(ctrl_size)
        
        for i in range(ctrl_size):
            self._control_bytes[i] = EMPTY
        
        self._slots = UnsafePointer[DictEntry[Int, Int]].alloc(actual_capacity)
        self._growth_left = Int32((actual_capacity * 7) // 8)
        self._size = 0

    fn _resize(mut self):
        """Resize table."""
        var old_capacity = self._capacity
        var old_control_bytes = self._control_bytes
        var old_slots = self._slots
        var old_size = self._size

        self._allocate_table(Int(old_capacity * 2))

        for old_slot_idx in range(Int(old_capacity)):
            var ctrl = old_control_bytes[old_slot_idx]
            if is_full(ctrl):
                var entry = old_slots[old_slot_idx]
                var hash_val = UInt64(hash(entry.key))  # Specialized hash
                var slot_index = unified_resize_insert[Int, Int](
                    self._control_bytes, 
                    self._slots,
                    Int(self._capacity),
                    entry.key, 
                    entry.value, 
                    hash_val
                )
                var h2 = UInt8(hash_val & 0x7F)
                self._set_ctrl_byte(slot_index, make_ctrl_byte(h2))
        
        self._size = old_size
        self._growth_left = Int32(((Int(self._capacity) * 7) // 8) - Int(old_size))

        if old_control_bytes:
            old_control_bytes.free()
        if old_slots:
            old_slots.free()

    @always_inline
    fn _normalize_capacity(self, min_capacity: Int) -> Int:
        """Normalize capacity to power of 2."""
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
        if index < Self.GROUP_WIDTH:
            self._control_bytes[Int(self._capacity) + index] = value