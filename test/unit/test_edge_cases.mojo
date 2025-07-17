#!/usr/bin/env mojo
"""Comprehensive edge case testing for SwissTable implementation.

Tests boundary conditions, empty states, minimal sizes, and other edge cases
that are critical for production reliability.
"""

from testing import assert_equal, assert_true, assert_false
from swisstable import SwissTable
from swisstable.hash import MojoHashFunction


fn test_empty_table_operations() raises:
    """Test all operations on empty table."""
    var table = SwissTable[Int, String](MojoHashFunction())
    
    # Initial state
    assert_equal(0, table.size())
    assert_equal(16, table.capacity())  # Default initial capacity
    assert_false(table.__bool__())
    
    # Lookup on empty table
    var result = table.lookup(42)
    assert_false(result)
    
    # Delete on empty table
    var deleted = table.delete(42)
    assert_false(deleted)
    
    # Contains on empty table
    assert_false(42 in table)
    assert_false(table.contains(42))
    
    # Get with default on empty table
    var get_result = table.get(42, String("default"))
    assert_equal(String("default"), get_result)
    
    # Pop on empty table
    var pop_result = table.pop(42, String("default"))
    assert_equal(String("default"), pop_result)
    
    # Clear empty table (should be no-op)
    table.clear()
    assert_equal(0, table.size())


fn test_single_element_operations() raises:
    """Test operations with exactly one element."""
    var table = SwissTable[String, Int](MojoHashFunction())
    
    # Insert single element
    var inserted = table.insert(String("key"), 100)
    assert_true(inserted)
    assert_equal(1, table.size())
    assert_true(table.__bool__())
    
    # Lookup single element
    var result = table.lookup(String("key"))
    assert_true(result)
    assert_equal(100, result.value())
    
    # Contains single element
    assert_true(String("key") in table)
    assert_false(String("missing") in table)
    
    # Get single element
    var get_result = table.get(String("key"), 999)
    assert_equal(100, get_result)
    
    # Get missing from single element table
    var get_missing = table.get(String("missing"), 999)
    assert_equal(999, get_missing)
    
    # Delete single element
    var deleted = table.delete(String("key"))
    assert_true(deleted)
    assert_equal(0, table.size())
    assert_false(table.__bool__())
    
    # Table should be empty again
    var lookup_after_delete = table.lookup(String("key"))
    assert_false(lookup_after_delete)


fn test_capacity_boundaries() raises:
    """Test behavior at capacity boundaries and power-of-2 edges."""
    var table = SwissTable[Int, Int](MojoHashFunction())
    var initial_capacity = table.capacity()
    
    # Fill to just under resize threshold (7/8 load factor)
    var threshold = (initial_capacity * 7) // 8
    
    for i in range(threshold):
        var inserted = table.insert(i, i * 2)
        assert_true(inserted)
        assert_equal(i + 1, table.size())
    
    # Should not have resized yet
    assert_equal(initial_capacity, table.capacity())
    
    # One more insertion should trigger resize
    var trigger_resize = table.insert(threshold, threshold * 2)
    assert_true(trigger_resize)
    assert_equal(threshold + 1, table.size())
    assert_true(table.capacity() > initial_capacity)
    
    # Verify all elements still accessible after resize
    for i in range(threshold + 1):
        var result = table.lookup(i)
        assert_true(result)
        assert_equal(i * 2, result.value())


fn test_zero_capacity_edge_case() raises:
    """Test behavior with theoretical zero capacity (should not happen)."""
    # Note: Our implementation starts with capacity 16, but test the logic
    var table = SwissTable[Int, String](MojoHashFunction())
    
    # Even with operations, capacity should never be zero
    assert_true(table.capacity() > 0)
    
    # Operations should work normally
    _ = table.insert(1, String("test"))
    assert_equal(1, table.size())


fn test_maximum_single_probe() raises:
    """Test scenarios requiring only single probe (no collisions)."""
    var table = SwissTable[Int, String](MojoHashFunction())
    
    # Insert elements that likely map to different slots
    var keys = List[Int](1, 1000, 2000, 3000, 4000)
    
    for i in range(len(keys)):
        var key = keys[i]
        var inserted = table.insert(key, String("value_") + String(key))
        assert_true(inserted)
    
    # All should be findable
    for i in range(len(keys)):
        var key = keys[i]
        var result = table.lookup(key)
        assert_true(result)
        assert_equal(String("value_") + String(key), result.value())


