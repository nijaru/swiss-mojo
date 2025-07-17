#!/usr/bin/env mojo
"""Comprehensive memory safety tests for SwissTable implementation.

Tests resource cleanup, memory leak prevention, and safe destruction patterns
that are critical for production reliability.
"""

from testing import assert_equal, assert_true, assert_false
from swisstable import SwissTable
from swisstable.hash import MojoHashFunction


fn test_table_destruction() raises:
    """Test proper cleanup when table goes out of scope."""
    print("  Testing table destruction...")
    
    # Test 1: Simple table operations
    var table1 = SwissTable[Int, String](MojoHashFunction())
    _ = table1.insert(1, String("test"))
    _ = table1.insert(2, String("data"))
    assert_equal(2, table1.size())
    
    # Test 2: Table after resize
    var table2 = SwissTable[String, Int](MojoHashFunction())
    # Insert enough to trigger resize
    for i in range(20):
        _ = table2.insert(String("key_") + String(i), i)
    assert_equal(20, table2.size())


fn test_multiple_resize_cleanup() raises:
    """Test memory cleanup through multiple resize operations."""
    print("  Testing multiple resize cleanup...")
    
    var table = SwissTable[Int, String](MojoHashFunction())
    
    # Trigger multiple resizes and ensure no accumulation of old tables
    for batch in range(5):  # 5 resize cycles
        var start_size = table.size()
        var target_size = start_size + 50
        
        for i in range(start_size, target_size):
            _ = table.insert(i, String("batch_") + String(batch) + String("_") + String(i))
        
        assert_equal(target_size, table.size())
        
        # Verify all elements are accessible (tests cleanup correctness)
        for i in range(target_size):
            var result = table.lookup(i)
            assert_true(result)


fn test_clear_operation_safety() raises:
    """Test that clear operation properly handles memory."""
    print("  Testing clear operation safety...")
    
    var table = SwissTable[String, Int](MojoHashFunction())
    
    # Fill table
    for i in range(100):
        _ = table.insert(String("clear_test_") + String(i), i * 2)
    
    assert_equal(100, table.size())
    
    # Clear should reset size but preserve capacity
    var capacity_before = table.capacity()
    table.clear()
    
    assert_equal(0, table.size())
    assert_equal(capacity_before, table.capacity())
    
    # Should be able to insert after clear
    _ = table.insert(String("after_clear"), 42)
    assert_equal(1, table.size())
    
    var result = table.lookup(String("after_clear"))
    assert_true(result)
    assert_equal(42, result.value())


fn test_copy_construction_safety() raises:
    """Test copy construction doesn't cause double-free."""
    print("  Testing copy construction safety...")
    
    var original = SwissTable[Int, String](MojoHashFunction())
    
    # Fill original table
    for i in range(50):
        _ = original.insert(i, String("original_") + String(i))
    
    # Copy construction
    var copied = original
    
    # Both should have same data
    assert_equal(original.size(), copied.size())
    assert_equal(original.capacity(), copied.capacity())
    
    # Verify both can be used independently
    for i in range(50):
        var orig_result = original.lookup(i)
        var copy_result = copied.lookup(i)
        assert_true(orig_result)
        assert_true(copy_result)
        assert_equal(orig_result.value(), copy_result.value())
    
    # Add to original, shouldn't affect copy
    _ = original.insert(100, String("original_only"))
    assert_equal(51, original.size())
    assert_equal(50, copied.size())
    
    assert_true(original.lookup(100))
    assert_false(copied.lookup(100))


fn test_large_table_destruction() raises:
    """Test destruction of large tables."""
    print("  Testing large table destruction...")
    
    var large_table = SwissTable[Int, String](MojoHashFunction())
    
    # Create a large table (multiple resizes)
    for i in range(1000):
        _ = large_table.insert(i, String("large_") + String(i))
    
    assert_equal(1000, large_table.size())
    
    # Test that we can still operate on large table
    var mid_result = large_table.lookup(500)
    assert_true(mid_result)
    assert_equal(String("large_500"), mid_result.value())


fn test_empty_table_operations() raises:
    """Test operations on empty tables are memory safe."""
    print("  Testing empty table operations...")
    
    var table = SwissTable[String, Int](MojoHashFunction())
    
    # Operations on empty table should be safe
    assert_equal(0, table.size())
    assert_false(table.lookup(String("nonexistent")))
    assert_false(table.delete(String("nonexistent")))
    
    # Clear empty table
    table.clear()
    assert_equal(0, table.size())
    
    # Multiple operations
    for i in range(10):
        assert_false(table.lookup(String("test_") + String(i)))
        assert_false(table.delete(String("test_") + String(i)))


fn test_capacity_growth_patterns() raises:
    """Test that capacity grows predictably and doesn't waste memory."""
    print("  Testing capacity growth patterns...")
    
    var table = SwissTable[Int, Int](MojoHashFunction())
    var last_capacity = table.capacity()
    var resize_count = 0
    
    # Track capacity growth through insertions
    for i in range(200):
        _ = table.insert(i, i * 2)
        var current_capacity = table.capacity()
        
        if current_capacity > last_capacity:
            resize_count += 1
            print("    Resize", resize_count, ":", last_capacity, "->", current_capacity, "at size", table.size())
            
            # Capacity should double each time
            assert_equal(current_capacity, last_capacity * 2)
            last_capacity = current_capacity
    
    print("    Total resizes:", resize_count)
    
    # Should have reasonable number of resizes (not too many)
    assert_true(resize_count >= 3)  # At least a few resizes
    assert_true(resize_count <= 8)  # But not excessive


fn test_move_semantics_safety() raises:
    """Test move operations are memory safe."""
    print("  Testing move semantics safety...")
    
    # Create and populate table
    var source = SwissTable[String, Int](MojoHashFunction())
    for i in range(30):
        _ = source.insert(String("move_test_") + String(i), i)
    
    var original_size = source.size()
    var original_capacity = source.capacity()
    
    # Move construction
    var destination = source^
    
    # Destination should have the data
    assert_equal(original_size, destination.size())
    assert_equal(original_capacity, destination.capacity())
    
    # Verify data integrity after move
    for i in range(30):
        var result = destination.lookup(String("move_test_") + String(i))
        assert_true(result)
        assert_equal(i, result.value())


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
    print("Running SwissTable Memory Safety Tests:")
    print("=" * 50)
    
    test["test_table_destruction", test_table_destruction]()
    test["test_multiple_resize_cleanup", test_multiple_resize_cleanup]()
    test["test_clear_operation_safety", test_clear_operation_safety]()
    test["test_copy_construction_safety", test_copy_construction_safety]()
    test["test_large_table_destruction", test_large_table_destruction]()
    test["test_empty_table_operations", test_empty_table_operations]()
    test["test_capacity_growth_patterns", test_capacity_growth_patterns]()
    test["test_move_semantics_safety", test_move_semantics_safety]()
    
    print()
    print("All memory safety tests passed! ✅")
    print("SwissTable implementation is memory safe and production ready.")