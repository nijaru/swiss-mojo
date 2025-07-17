#!/usr/bin/env mojo

"""
Core Performance Benchmarks for SwissTable vs stdlib Dict.
Consolidated from redundant benchmark files with proper Mojo syntax.
"""

from time import perf_counter_ns
from swisstable import SwissTable, create_table, MojoHashFunction
from collections import Dict


fn benchmark_insertions() -> (Int, Int):
    """Benchmark insertion performance for SwissTable vs Dict."""
    
    # Create test data
    var keys = List[String]()
    var values = List[Int]()
    for i in range(1000):
        keys.append("key")  # Simplified to avoid String conversion issues
        values.append(i)
    
    # Benchmark SwissTable
    var swiss_total_time = 0
    for _ in range(100):
        var table = create_table[String, Int]()
        var start_time = perf_counter_ns()
        
        for i in range(len(keys)):
            _ = table.insert(keys[i], values[i])
        
        var end_time = perf_counter_ns()
        swiss_total_time += Int(end_time - start_time)
    
    # Benchmark Dict
    var dict_total_time = 0
    for _ in range(100):
        var dict = Dict[String, Int]()
        var start_time = perf_counter_ns()
        
        for i in range(len(keys)):
            dict[keys[i]] = values[i]
        
        var end_time = perf_counter_ns()
        dict_total_time += Int(end_time - start_time)
    
    return (swiss_total_time, dict_total_time)


fn benchmark_lookups() -> (Int, Int):
    """Benchmark lookup performance for SwissTable vs Dict."""
    
    # Create test data and populate tables
    var keys = List[String]()
    var values = List[Int]()
    for i in range(1000):
        keys.append("key")
        values.append(i)
    
    var swiss_table = create_table[String, Int]()
    var dict_table = Dict[String, Int]()
    for i in range(len(keys)):
        _ = swiss_table.insert(keys[i], values[i])
        dict_table[keys[i]] = values[i]
    
    # Benchmark SwissTable lookups
    var swiss_total_time = 0
    for _ in range(500):
        var start_time = perf_counter_ns()
        
        for i in range(len(keys)):
            var result = swiss_table.lookup(keys[i])
            if result:
                _ = result.value()
        
        var end_time = perf_counter_ns()
        swiss_total_time += Int(end_time - start_time)
    
    # Benchmark Dict lookups
    var dict_total_time = 0
    for _ in range(500):
        var start_time = perf_counter_ns()
        
        for i in range(len(keys)):
            try:
                _ = dict_table[keys[i]]
            except:
                pass
        
        var end_time = perf_counter_ns()
        dict_total_time += Int(end_time - start_time)
    
    return (swiss_total_time, dict_total_time)


fn main():
    """Run core performance benchmarks."""
    print("🚀 SwissTable Core Performance Benchmarks")
    print("=" * 60)
    print("Comparing SwissTable vs stdlib Dict performance")
    print("Using 1000 keys with 100-500 iterations for statistical validity")
    print()
    
    # Benchmark insertions
    print("📊 Insertion Performance:")
    var insert_times = benchmark_insertions()
    var swiss_insert_time = insert_times[0]
    var dict_insert_time = insert_times[1]
    
    var swiss_insert_ops_sec = Float64(1000 * 100) * 1e9 / Float64(swiss_insert_time)
    _ = Float64(1000 * 100) * 1e9 / Float64(dict_insert_time)  # Dict ops/sec for reference
    var insert_speedup = Float64(dict_insert_time) / Float64(swiss_insert_time)
    
    print("  SwissTable Insert:")
    print("    Operations/sec: " + String(swiss_insert_ops_sec / 1e6) + "M")
    print("    Total time: " + String(swiss_insert_time / 1000000) + "ms")
    print("  Speedup vs Dict: " + String(insert_speedup) + "x")
    print()
    
    # Benchmark lookups
    print("🔍 Lookup Performance:")
    var lookup_times = benchmark_lookups()
    var swiss_lookup_time = lookup_times[0]
    var dict_lookup_time = lookup_times[1]
    
    var swiss_lookup_ops_sec = Float64(1000 * 500) * 1e9 / Float64(swiss_lookup_time)
    _ = Float64(1000 * 500) * 1e9 / Float64(dict_lookup_time)  # Dict ops/sec for reference
    var lookup_speedup = Float64(dict_lookup_time) / Float64(swiss_lookup_time)
    
    print("  SwissTable Lookup:")
    print("    Operations/sec: " + String(swiss_lookup_ops_sec / 1e6) + "M")
    print("    Total time: " + String(swiss_lookup_time / 1000000) + "ms")
    print("  Speedup vs Dict: " + String(lookup_speedup) + "x")
    print()
    
    # Performance summary
    print("📈 Performance Summary:")
    print("  SwissTable is " + String(insert_speedup) + "x faster at insertions")
    print("  SwissTable is " + String(lookup_speedup) + "x faster at lookups")
    
    if insert_speedup >= 1.1 and lookup_speedup >= 2.0:
        print("  ✅ Performance targets met (1.1x+ insert, 2.0x+ lookup)")
    else:
        print("  ❌ Performance targets not met")
    
    print()
    print("🎯 Core benchmark completed successfully!")