fn test_duplicate_insertions() raises:
    """Test inserting duplicate keys."""
    var table = SwissTable[String, Int](MojoHashFunction())
    
    # First insertion
    var first = table.insert(String("duplicate"), 100)
    assert_true(first)
    assert_equal(1, table.size())
    
    # Second insertion of same key (should replace)
    var second = table.insert(String("duplicate"), 200)
    assert_false(second)  # Key already exists
    assert_equal(1, table.size())  # Size unchanged
    
    # Value should be updated
    var result = table.lookup(String("duplicate"))
    assert_true(result)
    assert_equal(200, result.value())


fn test_alternating_insert_delete() raises:
    """Test alternating insertion and deletion patterns."""
    var table = SwissTable[Int, String](MojoHashFunction())
    
    # Pattern: insert, delete, insert, delete...
    for cycle in range(10):
        var key = cycle
        
        # Insert
        var inserted = table.insert(key, String("cycle_") + String(cycle))
        assert_true(inserted)
        assert_equal(1, table.size())
        
        # Verify
        var result = table.lookup(key)
        assert_true(result)
        assert_equal(String("cycle_") + String(cycle), result.value())
        
        # Delete
        var deleted = table.delete(key)
        assert_true(deleted)
        assert_equal(0, table.size())
        
        # Verify gone
        var after_delete = table.lookup(key)
        assert_false(after_delete)


fn test_small_to_medium_resize() raises:
    """Test the critical small table to medium table transition."""
    var table = SwissTable[Int, Int](MojoHashFunction())
    
    # Start with small table (capacity 16)
    assert_equal(16, table.capacity())
    
    # Insert elements to trigger first resize
    var first_threshold = (16 * 7) // 8  # 14 elements
    
    for i in range(first_threshold + 1):
        _ = table.insert(i, i * 10)
    
    # Should have resized to next power of 2 (32)
    assert_equal(32, table.capacity())
    assert_equal(first_threshold + 1, table.size())
    
    # Continue to next resize threshold  
    var second_threshold = (32 * 7) // 8  # 28 elements
    
    for i in range(first_threshold + 1, second_threshold + 1):
        _ = table.insert(i, i * 10)
    
    # Should have resized again (64)
    assert_equal(64, table.capacity())
    assert_equal(second_threshold + 1, table.size())
    
    # Verify all elements accessible across multiple resizes
    for i in range(second_threshold + 1):
        var result = table.lookup(i)
        assert_true(result)
        assert_equal(i * 10, result.value())


fn test_boundary_hash_values() raises:
    """Test with hash values at integer boundaries."""
    var table = SwissTable[Int, String](MojoHashFunction())
    
    # Test with values that might cause edge cases in hash computation
    var boundary_values = List[Int](0, 1, -1, 127, 128, 255, 256, 65535, 65536)
    
    for i in range(len(boundary_values)):
        var key = boundary_values[i]
        var inserted = table.insert(key, String("boundary_") + String(key))
        assert_true(inserted)
    
    # Verify all are findable
    for i in range(len(boundary_values)):
        var key = boundary_values[i]
        var result = table.lookup(key)
        assert_true(result)
        assert_equal(String("boundary_") + String(key), result.value())


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
    print("Running SwissTable Edge Case Tests:")
    print("=" * 50)
    
    test["test_empty_table_operations", test_empty_table_operations]()
    test["test_single_element_operations", test_single_element_operations]()
    test["test_capacity_boundaries", test_capacity_boundaries]()
    test["test_zero_capacity_edge_case", test_zero_capacity_edge_case]()
    test["test_maximum_single_probe", test_maximum_single_probe]()
    test["test_duplicate_insertions", test_duplicate_insertions]()
    test["test_alternating_insert_delete", test_alternating_insert_delete]()
    test["test_small_to_medium_resize", test_small_to_medium_resize]()
    test["test_boundary_hash_values", test_boundary_hash_values]()
    
    print()
    print("All edge case tests passed! ✅")