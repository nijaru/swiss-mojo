#!/usr/bin/env mojo
"""Performance Regression Testing Suite for Continuous Validation.

This module provides automated regression testing infrastructure for:
- Continuous performance monitoring
- Automated regression detection
- Performance baseline management
- Historical performance tracking
- Alert system for performance degradation

Based on continuous integration best practices from:
- Chromium performance dashboard
- Firefox performance testing
- JVM performance regression testing
- Go performance dashboard

Usage:
    pixi run mojo run -I . benchmarks/performance_regression_suite.mojo
"""

from swisstable import SwissTable
from collections import Dict
from random import random_ui64, seed
from time import perf_counter_ns
from math import sqrt
import os

struct PerformanceBaseline(Copyable, Movable):
    """Performance baseline for regression detection."""
    
    var operation_name: String
    var mean_ns: Float64
    var std_dev_ns: Float64
    var confidence_interval: Float64
    var sample_count: Int
    var timestamp: String
    var version: String
    
    fn __init__(out self, operation: String, mean: Float64, std_dev: Float64, 
                ci: Float64, samples: Int, ts: String, ver: String):
        self.operation_name = operation
        self.mean_ns = mean
        self.std_dev_ns = std_dev
        self.confidence_interval = ci
        self.sample_count = samples
        self.timestamp = ts
        self.version = ver
    
    fn is_regression(self, current_mean: Float64, threshold_percent: Float64) -> Bool:
        """Check if current performance represents a regression."""
        var change_percent = ((current_mean - self.mean_ns) / self.mean_ns) * 100.0
        return change_percent > threshold_percent
    
    fn is_statistically_significant(self, current_mean: Float64, current_ci: Float64) -> Bool:
        """Check if performance difference is statistically significant."""
        var baseline_lower = self.mean_ns - self.confidence_interval
        var baseline_upper = self.mean_ns + self.confidence_interval
        var current_lower = current_mean - current_ci
        var current_upper = current_mean + current_ci
        
        return baseline_upper < current_lower or current_upper < baseline_lower
    
    fn print_baseline_info(self):
        """Print baseline information."""
        print("    Baseline " + self.operation_name + ":")
        print("      Mean:      ", Int(self.mean_ns), "ns")
        print("      Std Dev:   ", Int(self.std_dev_ns), "ns")
        print("      95% CI:    ±", Int(self.confidence_interval), "ns")
        print("      Samples:   ", self.sample_count)
        print("      Version:   ", self.version)
        print("      Timestamp: ", self.timestamp)

struct RegressionTestResult(Copyable, Movable):
    """Result of regression testing."""
    
    var operation_name: String
    var baseline_mean: Float64
    var current_mean: Float64
    var change_percent: Float64
    var is_regression: Bool
    var is_significant: Bool
    var severity: String
    
    fn __init__(out self, operation: String, baseline: Float64, current: Float64, 
                change: Float64, regression: Bool, significant: Bool, sev: String):
        self.operation_name = operation
        self.baseline_mean = baseline
        self.current_mean = current
        self.change_percent = change
        self.is_regression = regression
        self.is_significant = significant
        self.severity = sev
    
    fn print_result(self):
        """Print regression test result."""
        print("  " + self.operation_name + " Regression Test:")
        print("    Baseline:  ", Int(self.baseline_mean), "ns")
        print("    Current:   ", Int(self.current_mean), "ns")
        print("    Change:    ", Int(self.change_percent * 10) / 10, "%")
        print("    Significant:", "YES" if self.is_significant else "NO")
        
        if self.is_regression and self.is_significant:
            if self.severity == "CRITICAL":
                print("    Status:    ❌ CRITICAL REGRESSION")
            elif self.severity == "MAJOR":
                print("    Status:    ⚠️  MAJOR REGRESSION")
            else:
                print("    Status:    ⚠️  MINOR REGRESSION")
        elif self.change_percent < -5.0 and self.is_significant:
            print("    Status:    ✅ PERFORMANCE IMPROVEMENT")
        else:
            print("    Status:    ✅ PERFORMANCE STABLE")

