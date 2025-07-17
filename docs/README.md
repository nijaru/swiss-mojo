# Swiss Table Documentation

This directory contains documentation for the SwissTable implementation.

## User Documentation

- **[Migration Guide](migration-from-dict.md)** - Complete guide for migrating from stdlib Dict
- **[Performance Guide](performance-guide.md)** - Optimization techniques and performance characteristics
- **[Performance Analysis](performance_analysis.md)** - Detailed performance benchmarks and analysis

## Legal Documentation

- **[Attribution](legal/ATTRIBUTION.md)** - Acknowledgments and algorithm references
- **[Legal Notice](legal/NOTICE)** - Legal notices

## Quick Start

```mojo
from swisstable import SwissTable, DefaultHashFunction

fn main() raises:
    # Create a new SwissTable
    var table = SwissTable[String, Int](DefaultHashFunction())
    
    # Dict-compatible API
    table["hello"] = 42
    table["world"] = 100
    
    print(table["hello"])  # 42
    print("hello" in table)  # True
    print(len(table))  # 2
    
    # Enhanced API
    _ = table.insert("mojo", 2025)
    var value = table.lookup("mojo")
    if value:
        print("Found:", value.value())  # Found: 2025
```

## Performance

SwissTable delivers production-validated performance improvements:
- **1.17x faster insertions** than stdlib Dict
- **2.66x faster lookups** than stdlib Dict  
- **100% correctness** with comprehensive testing

See the [Performance Guide](performance-guide.md) for detailed benchmarks and optimization techniques.

## Algorithm References

This implementation draws inspiration from proven Swiss table designs:
- **[Abseil C++](https://github.com/abseil/abseil-cpp)**: Original Swiss table design with control bytes and SIMD optimization
- **[Hashbrown (Rust)](https://github.com/rust-lang/hashbrown)**: Production-quality implementation with proven algorithms
- **Mojo Dict**: Performance analysis and probe sequence optimization patterns

See [legal/ATTRIBUTION.md](legal/ATTRIBUTION.md) for detailed acknowledgments and algorithm references.