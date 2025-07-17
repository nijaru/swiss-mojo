#!/usr/bin/env mojo
"""Comprehensive hash collision testing for SwissTable implementation.

Tests pathological hash functions, collision chains, and worst-case scenarios
to ensure the SwissTable handles hash collisions correctly.
"""

from testing import assert_equal, assert_true, assert_false
from collections import KeyElement
from swisstable import SwissTable
from swisstable.hash import HashFunction


struct ZeroHashFunction(HashFunction):
    """Pathological hash function that always returns 0 (maximum collisions)."""
    
    fn __init__(out self):
        pass
    
    fn __copyinit__(out self, other: Self):
        pass
    
    fn hash[T: KeyElement](self, key: T) -> UInt64:
        return 0  # All keys collide!


struct MaxHashFunction(HashFunction):
    """Pathological hash function that always returns max value."""
    
    fn __init__(out self):
        pass
    
    fn __copyinit__(out self, other: Self):
        pass
    
    fn hash[T: KeyElement](self, key: T) -> UInt64:
        return UInt64.MAX  # All keys collide at maximum value!


struct IdentityHashFunction(HashFunction):
    """Hash function that returns the key value directly (for Int keys)."""
    
    fn __init__(out self):
        pass
    
    fn __copyinit__(out self, other: Self):
        pass
    
    fn hash[T: KeyElement](self, key: T) -> UInt64:
        # For Int keys, return the value directly
        return UInt64(hash(key)) & 0xFF  # Bottom 8 bits only for more collisions


struct ClusterHashFunction(HashFunction):
    """Hash function that creates clustering by modulo operation."""
    
    fn __init__(out self):
        pass
    
    fn __copyinit__(out self, other: Self):
        pass
    
    fn hash[T: KeyElement](self, key: T) -> UInt64:
        # Create clusters of hash values
        return UInt64(hash(key)) % 7  # Force clustering in small range


fn test_zero_hash_collisions() raises:
    """Test with hash function that always returns 0."""
    var table = SwissTable[Int, String, ZeroHashFunction](ZeroHashFunction())
    
    # Insert multiple elements that all hash to 0
    var num_elements = 20
    for i in range(num_elements):
        var inserted = table.insert(i, String("zero_") + String(i))
        assert_true(inserted)
        assert_equal(i + 1, table.size())
    
    # All elements should be findable despite all having same hash
    for i in range(num_elements):
        var result = table.lookup(i)
        assert_true(result)
        assert_equal(String("zero_") + String(i), result.value())
    
    # Delete half the elements
    for i in range(0, num_elements, 2):
        var deleted = table.delete(i)
        assert_true(deleted)
    
    # Remaining elements should still be findable
    for i in range(1, num_elements, 2):
        var result = table.lookup(i)
        assert_true(result)
        assert_equal(String("zero_") + String(i), result.value())
    
    # Deleted elements should not be findable
    for i in range(0, num_elements, 2):
        var result = table.lookup(i)
        assert_false(result)


fn test_max_hash_collisions() raises:
    """Test with hash function that always returns maximum value."""
    var table = SwissTable[Int, String, MaxHashFunction](MaxHashFunction())
    
    # Insert elements that all hash to max value
    var num_elements = 15
    for i in range(num_elements):
        var inserted = table.insert(i, String("max_") + String(i))
        assert_true(inserted)
    
    assert_equal(num_elements, table.size())
    
    # All should be findable
    for i in range(num_elements):
        var result = table.lookup(i)
        assert_true(result)
        assert_equal(String("max_") + String(i), result.value())


fn test_clustered_hash_distribution() raises:
    """Test with hash function that creates clustering."""
    var table = SwissTable[Int, String, ClusterHashFunction](ClusterHashFunction())
    
    # Insert many elements that cluster into 7 hash buckets
    var num_elements = 50
    for i in range(num_elements):
        var inserted = table.insert(i, String("cluster_") + String(i))
        assert_true(inserted)
    
    assert_equal(num_elements, table.size())
    
    # All elements should be findable despite clustering
    for i in range(num_elements):
        var result = table.lookup(i)
        assert_true(result)
        assert_equal(String("cluster_") + String(i), result.value())


fn test_sequential_collision_chain() raises:
    """Test sequential keys that create long collision chains."""
    var table = SwissTable[Int, Int, IdentityHashFunction](IdentityHashFunction())
    
    # Insert sequential numbers that will have similar hash patterns
    var base = 1000
    var count = 30
    
    for i in range(count):
        var key = base + i
        var inserted = table.insert(key, key * 2)
        assert_true(inserted)
    
    # Verify all can be found
    for i in range(count):
        var key = base + i
        var result = table.lookup(key)
        assert_true(result)
        assert_equal(key * 2, result.value())
    
    # Delete every third element
    for i in range(0, count, 3):
        var key = base + i
        var deleted = table.delete(key)
        assert_true(deleted)
    
    # Verify remaining elements still findable
    for i in range(count):
        if i % 3 != 0:
            var key = base + i
            var result = table.lookup(key)
            assert_true(result)
            assert_equal(key * 2, result.value())


