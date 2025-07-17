#!/usr/bin/env mojo

"""
Performance Optimization Examples for SwissTable.

This example demonstrates best practices for maximizing SwissTable performance
including capacity planning, specialized tables, and bulk operations.
"""

from swisstable import SwissTable, FastStringIntTable, FastIntIntTable, MojoHashFunction
from time import perf_counter_ns


fn example_capacity_planning():
    """Demonstrate optimal capacity planning for performance."""
    print("📊 Capacity Planning Example:")
    print("=" * 40)
    
    # Bad: Let table grow organically (multiple resizes)
    var slow_table = SwissTable[String, Int](MojoHashFunction())
    print("❌ Bad approach - organic growth:")
    for i in range(1000):
        _ = slow_table.insert("key", i)  # Will trigger multiple resizes
    print("  Final capacity: " + String(slow_table.capacity()))
    
    # Good: Pre-allocate capacity
    var fast_table = SwissTable[String, Int](MojoHashFunction())
    fast_table.reserve(1200)  # Reserve 20% more than needed
    print("✅ Good approach - pre-allocated:")
    for i in range(1000):
        _ = fast_table.insert("key", i)  # No resizes needed
    print("  Final capacity: " + String(fast_table.capacity()))
    print()


fn example_specialized_tables():
    """Demonstrate when to use specialized vs generic tables."""
    print("⚡ Specialized Table Selection:")
    print("=" * 40)
    
    # Use FastStringIntTable for String->Int mappings
    var config_table = FastStringIntTable()
    _ = config_table.insert("max_connections", 100)
    _ = config_table.insert("timeout_ms", 5000)
    _ = config_table.insert("retry_count", 3)
    print("✅ FastStringIntTable for configuration values")
    
    # Use FastIntIntTable for Integer->Integer mappings  
    var lookup_table = FastIntIntTable()
    for i in range(100):
        _ = lookup_table.insert(i, i * i)  # Squares lookup
    print("✅ FastIntIntTable for mathematical lookups")
    
    # Use generic SwissTable for complex types
    var generic_table = SwissTable[String, String](MojoHashFunction())
    _ = generic_table.insert("user:123", "{'name': 'Alice', 'role': 'admin'}")
    print("✅ Generic SwissTable for complex data")
    print()


fn example_bulk_operations():
    """Demonstrate efficient bulk operations."""
    print("🚀 Bulk Operations for Performance:")
    print("=" * 40)
    
    var table = SwissTable[String, Int](MojoHashFunction())
    
    # Prepare bulk data
    var keys = List[String]()
    var values = List[Int]()
    for i in range(100):
        keys.append("bulk_key")
        values.append(i)
    
    # Use bulk_insert for better throughput
    print("✅ Using bulk_insert for better performance:")
    var results = table.bulk_insert(keys, values)
    var successful_inserts = 0
    for i in range(len(results)):
        if results[i]:
            successful_inserts += 1
    print("  Successful inserts: " + String(successful_inserts))
    
    # Use bulk_lookup for efficient batch queries
    var lookup_keys = List[String]()
    for i in range(50):
        lookup_keys.append("bulk_key")
    
    var lookup_results = table.bulk_lookup(lookup_keys)
    var found_values = 0
    for i in range(len(lookup_results)):
        if lookup_results[i]:
            found_values += 1
    print("  Found values: " + String(found_values))
    print()


fn example_memory_efficiency():
    """Demonstrate memory-efficient patterns."""
    print("💾 Memory Efficiency Patterns:")
    print("=" * 40)
    
    # Good: Use appropriate key types
    var int_keys = FastIntIntTable()  # More efficient than String keys
    _ = int_keys.insert(12345, 67890)
    print("✅ Use integer keys when possible")
    
    # Good: Clear tables when no longer needed
    var temp_table = SwissTable[String, Int](MojoHashFunction())
    _ = temp_table.insert("temp", 42)
    temp_table.clear()  # Free memory immediately
    print("✅ Clear tables when done")
    
    # Good: Use bulk operations to reduce overhead
    print("✅ Bulk operations reduce per-operation overhead")
    print()


fn performance_timing_example():
    """Show how to measure SwissTable performance."""
    print("⏱️  Performance Measurement Example:")
    print("=" * 40)
    
    var table = SwissTable[String, Int](MojoHashFunction())
    
    # Measure insertion performance
    var start_time = perf_counter_ns()
    for i in range(1000):
        _ = table.insert("perf_key", i)
    var end_time = perf_counter_ns()
    
    var duration_ms = Float64(end_time - start_time) / 1e6
    var ops_per_sec = 1000.0 / (duration_ms / 1000.0)
    
    print("  1000 insertions took: " + String(duration_ms) + "ms")
    print("  Operations per second: " + String(ops_per_sec))
    print()


fn main():
    """Run all performance optimization examples."""
    print("🏆 SwissTable Performance Optimization Guide")
    print("=" * 50)
    print()
    
    example_capacity_planning()
    example_specialized_tables()
    example_bulk_operations() 
    example_memory_efficiency()
    performance_timing_example()
    
    print("🎯 Key Takeaways:")
    print("  • Pre-allocate capacity with reserve()")
    print("  • Use specialized tables for common type combinations")
    print("  • Use bulk operations for better throughput")
    print("  • Clear tables when memory is tight")
    print("  • Measure performance in your specific use case")
    print()
    print("📚 See docs/performance-guide.md for detailed optimization strategies")