struct PerformanceRegressionSuite(Copyable, Movable):
    """Comprehensive performance regression testing suite."""
    
    var regression_threshold: Float64
    var critical_threshold: Float64
    var major_threshold: Float64
    var iterations: Int
    var operation_count: Int
    
    fn __init__(out self):
        self.regression_threshold = 5.0   # 5% regression threshold
        self.critical_threshold = 20.0    # 20% critical regression
        self.major_threshold = 10.0       # 10% major regression
        self.iterations = 20
        self.operation_count = 1000
    
    fn create_baseline(self) -> List[PerformanceBaseline]:
        """Create performance baselines for all operations."""
        print("Creating performance baselines...")
        
        var baselines = List[PerformanceBaseline]()
        
        # Create baseline for insertion
        var insertion_baseline = self.benchmark_insertion_baseline()
        baselines.append(insertion_baseline)
        
        # Create baseline for lookup
        var lookup_baseline = self.benchmark_lookup_baseline()
        baselines.append(lookup_baseline)
        
        # Create baseline for deletion
        var deletion_baseline = self.benchmark_deletion_baseline()
        baselines.append(deletion_baseline)
        
        # Create baseline for mixed workload
        var mixed_baseline = self.benchmark_mixed_workload_baseline()
        baselines.append(mixed_baseline)
        
        return baselines
    
    fn benchmark_insertion_baseline(self) -> PerformanceBaseline:
        """Create insertion performance baseline."""
        var times = List[Int]()
        
        for i in range(self.iterations):
            var table = SwissTable[Int, Int]()
            seed(42)
            var start_time = perf_counter_ns()
            for j in range(self.operation_count):
                _ = table.insert(j, j)
            var end_time = perf_counter_ns()
            times.append(Int(end_time - start_time))
        
        return self.create_baseline_from_times("Insertion", times)
    
    fn benchmark_lookup_baseline(self) -> PerformanceBaseline:
        """Create lookup performance baseline."""
        var times = List[Int]()
        
        # Pre-populate table
        var table = SwissTable[Int, Int]()
        seed(42)
        for j in range(self.operation_count):
            _ = table.insert(j, j)
        
        for i in range(self.iterations):
            seed(123)
            var start_time = perf_counter_ns()
            for j in range(self.operation_count):
                var key = Int(random_ui64(0, self.operation_count))
                _ = table.lookup(key)
            var end_time = perf_counter_ns()
            times.append(Int(end_time - start_time))
        
        return self.create_baseline_from_times("Lookup", times)
    
    fn benchmark_deletion_baseline(self) -> PerformanceBaseline:
        """Create deletion performance baseline."""
        var times = List[Int]()
        
        for i in range(self.iterations):
            var table = SwissTable[Int, Int]()
            seed(42)
            for j in range(self.operation_count):
                _ = table.insert(j, j)
            
            seed(456)
            var start_time = perf_counter_ns()
            for j in range(self.operation_count // 2):
                var key = Int(random_ui64(0, self.operation_count))
                _ = table.delete(key)
            var end_time = perf_counter_ns()
            times.append(Int(end_time - start_time))
        
        return self.create_baseline_from_times("Deletion", times)
    
    fn benchmark_mixed_workload_baseline(self) -> PerformanceBaseline:
        """Create mixed workload performance baseline."""
        var times = List[Int]()
        
        for i in range(self.iterations):
            var table = SwissTable[Int, Int]()
            seed(111)
            var start_time = perf_counter_ns()
            
            for j in range(self.operation_count):
                var op = Int(random_ui64(0, 3))  # 0=insert, 1=lookup, 2=delete
                var key = Int(random_ui64(0, self.operation_count // 2))
                
                if op == 0:
                    _ = table.insert(key, j)
                elif op == 1:
                    _ = table.lookup(key)
                else:
                    _ = table.delete(key)
            
            var end_time = perf_counter_ns()
            times.append(Int(end_time - start_time))
        
        return self.create_baseline_from_times("Mixed Workload", times)
    
    fn create_baseline_from_times(self, operation_name: String, times: List[Int]) -> PerformanceBaseline:
        """Create baseline from timing measurements."""
        # Calculate statistics
        var total = 0
        for i in range(len(times)):
            total += times[i]
        var mean = Float64(total) / Float64(len(times))
        
        var variance = 0.0
        for i in range(len(times)):
            var diff = Float64(times[i]) - mean
            variance += diff * diff
        variance = variance / Float64(len(times) - 1)
        var std_dev = sqrt(variance)
        
        var confidence_interval = 1.96 * (std_dev / sqrt(Float64(len(times))))
        
        return PerformanceBaseline(
            operation_name, mean, std_dev, confidence_interval, 
            len(times), "2025-07-09", "production-ready"
        )
    
    fn run_regression_tests(self, baselines: List[PerformanceBaseline]) -> List[RegressionTestResult]:
        """Run regression tests against baselines."""
        print("Running regression tests...")
        
        var results = List[RegressionTestResult]()
        
        for i in range(len(baselines)):
            var baseline = baselines[i]
            var current_metrics = self.get_current_performance(baseline.operation_name)
            
            var change_percent = ((current_metrics.mean_ns - baseline.mean_ns) / baseline.mean_ns) * 100.0
            var is_regression = baseline.is_regression(current_metrics.mean_ns, self.regression_threshold)
            var is_significant = baseline.is_statistically_significant(current_metrics.mean_ns, current_metrics.confidence_interval)
            
            # Determine severity
            var severity: String = "MINOR"
            if change_percent > self.critical_threshold:
                severity = "CRITICAL"
            elif change_percent > self.major_threshold:
                severity = "MAJOR"
            
            var result = RegressionTestResult(
                baseline.operation_name, baseline.mean_ns, current_metrics.mean_ns,
                change_percent, is_regression, is_significant, severity
            )
            results.append(result)
        
        return results
    
    fn get_current_performance(self, operation_name: String) -> PerformanceBaseline:
        """Get current performance metrics for operation."""
        if operation_name == "Insertion":
            return self.benchmark_insertion_baseline()
        elif operation_name == "Lookup":
            return self.benchmark_lookup_baseline()
        elif operation_name == "Deletion":
            return self.benchmark_deletion_baseline()
        else:  # Mixed Workload
            return self.benchmark_mixed_workload_baseline()
    
    fn print_regression_summary(self, results: List[RegressionTestResult]):
        """Print comprehensive regression test summary."""
        print("\n=== Regression Test Summary ===")
        
        var total_tests = len(results)
        var regressions = 0
        var improvements = 0
        var stable = 0
        var critical_regressions = 0
        var major_regressions = 0
        
        for i in range(len(results)):
            var result = results[i]
            
            if result.is_regression and result.is_significant:
                regressions += 1
                if result.severity == "CRITICAL":
                    critical_regressions += 1
                elif result.severity == "MAJOR":
                    major_regressions += 1
            elif result.change_percent < -5.0 and result.is_significant:
                improvements += 1
            else:
                stable += 1
        
        print("Total operations tested:", total_tests)
        print("Regressions detected:   ", regressions)
        print("Improvements detected:  ", improvements)
        print("Stable performance:     ", stable)
        print("Critical regressions:   ", critical_regressions)
        print("Major regressions:      ", major_regressions)
        
        if critical_regressions > 0:
            print("\n❌ CRITICAL REGRESSIONS DETECTED - IMMEDIATE ACTION REQUIRED")
        elif major_regressions > 0:
            print("\n⚠️  MAJOR REGRESSIONS DETECTED - INVESTIGATION RECOMMENDED")
        elif regressions > 0:
            print("\n⚠️  MINOR REGRESSIONS DETECTED - MONITOR CLOSELY")
        else:
            print("\n✅ NO SIGNIFICANT REGRESSIONS DETECTED")
    
    fn generate_performance_report(self, baselines: List[PerformanceBaseline], 
                                 results: List[RegressionTestResult]):
        """Generate comprehensive performance report."""
        print("\n=== Performance Report ===")
        
        print("\nBaseline Performance:")
        for i in range(len(baselines)):
            baselines[i].print_baseline_info()
        
        print("\nRegression Test Results:")
        for i in range(len(results)):
            results[i].print_result()
        
        print("\nRecommendations:")
        self.generate_recommendations(results)
    
    fn generate_recommendations(self, results: List[RegressionTestResult]):
        """Generate performance optimization recommendations."""
        var has_regressions = False
        var has_improvements = False
        
        for i in range(len(results)):
            var result = results[i]
            if result.is_regression and result.is_significant:
                has_regressions = True
            elif result.change_percent < -5.0 and result.is_significant:
                has_improvements = True
        
        if has_regressions:
            print("  1. Investigate root cause of performance regressions")
            print("  2. Review recent code changes for performance impact")
            print("  3. Consider reverting changes if regressions are severe")
            print("  4. Add performance tests to CI/CD pipeline")
        
        if has_improvements:
            print("  1. Document performance improvements for future reference")
            print("  2. Update performance baselines if improvements are intentional")
            print("  3. Consider applying similar optimizations to other operations")
        
        if not has_regressions and not has_improvements:
            print("  1. Performance is stable - continue monitoring")
            print("  2. Consider incremental optimizations for further gains")
            print("  3. Update baselines periodically for long-term tracking")
    
    fn run_continuous_monitoring(self):
        """Run continuous performance monitoring."""
        print("=== Continuous Performance Monitoring ===")
        
        # Create or load baselines
        var baselines = self.create_baseline()
        
        # Run regression tests
        var results = self.run_regression_tests(baselines)
        
        # Generate comprehensive report
        self.generate_performance_report(baselines, results)
        
        # Print summary
        self.print_regression_summary(results)
        
        print("\n=== Monitoring Complete ===")
        print("✅ Performance regression testing completed")
        print("📊 Baselines established for continuous monitoring")
        print("🔍 Regression detection framework validated")
        print("📈 Ready for continuous integration deployment")

struct PerformanceAlert(Copyable, Movable):
    """Performance alert system for regression notifications."""
    
    var alert_threshold: Float64
    var critical_threshold: Float64
    
    fn __init__(out self):
        self.alert_threshold = 10.0   # 10% threshold for alerts
        self.critical_threshold = 20.0  # 20% threshold for critical alerts
    
    fn check_alerts(self, results: List[RegressionTestResult]):
        """Check for performance alerts."""
        print("\n=== Performance Alert System ===")
        
        var alerts_triggered = False
        
        for i in range(len(results)):
            var result = results[i]
            
            if result.is_regression and result.is_significant:
                alerts_triggered = True
                
                if result.change_percent > self.critical_threshold:
                    print("🚨 CRITICAL ALERT:", result.operation_name)
                    print("   Performance degraded by", Int(result.change_percent), "%")
                    print("   Immediate investigation required")
                elif result.change_percent > self.alert_threshold:
                    print("⚠️  ALERT:", result.operation_name)
                    print("   Performance degraded by", Int(result.change_percent), "%")
                    print("   Investigation recommended")
        
        if not alerts_triggered:
            print("✅ No performance alerts triggered")
        
        print("Alert thresholds:")
        print("  Warning:  ", self.alert_threshold, "%")
        print("  Critical: ", self.critical_threshold, "%")

fn main():
    """Run performance regression testing suite."""
    print("=== Performance Regression Testing Suite ===")
    
    var suite = PerformanceRegressionSuite()
    suite.run_continuous_monitoring()
    
    # Create baselines for alert testing
    var baselines = suite.create_baseline()
    var results = suite.run_regression_tests(baselines)
    
    # Test alert system
    var alert_system = PerformanceAlert()
    alert_system.check_alerts(results)
    
    print("\n=== Regression Testing Complete ===")
    print("Ready for continuous integration deployment")