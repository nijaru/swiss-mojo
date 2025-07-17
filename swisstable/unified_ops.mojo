"""Unified Swiss table operations based on hashbrown's proven algorithm.

This module implements a single, simplified algorithm for all table sizes,
eliminating the complex branching between SIMD, simple, and small table paths.
Based on analysis of hashbrown (Rust's production SwissTable implementation).

Key principles:
- Single triangular probe sequence: (i² + i)/2
- No H1/H2 hash splitting - use full hash value
- Simple arithmetic loops instead of SIMD
- Consistent performance across all table sizes
"""

from collections import KeyElement, Optional
from .hash import EMPTY, DELETED, is_full, make_ctrl_byte
from .data_structures import DictEntry


struct TriangularProbeSequence:
    """Hashbrown-style triangular probe sequence.
    
    Uses the mathematical formula (i² + i)/2 to generate probe positions.
    This is guaranteed to visit every slot exactly once for power-of-2 table sizes.
    
    Reference: https://fgiesen.wordpress.com/2015/02/22/triangular-numbers-mod-2n/
    """
    var pos: UInt64
    var stride: UInt64
    var mask: UInt64
    
    fn __init__(out self, hash_val: UInt64, capacity: Int):
        """Initialize probe sequence from hash value."""
        self.mask = UInt64(capacity - 1)
        self.pos = hash_val & self.mask
        self.stride = 0
    
    @always_inline
    fn current_slot(self) -> UInt64:
        """Get current slot index."""
        return self.pos
    
    @always_inline
    fn next(mut self):
        """Advance to next slot using triangular sequence.
        
        Formula: pos = (pos + stride + 1) & mask
                stride += 1
        
        This generates the sequence: 0, 1, 3, 6, 10, 15, 21, ...
        Which are triangular numbers: (i² + i)/2
        """
        self.stride += 1
        self.pos = (self.pos + self.stride) & self.mask


@always_inline
fn specialized_hash[T: KeyElement](key: T) -> UInt64:
    """Optimized hash function - for now use generic hash, can be specialized later."""
    # TODO: Add compile-time specialization once Mojo supports better type introspection
    return UInt64(hash(key))


@always_inline
fn unified_lookup[K: KeyElement, V: Copyable & Movable](
    control_bytes: UnsafePointer[UInt8],
    slots: UnsafePointer[DictEntry[K, V]],
    capacity: Int,
    key: K,
    hash_val: UInt64
) -> Optional[V]:
    """Unified lookup using triangular probe sequence.
    
    Single algorithm for all table sizes - eliminates branching complexity.
    Based on hashbrown's proven approach.
    """
    if capacity == 0:
        return None
    
    # Extract H2 for control byte matching (only when needed)
    var h2 = UInt8(hash_val & 0x7F)  # Bottom 7 bits
    var seq = TriangularProbeSequence(hash_val, capacity)
    var probes = 0
    
    while probes < capacity:
        var slot_index = Int(seq.current_slot())
        var ctrl = control_bytes[slot_index]
        
        # Empty slot - key definitely not found
        if ctrl == EMPTY:
            return None
        
        # Check if this is a potential match
        if is_full(ctrl):
            # Compare H2 first (fast check)
            if ctrl == make_ctrl_byte(h2):
                # H2 matches, check full key
                var entry = slots[slot_index]
                if entry.key == key:
                    return entry.value
        
        # Continue to next slot (handles DELETED automatically)
        seq.next()
        probes += 1
    
    return None


@always_inline
fn unified_find_slot[K: KeyElement, V: Copyable & Movable](
    control_bytes: UnsafePointer[UInt8],
    slots: UnsafePointer[DictEntry[K, V]],
    capacity: Int,
    key: K,
    hash_val: UInt64
) -> (Bool, Int):
    """Unified slot finding for insertion.
    
    Returns (found_existing, slot_index).
    Uses same probe sequence as lookup to ensure consistency.
    """
    var h2 = UInt8(hash_val & 0x7F)
    var seq = TriangularProbeSequence(hash_val, capacity)
    var first_available = -1
    var probes = 0
    
    while probes < capacity:
        var slot_index = Int(seq.current_slot())
        var ctrl = control_bytes[slot_index]
        
        # Empty slot - can insert here, key definitely not present
        if ctrl == EMPTY:
            return (False, first_available if first_available != -1 else slot_index)
        
        # Deleted slot - remember as insertion candidate
        elif ctrl == DELETED:
            if first_available == -1:
                first_available = slot_index
        
        # Full slot - check for existing key
        elif is_full(ctrl):
            if ctrl == make_ctrl_byte(h2):
                var entry = slots[slot_index]
                if entry.key == key:
                    return (True, slot_index)  # Found existing key
        
        seq.next()
        probes += 1
    
    # Should never reach here with proper load factor
    return (False, first_available if first_available != -1 else 0)


@always_inline
fn unified_delete[K: KeyElement, V: Copyable & Movable](
    control_bytes: UnsafePointer[UInt8],
    slots: UnsafePointer[DictEntry[K, V]], 
    capacity: Int,
    key: K,
    hash_val: UInt64
) -> (Bool, Int):
    """Unified deletion using same probe sequence.
    
    Returns (found, slot_index) where found indicates if key was deleted.
    """
    var h2 = UInt8(hash_val & 0x7F)
    var seq = TriangularProbeSequence(hash_val, capacity)
    var probes = 0
    
    while probes < capacity:
        var slot_index = Int(seq.current_slot())
        var ctrl = control_bytes[slot_index]
        
        # Empty slot - key not found
        if ctrl == EMPTY:
            return (False, -1)
        
        # Check for key match
        if is_full(ctrl) and ctrl == make_ctrl_byte(h2):
            var entry = slots[slot_index]
            if entry.key == key:
                return (True, slot_index)
        
        seq.next()
        probes += 1
    
    return (False, -1)


@always_inline  
fn unified_resize_insert[K: KeyElement, V: Copyable & Movable](
    control_bytes: UnsafePointer[UInt8],
    slots: UnsafePointer[DictEntry[K, V]],
    capacity: Int,
    key: K,
    value: V,
    hash_val: UInt64
) -> Int:
    """Unified insertion during resize (no key checking needed).
    
    Returns slot index where entry was placed.
    Used during rehashing when we know keys don't exist yet.
    Only places the entry, caller must set control byte.
    """
    var seq = TriangularProbeSequence(hash_val, capacity)
    var probes = 0
    
    while probes < capacity:
        var slot_index = Int(seq.current_slot())
        var ctrl = control_bytes[slot_index]
        
        # Find first available slot (empty or deleted)
        if ctrl == EMPTY or ctrl == DELETED:
            # Place the entry
            var entry = DictEntry(key, value)
            (slots + slot_index).init_pointee_move(entry^)
            
            return slot_index
        
        seq.next()
        probes += 1
    
    # Should never reach here during resize
    return 0