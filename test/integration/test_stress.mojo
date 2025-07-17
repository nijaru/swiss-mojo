#!/usr/bin/env mojo
"""Comprehensive stress tests for SwissTable implementation.

Tests large datasets, random patterns, heavy load scenarios, and extended
operation cycles to validate production reliability under stress.
"""

from testing import assert_equal, assert_true, assert_false
from random import random_si64, seed
from collections import KeyElement
from swisstable import SwissTable
from swisstable.hash import MojoHashFunction, HashFunction


struct CollidingHashFunction(HashFunction):
    """Hash function that causes many collisions for stress testing."""
    
    fn __init__(out self):
        pass
    
    fn __copyinit__(out self, other: Self):
        pass
    
    fn hash[T: KeyElement](self, key: T) -> UInt64:
        # Force collisions by using only bottom 3 bits
        return UInt64(hash(key)) & 0x7  # Only 8 possible hash values


fn test_large_dataset_operations() raises:
    """Test operations with large datasets (10K+ elements)."""
    print("  Testing large dataset operations...")
    
    var table = SwissTable[Int, String](MojoHashFunction())
    var large_size = 10000
    
    print("    Inserting", large_size, "elements...")
    # Insert large number of elements
    for i in range(large_size):
        var inserted = table.insert(i, String("large_") + String(i))
        assert_true(inserted)
        
        # Periodic validation during insertion
        if i > 0 and i % 2000 == 0:
            print("      Progress:", i, "elements inserted")
            # Verify random sample
            for j in range(0, i, i // 10):  # Check every 10th element
                var result = table.lookup(j)
                assert_true(result)
                assert_equal(String("large_") + String(j), result.value())
    
    assert_equal(large_size, table.size())
    print("    ✅ All", large_size, "elements inserted successfully")
    
    print("    Verifying all elements accessible...")
    # Verify all elements are accessible
    for i in range(large_size):
        var result = table.lookup(i)
        assert_true(result)
        assert_equal(String("large_") + String(i), result.value())
    
    print("    ✅ All elements verified")


fn test_random_access_patterns() raises:
    """Test with random insertion and lookup patterns."""
    print("  Testing random access patterns...")
    
    # Set seed for reproducibility
    seed(12345)
    
    var table = SwissTable[Int, Int](MojoHashFunction())
    var operations = 5000
    var max_key = 1000
    
    # Track which keys we've inserted
    var inserted_keys = List[Bool]()
    for i in range(max_key):
        inserted_keys.append(False)
    
    print("    Performing", operations, "random operations...")
    for op in range(operations):
        var key = Int(random_si64(0, max_key - 1))
        var operation = Int(random_si64(0, 2))  # 0=insert, 1=lookup, 2=delete
        
        if operation == 0:  # Insert
            var inserted = table.insert(key, key * 2)
            if inserted:
                inserted_keys[key] = True
        elif operation == 1:  # Lookup
            var result = table.lookup(key)
            if inserted_keys[key]:
                assert_true(result)
                assert_equal(key * 2, result.value())
            else:
                assert_false(result)
        else:  # Delete
            var deleted = table.delete(key)
            if inserted_keys[key]:
                assert_true(deleted)
                inserted_keys[key] = False
            else:
                assert_false(deleted)
        
        # Periodic size validation
        if op % 1000 == 0:
            var expected_size = 0
            for i in range(max_key):
                if inserted_keys[i]:
                    expected_size += 1
            assert_equal(expected_size, table.size())
    
    print("    ✅ Random operations completed successfully")


fn test_heavy_collision_stress() raises:
    """Test performance under heavy hash collisions."""
    print("  Testing heavy collision stress...")
    
    var table = SwissTable[Int, String, CollidingHashFunction](CollidingHashFunction())
    var stress_size = 1000
    
    print("    Inserting", stress_size, "elements with heavy collisions...")
    # Insert elements that will all collide
    for i in range(stress_size):
        var inserted = table.insert(i, String("collision_") + String(i))
        assert_true(inserted)
    
    assert_equal(stress_size, table.size())
    
    print("    Verifying all elements findable despite collisions...")
    # Verify all elements are still findable
    for i in range(stress_size):
        var result = table.lookup(i)
        assert_true(result)
        assert_equal(String("collision_") + String(i), result.value())
    
    print("    ✅ Heavy collision stress test passed")


fn test_update_heavy_workload() raises:
    """Test repeated updates to same keys."""
    print("  Testing update-heavy workload...")
    
    var table = SwissTable[String, Int](MojoHashFunction())
    var key_count = 500
    var update_rounds = 20
    
    # Initial insertion
    for i in range(key_count):
        _ = table.insert(String("update_key_") + String(i), i)
    
    print("    Performing", update_rounds, "rounds of updates...")
    # Multiple rounds of updates
    for round in range(update_rounds):
        for i in range(key_count):
            var key = String("update_key_") + String(i)
            var new_value = (round * key_count) + i
            var inserted = table.insert(key, new_value)
            assert_false(inserted)  # Should be update, not insertion
        
        # Size should remain constant
        assert_equal(key_count, table.size())
        
        # Verify updated values
        if round % 5 == 0:  # Check every 5th round
            for i in range(key_count):
                var result = table.lookup(String("update_key_") + String(i))
                assert_true(result)
                assert_equal((round * key_count) + i, result.value())
    
    print("    ✅ Update-heavy workload completed")


fn test_alternating_growth_shrink() raises:
    """Test alternating growth and shrinkage patterns."""
    print("  Testing alternating growth/shrink patterns...")
    
    var table = SwissTable[Int, String](MojoHashFunction())
    var cycles = 5  # Reduced cycles for faster testing
    var batch_size = 100
    var next_key = 0
    
    for cycle in range(cycles):
        print("    Cycle", cycle + 1, "- Growing...")
        # Growth phase - insert new unique keys
        var size_before = table.size()
        var keys_added = List[Int]()
        
        for i in range(batch_size):
            _ = table.insert(next_key, String("cycle_") + String(cycle) + String("_") + String(next_key))
            keys_added.append(next_key)
            next_key += 1
        
        assert_equal(size_before + batch_size, table.size())
        
        print("    Cycle", cycle + 1, "- Shrinking...")
        # Shrink phase - remove half the keys we just added
        var elements_to_remove = batch_size // 2
        var size_before_delete = table.size()
        
        for i in range(elements_to_remove):
            var key_to_delete = keys_added[i]
            var deleted = table.delete(key_to_delete)
            assert_true(deleted)
        
        assert_equal(size_before_delete - elements_to_remove, table.size())
        
        # Verify remaining elements are accessible
        for i in range(elements_to_remove, batch_size):
            var result = table.lookup(keys_added[i])
            assert_true(result)
    
    print("    ✅ Growth/shrink cycles completed")


fn test_massive_resize_sequence() raises:
    """Test sequence of many resizes."""
    print("  Testing massive resize sequence...")
    
    var table = SwissTable[String, Int](MojoHashFunction())
    var resize_count = 0
    var last_capacity = table.capacity()
    
    # Insert enough elements to trigger many resizes
    var target_size = 5000
    
    print("    Inserting", target_size, "elements to trigger multiple resizes...")
    for i in range(target_size):
        _ = table.insert(String("resize_test_") + String(i), i)
        
        var current_capacity = table.capacity()
        if current_capacity > last_capacity:
            resize_count += 1
            print("      Resize", resize_count, "at element", i, ":", last_capacity, "->", current_capacity)
            last_capacity = current_capacity
    
    assert_equal(target_size, table.size())
    print("    Total resizes triggered:", resize_count)
    
    # Verify all elements after many resizes
    print("    Verifying all elements after", resize_count, "resizes...")
    for i in range(target_size):
        var result = table.lookup(String("resize_test_") + String(i))
        assert_true(result)
        assert_equal(i, result.value())
    
    print("    ✅ Massive resize sequence completed")


fn test_mixed_operation_stress() raises:
    """Test mixed operations under stress."""
    print("  Testing mixed operation stress...")
    
    var table = SwissTable[Int, String](MojoHashFunction())
    var base_operations = 1000  # Reduced for simpler testing
    
    # Phase 1: Insert all elements
    for i in range(base_operations):
        _ = table.insert(i, String("mixed_") + String(i))
    
    assert_equal(base_operations, table.size())
    
    # Phase 2: Mixed operations (lookup, update, delete)
    for i in range(base_operations // 4):  # Work on first quarter
        # Lookup operations
        var lookup_key = i * 2
        if lookup_key < base_operations:
            var result = table.lookup(lookup_key)
            assert_true(result)
        
        # Update operations
        var update_key = i * 3
        if update_key < base_operations:
            _ = table.insert(update_key, String("updated_") + String(i))
        
        # Delete operations
        var delete_key = i * 4 + 1  # Avoid overlapping with updates
        if delete_key < base_operations:
            var deleted = table.delete(delete_key)
            assert_true(deleted)
    
    print("    ✅ Mixed operation stress test completed")


fn test[name: String, test_fn: fn () raises -> None]() raises:
    """Test runner helper function."""
    print("Running", name, "...")
    try:
        test_fn()
        print("  ✅ PASS")
    except e:
        print("  ❌ FAIL:", e)
        raise e


def main():
    print("Running SwissTable Stress Tests:")
    print("=" * 50)
    print("WARNING: These tests may take several minutes to complete...")
    print()
    
    test["test_large_dataset_operations", test_large_dataset_operations]()
    test["test_random_access_patterns", test_random_access_patterns]()
    test["test_heavy_collision_stress", test_heavy_collision_stress]()
    test["test_update_heavy_workload", test_update_heavy_workload]()
    test["test_alternating_growth_shrink", test_alternating_growth_shrink]()
    test["test_massive_resize_sequence", test_massive_resize_sequence]()
    test["test_mixed_operation_stress", test_mixed_operation_stress]()
    
    print()
    print("All stress tests passed! ✅")
    print("SwissTable implementation handles heavy workloads reliably.")