fn test_collision_with_resize() raises:
    """Test hash collisions combined with table resize operations."""
    var table = SwissTable[Int, String, ZeroHashFunction](ZeroHashFunction())
    
    # Insert many colliding elements to force multiple resizes
    var num_elements = 100
    
    for i in range(num_elements):
        var inserted = table.insert(i, String("resize_") + String(i))
        assert_true(inserted)
        
        # Verify existing elements still findable after each insertion
        if i > 0 and i % 10 == 0:  # Check every 10 insertions
            for j in range(i):
                var result = table.lookup(j)
                assert_true(result)
                assert_equal(String("resize_") + String(j), result.value())
    
    # Final verification - all elements should be findable
    assert_equal(num_elements, table.size())
    for i in range(num_elements):
        var result = table.lookup(i)
        assert_true(result)
        assert_equal(String("resize_") + String(i), result.value())


fn test_h1_h2_collision_scenarios() raises:
    """Test scenarios where H1 matches but H2 differs (or vice versa)."""
    var table = SwissTable[Int, String, IdentityHashFunction](IdentityHashFunction())
    
    # Use keys that will have same H1 (capacity position) but different H2 (control byte)
    # Since we're using IdentityHashFunction with mod 256, we can control this
    var base_key = 100
    var colliding_keys = List[Int]()
    
    # Create keys that should map to same H1 bucket but have different H2 values
    for offset in range(8):
        colliding_keys.append(base_key + (offset * 256))  # Same low bits, different high bits
    
    # Insert all colliding keys
    for i in range(len(colliding_keys)):
        var key = colliding_keys[i]
        var inserted = table.insert(key, String("h1h2_") + String(key))
        assert_true(inserted)
    
    # Verify all are findable
    for i in range(len(colliding_keys)):
        var key = colliding_keys[i]
        var result = table.lookup(key)
        assert_true(result)
        assert_equal(String("h1h2_") + String(key), result.value())


fn test_worst_case_probe_sequence() raises:
    """Test probe sequence in worst-case collision scenarios."""
    var table = SwissTable[Int, String, ZeroHashFunction](ZeroHashFunction())
    
    # Fill table close to capacity with all colliding keys
    var capacity = table.capacity()
    var max_elements = (capacity * 7) // 8  # Up to load factor threshold
    
    for i in range(max_elements):
        var inserted = table.insert(i, String("probe_") + String(i))
        assert_true(inserted)
    
    # At this point, probe sequences should be long
    # Verify all elements are still findable
    for i in range(max_elements):
        var result = table.lookup(i)
        assert_true(result)
        assert_equal(String("probe_") + String(i), result.value())
    
    # Test lookup of non-existent key (should probe through collision chain)
    var missing_result = table.lookup(max_elements + 100)
    assert_false(missing_result)


fn test_mixed_collision_patterns() raises:
    """Test mixed good and bad hash distribution patterns."""
    var table = SwissTable[Int, String, ClusterHashFunction](ClusterHashFunction())
    
    # Mix of keys that cluster and keys that don't
    var mixed_keys = List[Int]()
    
    # Some keys that cluster (multiples of 7)
    for i in range(0, 35, 7):
        mixed_keys.append(i)
    
    # Some keys with better distribution
    for prime in List[Int](101, 103, 107, 109, 113):
        mixed_keys.append(prime)
    
    # Insert all mixed keys
    for i in range(len(mixed_keys)):
        var key = mixed_keys[i]
        var inserted = table.insert(key, String("mixed_") + String(key))
        assert_true(inserted)
    
    # Verify all findable
    for i in range(len(mixed_keys)):
        var key = mixed_keys[i]
        var result = table.lookup(key)
        assert_true(result)
        assert_equal(String("mixed_") + String(key), result.value())


fn test[name: String, test_fn: fn () raises -> None]() raises:
    """Test runner helper function."""
    print("  " + name + " ...", end="")
    try:
        test_fn()
        print(" PASS")
    except e:
        print(" FAIL")
        raise e


def main():
    print("Running SwissTable Hash Collision Tests:")
    print("=" * 50)
    
    test["test_zero_hash_collisions", test_zero_hash_collisions]()
    test["test_max_hash_collisions", test_max_hash_collisions]()
    test["test_clustered_hash_distribution", test_clustered_hash_distribution]()
    test["test_sequential_collision_chain", test_sequential_collision_chain]()
    test["test_collision_with_resize", test_collision_with_resize]()
    test["test_h1_h2_collision_scenarios", test_h1_h2_collision_scenarios]()
    test["test_worst_case_probe_sequence", test_worst_case_probe_sequence]()
    test["test_mixed_collision_patterns", test_mixed_collision_patterns]()
    
    print()
    print("All hash collision tests passed! ✅")