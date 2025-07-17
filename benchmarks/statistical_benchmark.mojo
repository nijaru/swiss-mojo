#!/usr/bin/env mojo
"""Statistical performance validation with multiple runs and confidence intervals.

Runs benchmarks multiple times to provide statistically meaningful results
with variance analysis and confidence intervals.
"""

from time import perf_counter_ns
from random import random_ui64, seed
from collections import Dict
from swisstable import SwissTable, DefaultHashFunction
from math import sqrt


struct StatResults(Copyable, Movable):
    var mean: Float64
    var std_dev: Float64
    var min_val: Float64
    var max_val: Float64
    var runs: Int
    
    fn __init__(out self, values: List[Float64]):
        self.runs = len(values)
        
        # Calculate mean
        var sum: Float64 = 0.0
        for i in range(len(values)):
            sum += values[i]
        self.mean = sum / Float64(len(values))
        
        # Calculate min/max
        self.min_val = values[0]
        self.max_val = values[0]
        for i in range(len(values)):
            if values[i] < self.min_val:
                self.min_val = values[i]
            if values[i] > self.max_val:
                self.max_val = values[i]
        
        # Calculate standard deviation
        var variance_sum: Float64 = 0.0
        for i in range(len(values)):
            var diff = values[i] - self.mean
            variance_sum += diff * diff
        self.std_dev = sqrt(variance_sum / Float64(len(values)))
    
    fn confidence_interval_95(self) -> (Float64, Float64):
        """Calculate 95% confidence interval assuming normal distribution."""
        # Using t-distribution critical value for small samples (approx 2.0 for n=10)
        var margin = 2.0 * (self.std_dev / sqrt(Float64(self.runs)))
        return (self.mean - margin, self.mean + margin)
    
    fn print_stats(self, name: String):
        var ci = self.confidence_interval_95()
        print("=== " + name + " ===")
        print("  Mean: ", self.mean, " ms")
        print("  Std Dev: ", self.std_dev, " ms")
        print("  95% CI: [", ci[0], ", ", ci[1], "] ms")
        print("  Range: [", self.min_val, ", ", self.max_val, "] ms")
        print("  Runs: ", self.runs)
        print()


fn benchmark_insertion_multiple_runs(key_count: Int, iterations: Int, runs: Int) raises -> (StatResults, StatResults):
    """Run insertion benchmark multiple times for statistical validation."""
    print("Running insertion benchmark: " + String(key_count) + " keys, " + 
          String(iterations) + " iterations, " + String(runs) + " runs")
    
    var dict_times = List[Float64]()
    var swiss_times = List[Float64]()
    
    # Generate test keys once
    var keys = List[String]()
    for i in range(key_count):
        keys.append("key_" + String(i))
    
    for run in range(runs):
        print("  Run " + String(run + 1) + "/" + String(runs))
        
        # Dict insertion timing
        var dict_total: Float64 = 0.0
        for iter in range(iterations):
            var dict = Dict[String, Int]()
            var start = perf_counter_ns()
            for i in range(key_count):
                dict[keys[i]] = i
            var end = perf_counter_ns()
            dict_total += Float64(end - start) / 1e6
        dict_times.append(dict_total / Float64(iterations))
        
        # SwissTable insertion timing
        var swiss_total: Float64 = 0.0
        for iter in range(iterations):
            var table = SwissTable[String, Int](DefaultHashFunction())
            var start = perf_counter_ns()
            for i in range(key_count):
                _ = table.insert(keys[i], i)
            var end = perf_counter_ns()
            swiss_total += Float64(end - start) / 1e6
        swiss_times.append(swiss_total / Float64(iterations))
    
    return (StatResults(dict_times), StatResults(swiss_times))


