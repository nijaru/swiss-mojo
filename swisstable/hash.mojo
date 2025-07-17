"""Hash utilities for Swiss table implementation.

Provides H1/H2 hash splitting and control byte generation for efficient
SIMD-based metadata scanning in Swiss tables.

Includes HashFunction trait for custom hash function support.
"""

from collections import KeyElement


# ===----------------------------------------------------------------------=== #
# HashFunction Trait
# ===----------------------------------------------------------------------=== #

trait HashFunction(Copyable):
    """Trait for hash functions used by SwissTable.
    
    Provides a clean interface for custom hash functions while maintaining
    compatibility with SwissTable's H1/H2 splitting approach.
    
    Hash functions must produce high-quality 64-bit hash values with good
    distribution properties to minimize collisions.
    
    Example:
        ```mojo
        struct MyHashFunction(HashFunction):
            fn __init__(out self):
                pass
            
            fn hash[T: KeyElement](self, key: T) -> UInt64:
                return UInt64(hash(key))  # Simple implementation
        ```
    """
    
    fn hash[T: KeyElement](self, key: T) -> UInt64:
        """Compute hash value for a key.
        
        Args:
            key: The key to hash.
            
        Returns:
            64-bit hash value with good distribution properties.
        """
        ...


# ===----------------------------------------------------------------------=== #
# Default Hash Function Implementation
# ===----------------------------------------------------------------------=== #

struct MojoHashFunction(HashFunction):
    """Standard hash function using Mojo's built-in hash().
    
    Uses Mojo's DJBX33A implementation with SIMD optimization and hash secret
    for DoS protection. Provides excellent performance and good distribution.
    """
    
    fn __init__(out self):
        pass
    
    fn __copyinit__(out self, other: Self):
        pass
    
    fn hash[T: KeyElement](self, key: T) -> UInt64:
        return UInt64(hash(key))


# ===----------------------------------------------------------------------=== #
# Hash Utility Functions
# ===----------------------------------------------------------------------=== #

@always_inline
fn compute_hash[T: KeyElement](key: T) -> UInt64:
    """Compute mixed hash value once for both H1 and H2 extraction.
    
    Legacy function - now uses MojoHashFunction for consistency.
    """
    var hasher = MojoHashFunction()
    return hasher.hash(key)

@always_inline
fn h1_hash[T: KeyElement](key: T) -> UInt64:
    """Extract H1 hash (table index) from key.
    
    H1 uses full mixed hash for table indexing and probing.
    """
    return compute_hash(key)

@always_inline  
fn h2_hash[T: KeyElement](key: T) -> UInt8:
    """Extract H2 hash (control byte) from key.
    
    Following hashbrown's approach: use top 7 bits of hash for H2.
    """
    var full_hash = compute_hash(key)
    # Use top 7 bits for H2 (hashbrown approach)
    return UInt8((full_hash >> 57) & 0x7F)

@always_inline
fn compute_h1_h2[T: KeyElement](key: T) -> (UInt64, UInt8):
    """Compute both H1 and H2 hashes in single operation.
    
    Optimized to compute hash mixing only once, reducing overhead.
    Returns (h1, h2) tuple.
    """
    var full_hash = compute_hash(key)
    var h1 = full_hash
    var h2 = UInt8((full_hash >> 57) & 0x7F)
    return (h1, h2)


# Control byte constants for Swiss table metadata (hashbrown-compatible)
alias EMPTY: UInt8 = 0xFF      # 255 - Empty slot (all bits set)
alias DELETED: UInt8 = 0x80    # 128 - Deleted slot (MSB = 1, others = 0)
alias SENTINEL: UInt8 = 0xFF   # 255 - End sentinel (same as EMPTY)


@always_inline
fn is_empty(ctrl: UInt8) -> Bool:
    """Check if control byte represents an empty slot."""
    return ctrl == EMPTY


@always_inline
fn is_deleted(ctrl: UInt8) -> Bool:
    """Check if control byte represents a deleted slot."""
    return ctrl == DELETED


@always_inline
fn is_full(ctrl: UInt8) -> Bool:
    """Check if control byte represents a full slot."""
    return (ctrl & 0x80) == 0


@always_inline
fn is_empty_or_deleted(ctrl: UInt8) -> Bool:
    """Check if control byte represents an empty or deleted slot.
    
    Both empty and deleted have MSB set (>= 128).
    """
    return (ctrl & 0x80) != 0


@always_inline
fn make_ctrl_byte(h2: UInt8) -> UInt8:
    """Create a control byte from H2 hash.
    
    Ensures MSB is 0 to indicate a full slot.
    
    Args:
        h2: The 7-bit H2 hash value.
        
    Returns:
        Control byte with MSB cleared.
    """
    return h2 & 0x7F