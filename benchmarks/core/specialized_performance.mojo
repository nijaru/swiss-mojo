#!/usr/bin/env mojo

"""
Specialized Table Performance Benchmarks.

Consolidated from test_specialized_performance.mojo, test_fast_int_int_performance.mojo,
and test_fast_string_string_performance.mojo to eliminate redundancy.
Tests specialized table performance vs generic SwissTable.
"""

from time import perf_counter_ns
from swisstable import SwissTable, FastStringIntTable, FastIntIntTable, FastStringStringTable, MojoHashFunction


struct SpecializedBenchmarkResult:
    var table_type: String
    var operations: Int
    var time_ns: Int
    var ops_per_sec: Float64
    var speedup_vs_generic: Float64

    fn __init__(inout self, table_type: String, operations: Int, time_ns: Int, generic_time_ns: Int):
        self.table_type = table_type
        self.operations = operations
        self.time_ns = time_ns
        self.ops_per_sec = Float64(operations) * 1e9 / Float64(time_ns)
        self.speedup_vs_generic = Float64(generic_time_ns) / Float64(time_ns)

    fn print_results(self):
        var ops_millions = self.ops_per_sec / 1e6
        print("  " + self.table_type + ":")
        print("    Operations/sec: " + str(ops_millions) + "M")
        print("    Speedup vs Generic: " + str(self.speedup_vs_generic) + "x")
        print("    Improvement: +" + str((self.speedup_vs_generic - 1.0) * 100) + "%")


fn benchmark_string_int_performance(iterations: Int = 100) -> (Int, Int):
    """Benchmark FastStringIntTable vs generic SwissTable[String, Int]."""
    
    # Prepare test data
    var keys = List[String]()
    var values = List[Int]()
    for i in range(1000):
        keys.append("benchmark_key_" + str(i))
        values.append(i * 123)
    
    # Benchmark FastStringIntTable
    var fast_total_time = 0
    for _ in range(iterations):
        var fast_table = FastStringIntTable()
        var start_time = perf_counter_ns()
        
        for i in range(len(keys)):
            _ = fast_table.insert(keys[i], values[i])
        
        var end_time = perf_counter_ns()
        fast_total_time += int(end_time - start_time)
    
    # Benchmark generic SwissTable
    var generic_total_time = 0
    for _ in range(iterations):
        var generic_table = SwissTable[String, Int](MojoHashFunction())
        var start_time = perf_counter_ns()
        
        for i in range(len(keys)):
            _ = generic_table.insert(keys[i], values[i])
        
        var end_time = perf_counter_ns()
        generic_total_time += int(end_time - start_time)
    
    return (fast_total_time, generic_total_time)


fn benchmark_int_int_performance(iterations: Int = 100) -> (Int, Int):
    """Benchmark FastIntIntTable vs generic SwissTable[Int, Int]."""
    
    # Prepare test data
    var keys = List[Int]()
    var values = List[Int]()
    for i in range(1000):
        keys.append(i + 1000000)  # Offset to avoid collisions
        values.append(i * 456)
    
    # Benchmark FastIntIntTable
    var fast_total_time = 0
    for _ in range(iterations):
        var fast_table = FastIntIntTable()
        var start_time = perf_counter_ns()
        
        for i in range(len(keys)):
            _ = fast_table.insert(keys[i], values[i])
        
        var end_time = perf_counter_ns()
        fast_total_time += int(end_time - start_time)
    
    # Benchmark generic SwissTable
    var generic_total_time = 0
    for _ in range(iterations):
        var generic_table = SwissTable[Int, Int](MojoHashFunction())
        var start_time = perf_counter_ns()
        
        for i in range(len(keys)):
            _ = generic_table.insert(keys[i], values[i])
        
        var end_time = perf_counter_ns()
        generic_total_time += int(end_time - start_time)
    
    return (fast_total_time, generic_total_time)


fn benchmark_string_string_performance(iterations: Int = 100) -> (Int, Int):
    """Benchmark FastStringStringTable vs generic SwissTable[String, String]."""
    
    # Prepare test data
    var keys = List[String]()
    var values = List[String]()
    for i in range(1000):
        keys.append("key_" + str(i))
        values.append("value_" + str(i * 789))
    
    # Benchmark FastStringStringTable
    var fast_total_time = 0
    for _ in range(iterations):
        var fast_table = FastStringStringTable()
        var start_time = perf_counter_ns()
        
        for i in range(len(keys)):
            _ = fast_table.insert(keys[i], values[i])
        
        var end_time = perf_counter_ns()
        fast_total_time += int(end_time - start_time)
    
    # Benchmark generic SwissTable
    var generic_total_time = 0
    for _ in range(iterations):
        var generic_table = SwissTable[String, String](MojoHashFunction())
        var start_time = perf_counter_ns()
        
        for i in range(len(keys)):
            _ = generic_table.insert(keys[i], values[i])
        
        var end_time = perf_counter_ns()
        generic_total_time += int(end_time - start_time)
    
    return (fast_total_time, generic_total_time)


fn run_specialized_benchmarks():
    """Run comprehensive specialized table benchmarks."""
    print("⚡ Specialized Table Performance Benchmarks")
    print("=" * 60)
    print("Comparing specialized tables vs generic SwissTable")
    print("Using 1000 insertions with 100 iterations each")
    print()
    
    # Benchmark FastStringIntTable
    print("🔤 FastStringIntTable Performance:")
    var string_int_times = benchmark_string_int_performance(100)
    var string_int_result = SpecializedBenchmarkResult("FastStringIntTable", 1000 * 100, string_int_times[0], string_int_times[1])
    string_int_result.print_results()
    print()
    
    # Benchmark FastIntIntTable
    print("🔢 FastIntIntTable Performance:")
    var int_int_times = benchmark_int_int_performance(100)
    var int_int_result = SpecializedBenchmarkResult("FastIntIntTable", 1000 * 100, int_int_times[0], int_int_times[1])
    int_int_result.print_results()
    print()
    
    # Benchmark FastStringStringTable
    print("📝 FastStringStringTable Performance:")
    var string_string_times = benchmark_string_string_performance(100)
    var string_string_result = SpecializedBenchmarkResult("FastStringStringTable", 1000 * 100, string_string_times[0], string_string_times[1])
    string_string_result.print_results()
    print()
    
    # Performance summary
    print("📊 Specialized Table Summary:")
    print("  FastStringIntTable: +" + str((string_int_result.speedup_vs_generic - 1.0) * 100) + "% improvement")
    print("  FastIntIntTable: +" + str((int_int_result.speedup_vs_generic - 1.0) * 100) + "% improvement")
    print("  FastStringStringTable: +" + str((string_string_result.speedup_vs_generic - 1.0) * 100) + "% improvement")
    print()
    
    # Validate performance claims
    var all_improved = (string_int_result.speedup_vs_generic >= 1.0 and 
                       int_int_result.speedup_vs_generic >= 1.0 and 
                       string_string_result.speedup_vs_generic >= 1.0)
    
    if all_improved:
        print("  ✅ All specialized tables show improvement over generic")
    else:
        print("  ❌ Some specialized tables underperforming")
    
    print()
    print("🎯 Specialized benchmarks completed!")


fn main():
    """Run specialized table performance benchmarks."""
    run_specialized_benchmarks()