fn benchmark_lookup_multiple_runs(key_count: Int, iterations: Int, runs: Int) raises -> (StatResults, StatResults):
    """Run lookup benchmark multiple times for statistical validation."""
    print("Running lookup benchmark: " + String(key_count) + " keys, " + 
          String(iterations) + " iterations, " + String(runs) + " runs")
    
    var dict_times = List[Float64]()
    var swiss_times = List[Float64]()
    
    # Generate test keys once
    var keys = List[String]()
    for i in range(key_count):
        keys.append("key_" + String(i))
    
    for run in range(runs):
        print("  Run " + String(run + 1) + "/" + String(runs))
        
        # Pre-populate tables for this run
        var dict = Dict[String, Int]()
        var table = SwissTable[String, Int](DefaultHashFunction())
        for i in range(key_count):
            dict[keys[i]] = i
            _ = table.insert(keys[i], i)
        
        # Dict lookup timing
        var dict_total: Float64 = 0.0
        for iter in range(iterations):
            var start = perf_counter_ns()
            for i in range(key_count):
                var value = dict[keys[i]]
            var end = perf_counter_ns()
            dict_total += Float64(end - start) / 1e6
        dict_times.append(dict_total / Float64(iterations))
        
        # SwissTable lookup timing
        var swiss_total: Float64 = 0.0
        for iter in range(iterations):
            var start = perf_counter_ns()
            for i in range(key_count):
                var value = table.lookup(keys[i])
            var end = perf_counter_ns()
            swiss_total += Float64(end - start) / 1e6
        swiss_times.append(swiss_total / Float64(iterations))
    
    return (StatResults(dict_times), StatResults(swiss_times))


fn print_performance_comparison(dict_stats: StatResults, swiss_stats: StatResults, operation: String):
    """Print detailed performance comparison with statistical significance."""
    var speedup = dict_stats.mean / swiss_stats.mean
    var speedup_ci_low = dict_stats.confidence_interval_95()[0] / swiss_stats.confidence_interval_95()[1]
    var speedup_ci_high = dict_stats.confidence_interval_95()[1] / swiss_stats.confidence_interval_95()[0]
    
    print("=== " + operation + " Performance Comparison ===")
    print("Dict time: ", dict_stats.mean, " ± ", dict_stats.std_dev, " ms")
    print("SwissTable time: ", swiss_stats.mean, " ± ", swiss_stats.std_dev, " ms")
    print("Speedup: ", speedup, "x (95% CI: [", speedup_ci_low, ", ", speedup_ci_high, "])")
    
    # Statistical significance check (rough)
    var difference = dict_stats.mean - swiss_stats.mean
    var pooled_std = sqrt((dict_stats.std_dev * dict_stats.std_dev + swiss_stats.std_dev * swiss_stats.std_dev) / 2.0)
    var t_stat = difference / (pooled_std * sqrt(2.0 / Float64(dict_stats.runs)))
    
    if t_stat > 2.0:  # Rough t-test for significance
        print("Result: ✅ Statistically significant improvement")
    else:
        print("Result: ⚠️  Improvement not statistically significant")
    print()


fn main() raises:
    print("=== Statistical Performance Validation ===")
    print("Multiple runs with confidence intervals and significance testing")
    print()
    
    seed()
    
    # Test different scales with multiple runs
    var scales = List[Int]()
    scales.append(10)
    scales.append(100)
    scales.append(500)
    scales.append(1000)
    
    alias ITERATIONS = 50  # Reduced iterations for multiple runs
    alias RUNS = 10        # Multiple independent runs for statistics
    
    for i in range(len(scales)):
        var scale = scales[i]
        print(">>> Testing scale: " + String(scale) + " keys <<<")
        print()
        
        # Insertion benchmark
        var insertion_results = benchmark_insertion_multiple_runs(scale, ITERATIONS, RUNS)
        insertion_results[0].print_stats("Dict Insertion")
        insertion_results[1].print_stats("SwissTable Insertion")
        print_performance_comparison(insertion_results[0], insertion_results[1], "Insertion")
        
        # Lookup benchmark
        var lookup_results = benchmark_lookup_multiple_runs(scale, ITERATIONS, RUNS)
        lookup_results[0].print_stats("Dict Lookup")
        lookup_results[1].print_stats("SwissTable Lookup")
        print_performance_comparison(lookup_results[0], lookup_results[1], "Lookup")
        
        print("-" * 60)
        print()
    
    print("=== Summary ===")
    print("All results include 95% confidence intervals and statistical significance testing.")
    print("Multiple independent runs validate the consistency of performance improvements.")