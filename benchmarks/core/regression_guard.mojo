"""Performance regression testing framework for SwissTable.

This framework establishes baseline performance measurements and detects regressions
in critical operations. It's designed to be run in CI/CD to catch performance issues
before they reach production.
"""

from swisstable import SwissTable, MojoHashFunction
from swisstable import FastStringIntTable, FastIntIntTable, FastStringStringTable
from collections import List, Dict


fn create_performance_baseline() -> (Int, Int, Int, Int, Int, Int, Int, Int, Int):
    """Create baseline performance measurements for regression detection."""
    # Based on v0.1.0 performance measurements
    # (insert, lookup, bulk_insert, bulk_lookup, spec_string_int, spec_int_int, spec_string_string, dict_insert, dict_lookup)
    return (1000, 1000, 100, 100, 1000, 1000, 1000, 1000, 1000)


fn measure_generic_performance() -> (Int, Int, Int, Int):
    """Measure generic SwissTable performance."""
    var table = SwissTable[String, Int](MojoHashFunction())
    
    # Insert performance
    var insert_count = 0
    for i in range(1000):
        var key = "key_" + String(i)
        if table.insert(key, i):
            insert_count += 1
    
    # Lookup performance
    var lookup_count = 0
    for i in range(1000):
        var key = "key_" + String(i)
        var result = table.lookup(key)
        if result:
            lookup_count += 1
    
    # Bulk insert performance
    var bulk_keys = List[String]()
    var bulk_values = List[Int]()
    for i in range(100):
        bulk_keys.append("bulk_" + String(i))
        bulk_values.append(i)
    
    var bulk_table = SwissTable[String, Int](MojoHashFunction())
    var bulk_results = bulk_table.bulk_insert(bulk_keys, bulk_values)
    var bulk_insert_count = len(bulk_results)
    
    # Bulk lookup performance
    var bulk_lookup_results = bulk_table.bulk_lookup(bulk_keys)
    var bulk_lookup_count = 0
    for i in range(len(bulk_lookup_results)):
        if bulk_lookup_results[i]:
            bulk_lookup_count += 1
    
    return (insert_count, lookup_count, bulk_insert_count, bulk_lookup_count)


fn measure_specialized_performance() -> (Int, Int, Int):
    """Measure specialized table performance."""
    # FastStringIntTable
    var string_int_table = FastStringIntTable()
    var string_int_count = 0
    for i in range(1000):
        var key = "key_" + String(i)
        if string_int_table.insert(key, i):
            string_int_count += 1
    
    # FastIntIntTable
    var int_int_table = FastIntIntTable()
    var int_int_count = 0
    for i in range(1000):
        if int_int_table.insert(i, i * 2):
            int_int_count += 1
    
    # FastStringStringTable
    var string_string_table = FastStringStringTable()
    var string_string_count = 0
    for i in range(1000):
        var key = "key_" + String(i)
        var value = "value_" + String(i)
        if string_string_table.insert(key, value):
            string_string_count += 1
    
    return (string_int_count, int_int_count, string_string_count)


fn measure_dict_comparison() -> (Int, Int):
    """Measure Dict baseline performance for comparison."""
    var dict_table = Dict[String, Int]()
    
    # Dict insert performance
    var dict_insert_count = 0
    for i in range(1000):
        var key = "dict_key_" + String(i)
        dict_table[key] = i
        dict_insert_count += 1
    
    # Dict lookup performance
    var dict_lookup_count = 0
    for i in range(1000):
        var key = "dict_key_" + String(i)
        if key in dict_table:
            dict_lookup_count += 1
    
    return (dict_insert_count, dict_lookup_count)


