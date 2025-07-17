"""Detailed performance profiling to identify bottlenecks vs stdlib Dict.

This benchmark creates micro-benchmarks for individual operations to understand
where time is spent compared to stdlib Dict operations.
"""

from time import perf_counter_ns
from random import random_ui64, seed
from collections import Dict
from swisstable import SwissTable
from swisstable.hash import DefaultHashFunction


struct ProfileResults(Copyable, Movable):
    var dict_time: Float64
    var swiss_table_time: Float64  
    var operation: String
    var key_count: Int
    
    fn __init__(out self, operation: String, key_count: Int):
        self.operation = operation
        self.key_count = key_count
        self.dict_time = 0.0
        self.swiss_table_time = 0.0
    
    fn swiss_table_speedup(self) -> Float64:
        return self.dict_time / self.swiss_table_time
    
    fn print_results(self):
        print("=== " + self.operation + " (" + String(self.key_count) + " keys) ===")
        print("Dict time:       ", self.dict_time, "ms")
        print("SwissTable time: ", self.swiss_table_time, "ms (", 
              String(self.swiss_table_speedup()) + "x)")
        print()


fn profile_insertion(key_count: Int, iterations: Int = 100) raises -> ProfileResults:
    """Profile pure insertion performance."""
    var results = ProfileResults("Insertion", key_count)
    
    # Generate test keys once
    var keys = List[String]()
    for i in range(key_count):
        keys.append("key_" + String(i))
    
    # Profile Dict insertion
    var dict_total: Float64 = 0.0
    for iter in range(iterations):
        var dict = Dict[String, Int]()
        var start = perf_counter_ns()
        for i in range(key_count):
            dict[keys[i]] = i
        var end = perf_counter_ns()
        dict_total += Float64(end - start) / 1e6  # Convert to ms
    results.dict_time = dict_total / Float64(iterations)
    
    # Profile SwissTable insertion 
    var swiss_table_total: Float64 = 0.0
    for iter in range(iterations):
        var table = SwissTable[String, Int](DefaultHashFunction())
        var start = perf_counter_ns()
        for i in range(key_count):
            _ = table.insert(keys[i], i)
        var end = perf_counter_ns()
        swiss_table_total += Float64(end - start) / 1e6
    results.swiss_table_time = swiss_table_total / Float64(iterations)
    
    
    return results


fn profile_lookup(key_count: Int, iterations: Int = 100) raises -> ProfileResults:
    """Profile lookup performance with pre-populated tables."""
    var results = ProfileResults("Lookup", key_count)
    
    # Generate test keys
    var keys = List[String]()
    for i in range(key_count):
        keys.append("key_" + String(i))
    
    # Pre-populate Dict
    var dict = Dict[String, Int]()
    for i in range(key_count):
        dict[keys[i]] = i
    
    # Pre-populate SwissTable
    var table = SwissTable[String, Int](DefaultHashFunction())
    for i in range(key_count):
        _ = table.insert(keys[i], i)
    
    
    # Profile Dict lookup
    var dict_total: Float64 = 0.0
    for iter in range(iterations):
        var start = perf_counter_ns()
        for i in range(key_count):
            var value = dict[keys[i]]
        var end = perf_counter_ns()
        dict_total += Float64(end - start) / 1e6
    results.dict_time = dict_total / Float64(iterations)
    
    # Profile SwissTable lookup
    var swiss_table_total: Float64 = 0.0
    for iter in range(iterations):
        var start = perf_counter_ns()
        for i in range(key_count):
            var value = table.lookup(keys[i])
        var end = perf_counter_ns()
        swiss_table_total += Float64(end - start) / 1e6
    results.swiss_table_time = swiss_table_total / Float64(iterations)
    
    
    return results


fn profile_hash_operations(key_count: Int, iterations: Int = 1000) raises -> ProfileResults:
    """Profile just hash computation overhead."""
    var results = ProfileResults("Hash Computation", key_count)
    
    var keys = List[String]()
    for i in range(key_count):
        keys.append("key_" + String(i))
    
    # Profile direct hash function calls
    var hash_fn = DefaultHashFunction()
    var hash_total: Float64 = 0.0
    for iter in range(iterations):
        var start = perf_counter_ns()
        for i in range(key_count):
            var h = hash_fn.hash(keys[i])
        var end = perf_counter_ns()
        hash_total += Float64(end - start) / 1e6
    
    # For comparison purposes, set this as "swiss_table_time"
    results.swiss_table_time = hash_total / Float64(iterations)
    results.dict_time = results.swiss_table_time  # Assume same hash cost
    
    return results


fn profile_mixed_workload(key_count: Int, iterations: Int = 50) raises -> ProfileResults:
    """Profile realistic mixed insert/lookup workload."""
    var results = ProfileResults("Mixed Workload", key_count)
    
    var keys = List[String]()
    for i in range(key_count * 2):  # More keys than we'll use
        keys.append("key_" + String(i))
    
    # Profile Dict mixed workload
    var dict_total: Float64 = 0.0
    for iter in range(iterations):
        var dict = Dict[String, Int]()
        var start = perf_counter_ns()
        
        # Insert half the keys
        for i in range(key_count // 2):
            dict[keys[i]] = i
        
        # Mix of lookups and insertions
        for i in range(key_count // 2, key_count):
            if i % 3 == 0:
                # Lookup existing key
                var value = dict[keys[i % (key_count // 2)]]
            else:
                # Insert new key
                dict[keys[i]] = i
        
        var end = perf_counter_ns()
        dict_total += Float64(end - start) / 1e6
    results.dict_time = dict_total / Float64(iterations)
    
    # Profile SwissTable mixed workload
    var swiss_table_total: Float64 = 0.0
    for iter in range(iterations):
        var table = SwissTable[String, Int](DefaultHashFunction())
        var start = perf_counter_ns()
        
        for i in range(key_count // 2):
            _ = table.insert(keys[i], i)
        
        for i in range(key_count // 2, key_count):
            if i % 3 == 0:
                var value = table.lookup(keys[i % (key_count // 2)])
            else:
                _ = table.insert(keys[i], i)
        
        var end = perf_counter_ns()
        swiss_table_total += Float64(end - start) / 1e6
    results.swiss_table_time = swiss_table_total / Float64(iterations)
    
    
    return results


fn main() raises:
    print("=== Detailed Performance Profiling vs stdlib Dict ===")
    print("Analyzing individual operations to identify bottlenecks")
    print()
    
    seed()
    
    # Test different table sizes
    var sizes = List[Int]()
    sizes.append(10)
    sizes.append(100)  
    sizes.append(500)
    sizes.append(1000)
    
    for i in range(len(sizes)):
        var size = sizes[i]
        print(">>> Table size:", String(size), "keys <<<")
        
        # Profile individual operations
        var insertion_results = profile_insertion(size, 100)
        insertion_results.print_results()
        
        var lookup_results = profile_lookup(size, 100)
        lookup_results.print_results()
        
        var mixed_results = profile_mixed_workload(size, 50)
        mixed_results.print_results()
        
        print("-" * 50)
    
    # Profile hash computation separately
    print(">>> Hash Function Overhead <<<")
    var hash_results = profile_hash_operations(1000, 1000)
    print("Hash computation time (1000 keys, 1000 iterations):", hash_results.swiss_table_time, "ms")
    print()
    
    print("=== Analysis Summary ===")
    print("Use this data to identify the largest performance gaps")
    print("Focus optimization efforts on operations showing the most significant slowdowns")