"""SIMD operations for Swiss table control byte scanning.

Provides high-performance parallel operations on groups of 8 control bytes
for efficient slot finding and metadata scanning using production patterns.
"""

from .hash import EMPTY, DELETED, is_full


struct Group:
    """SIMD group for parallel control byte operations.
    
    Processes 8 control bytes simultaneously following Go and generic hashbrown patterns
    for optimal Mojo performance and reduced SIMD overhead.
    """
    var ctrl: SIMD[DType.uint8, 16]
    
    alias WIDTH = 16
    
    fn __init__(out self, ctrl_ptr: UnsafePointer[UInt8]):
        """Load 16 control bytes from memory into SIMD register.
        
        Optimized for cache line alignment and reduced memory bandwidth.
        """
        # Load 16 bytes aligned - optimized for cache line access
        # Using aligned load for better performance on modern CPUs
        self.ctrl = ctrl_ptr.load[width=16]()
    
    @always_inline
    fn find_match(self, h2: UInt8) -> SIMD[DType.bool, 16]:
        """Find slots that match the given H2 hash value.
        
        Optimized for Mojo: uses efficient SIMD comparison.
        """
        return self.ctrl == h2
    
    @always_inline
    fn mask_empty(self) -> SIMD[DType.bool, 16]:
        """Find empty slots (control byte = 255).
        
        Optimized for Mojo: direct comparison without temporary SIMD creation.
        """
        return self.ctrl == EMPTY
    
    @always_inline
    fn mask_deleted(self) -> SIMD[DType.bool, 16]:
        """Find deleted slots (control byte = 128).
        
        Optimized for Mojo: direct comparison without temporary SIMD creation.
        """
        return self.ctrl == DELETED
    
    @always_inline
    fn mask_empty_or_deleted(self) -> SIMD[DType.bool, 16]:
        """Find empty or deleted slots (MSB set, >= 128).
        
        Hashbrown insight: Both EMPTY (0xFF) and DELETED (0x80) have MSB set,
        enabling single-instruction detection via MSB test.
        """
        var msb_mask = SIMD[DType.uint8, 16](0x80)
        return (self.ctrl & msb_mask) != 0
    
    @always_inline
    fn mask_full(self) -> SIMD[DType.bool, 16]:
        """Find full slots (control byte < 128)."""
        var msb_mask = SIMD[DType.uint8, 16](0x80)
        return (self.ctrl & msb_mask) == 0
    
    @always_inline
    fn any_empty(self) -> Bool:
        """Check if any slots in the group are empty."""
        return self.mask_empty().reduce_or()
    
    @always_inline
    fn any_match(self, h2: UInt8) -> Bool:
        """Check if any slots match the given H2 hash."""
        return self.find_match(h2).reduce_or()
    
    @always_inline
    fn any_empty_or_deleted(self) -> Bool:
        """Check if any slots are available for insertion."""
        return self.mask_empty_or_deleted().reduce_or()
    
    @always_inline  
    fn find_empty(self) -> SIMD[DType.bool, 16]:
        """Alias for mask_empty() for compatibility."""
        return self.mask_empty()

    @always_inline
    fn find_valid_match_fast(self, h2: UInt8, group_offset: UInt64, capacity: Int) -> Int:
        """Fast path for finding first valid H2 match without scalar branching.
        
        Optimized version that checks bounds once per group instead of per position.
        Returns position within group (0-7) or -1 if no valid match.
        """
        # Early exit if group starts beyond capacity
        if group_offset >= UInt64(capacity):
            return -1
        
        var match_mask = self.find_match(h2)
        
        # Fast path: if group is entirely within capacity, no bounds checking needed
        if group_offset + 16 <= UInt64(capacity):
            return find_first_set_bit(match_mask)
        
        # Slow path: check each match position for validity
        for i in range(16):
            if match_mask[i] and (group_offset + UInt64(i)) < UInt64(capacity):
                return i
        
        return -1

    @always_inline
    fn find_valid_available_fast(self, group_offset: UInt64, capacity: Int) -> Int:
        """Fast path for finding first valid available slot without scalar branching.
        
        Optimized version that checks bounds once per group instead of per position.
        Returns position within group (0-15) or -1 if no valid available slot.
        """
        # Early exit if group starts beyond capacity
        if group_offset >= UInt64(capacity):
            return -1
        
        var available_mask = self.mask_empty_or_deleted()
        
        # Fast path: if group is entirely within capacity, no bounds checking needed
        if group_offset + 16 <= UInt64(capacity):
            return find_first_set_bit(available_mask)
        
        # Slow path: check each available position for validity
        for i in range(16):
            if available_mask[i] and (group_offset + UInt64(i)) < UInt64(capacity):
                return i
        
        return -1

    @always_inline
    fn find_match_and_available(self, h2: UInt8) -> (SIMD[DType.bool, 16], SIMD[DType.bool, 16]):
        """Combined operation: find both matches and available slots in single pass.
        
        Reduces redundant SIMD operations by computing both masks together.
        Returns (match_mask, available_mask).
        """
        var match_mask = self.ctrl == h2
        var available_mask = (self.ctrl & SIMD[DType.uint8, 16](0x80)) != 0
        return (match_mask, available_mask)


@always_inline
fn find_first_valid_match(match_mask: SIMD[DType.bool, 16], valid_mask: SIMD[DType.bool, 16]) -> Int:
    """Find first position where both match and valid are true.
    
    Fast-path optimization for Group→slot mapping with bounds checking.
    Returns -1 if no valid matches found.
    """
    var combined_mask = match_mask & valid_mask
    return find_first_set_bit(combined_mask)

@always_inline
fn find_first_set_bit(mask: SIMD[DType.bool, 16]) -> Int:
    """Find index of first set bit in boolean mask.
    
    Returns -1 if no bits are set.
    """
    if not mask.reduce_or():
        return -1
    
    # Create index vector [0, 1, 2, ..., 15]
    var indices = SIMD[DType.uint8, 16]()
    for i in range(8):
        indices[i] = UInt8(i)
    
    # Use select to get valid indices, invalid get 255
    var selected = mask.select(indices, SIMD[DType.uint8, 16](255))
    return Int(selected.reduce_min())


struct ProbeSequence:
    """Simplified probe sequence for Swiss table optimized for Mojo.
    
    Uses linear probing by groups for simplicity and better performance
    in Mojo's execution model. Sacrifices theoretical collision distribution
    for practical performance gains.
    """
    var mask: UInt64      # capacity - 1 (must be power of 2)
    var offset: UInt64    # Current probe offset
    
    fn __init__(out self, hash: UInt64, capacity: Int):
        """Initialize probe sequence starting from hash position."""
        self.mask = UInt64(capacity - 1)
        # Start at group boundary: hash & ~(GROUP_WIDTH - 1)
        self.offset = hash & self.mask & ~UInt64(Group.WIDTH - 1)
    
    @always_inline
    fn current_group(self) -> UInt64:
        """Get current group offset (always group-aligned)."""
        return self.offset
    
    @always_inline
    fn next(mut self):
        """Advance to next probe position using simple linear probing.
        
        Optimized for Mojo: simple increment by GROUP_WIDTH for better performance
        than complex triangular progression. Provides good enough distribution
        while minimizing computational overhead.
        """
        self.offset = (self.offset + UInt64(Group.WIDTH)) & self.mask