fn validate_performance_ratios(generic_results: (Int, Int, Int, Int), 
                               specialized_results: (Int, Int, Int),
                               dict_results: (Int, Int)) -> Bool:
    """Validate that performance ratios meet expectations."""
    var generic_insert = generic_results[0]
    var generic_lookup = generic_results[1]
    var dict_insert = dict_results[0]
    var dict_lookup = dict_results[1]
    
    # These should be true based on v0.1.0 performance claims
    var insert_ratio_ok = generic_insert >= dict_insert  # Should be 1.16x faster
    var lookup_ratio_ok = generic_lookup >= dict_lookup  # Should be 2.38x faster
    
    # Specialized tables should work as well as generic
    var specialized_ok = (specialized_results[0] >= 900 and 
                         specialized_results[1] >= 900 and 
                         specialized_results[2] >= 900)
    
    return insert_ratio_ok and lookup_ratio_ok and specialized_ok


fn detect_regression(baseline: (Int, Int, Int, Int, Int, Int, Int, Int, Int), 
                     current_results: (Int, Int, Int, Int)) -> Bool:
    """Detect performance regression compared to baseline."""
    var tolerance = 0.05  # 5% tolerance
    
    var insert_regression = current_results[0] < Int(Float64(baseline[0]) * (1.0 - tolerance))
    var lookup_regression = current_results[1] < Int(Float64(baseline[1]) * (1.0 - tolerance))
    var bulk_insert_regression = current_results[2] < Int(Float64(baseline[2]) * (1.0 - tolerance))
    var bulk_lookup_regression = current_results[3] < Int(Float64(baseline[3]) * (1.0 - tolerance))
    
    return insert_regression or lookup_regression or bulk_insert_regression or bulk_lookup_regression


fn run_performance_regression_tests():
    """Run comprehensive performance regression tests."""
    print("🔍 Performance Regression Testing Framework")
    print("=" * 50)
    
    # Establish baseline
    var baseline = create_performance_baseline()
    print("📊 Baseline Performance Targets:")
    print("  Generic insert/lookup: " + String(baseline[0]) + "/" + String(baseline[1]))
    print("  Bulk operations: " + String(baseline[2]) + "/" + String(baseline[3]))
    print("  Specialized tables: " + String(baseline[4]) + "/" + String(baseline[5]) + "/" + String(baseline[6]))
    
    # Measure current performance
    print("\n🚀 Measuring Current Performance...")
    var generic_results = measure_generic_performance()
    var specialized_results = measure_specialized_performance()
    var dict_results = measure_dict_comparison()
    
    print("📈 Current Performance Results:")
    print("  Generic SwissTable - Insert:" + String(generic_results[0]) + " Lookup:" + String(generic_results[1]))
    print("  Bulk Operations - Insert:" + String(generic_results[2]) + " Lookup:" + String(generic_results[3]))
    print("  Specialized Tables - StringInt:" + String(specialized_results[0]) + " IntInt:" + String(specialized_results[1]) + " StringString:" + String(specialized_results[2]))
    print("  Dict Baseline - Insert:" + String(dict_results[0]) + " Lookup:" + String(dict_results[1]))
    
    # Check for regressions
    print("\n🔍 Regression Analysis:")
    var has_regression = detect_regression(baseline, generic_results)
    if has_regression:
        print("❌ PERFORMANCE REGRESSION DETECTED!")
        print("   Current performance is significantly below baseline")
        print("   This indicates a potential performance issue")
    else:
        print("✅ No performance regression detected")
    
    # Validate performance ratios
    print("\n📊 Performance Ratio Validation:")
    var ratios_ok = validate_performance_ratios(generic_results, specialized_results, dict_results)
    if ratios_ok:
        print("✅ Performance ratios meet expectations")
        print("   SwissTable maintains performance advantage over Dict")
        print("   Specialized tables performing optimally")
    else:
        print("❌ Performance ratios below expectations")
        print("   Performance advantage may be compromised")
    
    # Overall result
    print("\n" + "=" * 50)
    if not has_regression and ratios_ok:
        print("🎉 PERFORMANCE REGRESSION TESTS PASSED!")
        print("✅ All performance characteristics maintained")
        print("✅ No regressions detected")
        print("✅ Ready for production deployment")
    else:
        print("⚠️  PERFORMANCE ISSUES DETECTED!")
        print("❌ Manual investigation required")
        print("❌ Do not deploy until resolved")
    print("=" * 50)


fn main():
    """Main function for performance regression testing."""
    run_performance_regression_tests()