# swiss-mojo

[![Mojo](https://img.shields.io/badge/mojo-🔥-red.svg)](https://modular.com/mojo)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Version](https://img.shields.io/badge/version-0.2.0-green.svg)](https://github.com/nijaru/swiss-mojo/releases)
[![Tests](https://img.shields.io/badge/tests-passing-brightgreen.svg)](#testing)

High-performance Swiss table hash map implementation for Mojo, optimized for maximum speed. Built on Google's proven SwissTable design with specialized type implementations for exceptional performance.

✅ **Status**: **Release v0.1.0** - Production ready with bulk operations, comprehensive test coverage, and specialized optimizations.

## Overview

`swiss-mojo` provides high-performance SwissTable implementations with specialized optimizations:

- **Generic SwissTable**: 1.16x faster insertions, 2.38x faster lookups vs stdlib Dict
- **Specialized implementations**: Up to 147% additional speedup for common type combinations
- **Bulk operations**: 15-30% throughput improvement for batch processing (16+ items)
- **Production tested**: Unified triangular probe sequence from proven algorithms
- **Maximum performance**: Evidence-based optimizations with systematic testing
- **Dict-compatible API**: `table[key]`, `keys()`, `values()`, `items()`, `update()` with zero performance cost
- **Enhanced API**: `insert()`, `lookup()`, `delete()`, `get()`, `contains()`, `pop()`, `reserve()`

Based on production-tested algorithms from:
- **Rust standard library** (via [hashbrown])
- **Google's Abseil C++ library** (original implementation)  
- **Go 1.24+** (new built-in map implementation)

[SwissTable]: https://abseil.io/about/design/swisstables
[hashbrown]: https://github.com/rust-lang/hashbrown

## Performance Results

**SwissTable delivers production-validated performance improvements:**

### Generic SwissTable vs stdlib Dict

| **Operation** | **SwissTable** | **stdlib Dict** | **Speedup** |
|---------------|----------------|-----------------|-------------|
| **Insertions** | 68.3M ops/sec | 58.7M ops/sec | **1.16x faster** ✅ |
| **Lookups** | 857.6M ops/sec | 361.0M ops/sec | **2.38x faster** ✅ |

### Specialized Implementations vs Generic SwissTable

| **Implementation** | **Use Case** | **Additional Speedup** | **Total vs Dict** |
|-------------------|--------------|------------------------|-------------------|
| **FastStringIntTable** | String→Int mappings | **+5.4%** | **1.22x faster** ✅ |
| **FastIntIntTable** | Int→Int counters | **+11%** | **1.29x faster** ✅ |  
| **FastStringStringTable** | String→String configs | **+147%** | **2.87x faster** ✅ |

### Bulk Operations Performance

| **Operation** | **Individual** | **Bulk (16+ items)** | **Improvement** |
|---------------|----------------|----------------------|-----------------|
| **Insert Operations** | Standard speed | Optimized batch processing | **15-30% faster** ✅ |
| **Lookup Operations** | Standard speed | Batch query processing | **15-30% faster** ✅ |
| **Contains Checks** | Standard speed | Fast bulk verification | **15-30% faster** ✅ |

**Key insights:**
- **Baseline performance**: 16% faster insertions, 138% faster lookups than stdlib Dict
- **Specialization wins**: Eliminating generic overhead provides 5-147% additional speedup
- **Bulk operations**: 15-30% throughput improvement for batch processing (16+ items)
- **Evidence-based**: All optimizations systematically tested and validated
- **Production ready**: 1000 keys × 500 iterations benchmark with 100% correctness

*Results from production workload simulation: 1000 keys, 500 iterations, Apple Silicon M-series.*

## Quick Start

### SwissTable - Maximum Performance

```mojo
from swisstable import SwissTable, MojoHashFunction

fn main() raises:
    # Easy creation with hash function
    var table = SwissTable[String, Int](MojoHashFunction())
    
    # Core operations for maximum speed
    _ = table.insert("hello", 42)
    _ = table.insert("world", 100)
    
    var value = table.lookup("hello")
    if value:
        print("Found:", value.value())  # Found: 42
    
    var deleted = table.delete("hello")
    print("Deleted:", deleted)  # Deleted: True
    
    # Enhanced API methods
    print("Contains 'world':", table.contains("world"))  # True
    print("Get with default:", table.get("missing", -1))  # -1
    print("Length:", len(table))  # 1
    print("Is non-empty:", bool(table))  # True
    
    # Dict API compatibility
    table["new_key"] = 200  # Same as insert()
    var value = table["new_key"]  # Same as lookup()
    if "new_key" in table:  # Same as contains()
        print("Key exists!")
    
    # Capacity management
    table.reserve(1000)  # Pre-allocate for performance
```

### Specialized Tables - Maximum Performance

For common type combinations, use specialized implementations for additional speedup:

```mojo
from swisstable import FastStringIntTable, FastIntIntTable, FastStringStringTable

fn main():
    # String->Int mapping (5.4% faster than generic)
    var string_to_int = FastStringIntTable()
    _ = string_to_int.insert("count", 42)
    _ = string_to_int.insert("total", 1000)
    
    # Int->Int mapping (11% faster than generic) 
    var int_to_int = FastIntIntTable()
    _ = int_to_int.insert(123, 456)
    _ = int_to_int.insert(789, 999)
    
    # String->String mapping (147% faster than generic!)
    var config = FastStringStringTable() 
    _ = config.insert("host", "localhost")
    _ = config.insert("port", "8080")
    _ = config.insert("protocol", "https")
    
    # All specialized tables have the same API as generic SwissTable
    var host = config.lookup("host")  # Returns Optional[String]
    var count = string_to_int.get("count", -1)  # Returns Int
    print("Host:", host.value() if host else "unknown")
    print("Count:", count)
```

**When to use specialized tables:**
- **FastStringIntTable**: Counters, indexes, mappings with string keys
- **FastIntIntTable**: Numeric mappings, ID tables, mathematical operations  
- **FastStringStringTable**: Configuration, translations, metadata storage

### Bulk Operations - High-Throughput Processing

For maximum throughput when processing large datasets, use bulk operations:

```mojo
from swisstable import SwissTable, MojoHashFunction
from collections import List

fn main():
    var table = SwissTable[String, Int](MojoHashFunction())
    
    # Prepare bulk data
    var keys = List[String]()
    var values = List[Int]()
    for i in range(1000):
        keys.append("item_" + String(i))
        values.append(i * 10)
    
    # Bulk insert - 15-30% faster than individual operations for 16+ items
    var results = table.bulk_insert(keys, values)
    print("Inserted:", len([r for r in results if r]), "items")
    
    # Bulk lookup for batch queries
    var lookup_keys = List[String]()
    lookup_keys.append("item_100")
    lookup_keys.append("item_500")
    lookup_keys.append("missing_key")
    
    var lookup_results = table.bulk_lookup(lookup_keys)
    for i in range(len(lookup_results)):
        if lookup_results[i]:
            print("Found:", lookup_keys[i], "->", lookup_results[i].value())
    
    # Fast bulk operations for maximum speed (no detailed results)
    table.bulk_insert_fast(keys, values)  # Ultra-fast insertion
    var found_count = table.bulk_contains_fast(lookup_keys)  # Fast existence check
    print("Found", found_count, "out of", len(lookup_keys), "keys")
    
    # Bulk update from another table
    var source_table = SwissTable[String, Int](MojoHashFunction())
    _ = source_table.insert("new_key", 999)
    table.bulk_update(source_table)  # Merge all entries
```

**Bulk operations performance:**
- **15-30% throughput improvement** for batch sizes 16+ items
- **Optimized memory access** patterns for large datasets
- **Reduced overhead** through batch processing
- **Production validated** with comprehensive benchmarks

## Installation

### Method 1: Download Pre-built Package (Recommended)

**One-line installation:**
```bash
curl -L https://github.com/nijaru/swiss-mojo/releases/latest/download/swiss-table.mojopkg -o swiss-table.mojopkg
```

**Or use our install script:**
```bash
curl -L https://raw.githubusercontent.com/nijaru/swiss-mojo/main/scripts/install.sh | bash
```

### Method 2: Build from Source

1. **Clone and build:**
   ```bash
   git clone https://github.com/nijaru/swiss-mojo.git
   cd swiss-mojo
   pixi install
   pixi run mojo package swisstable -o swiss-table.mojopkg
   ```

### Usage in Your Project

**Place the package in your project:**
```bash
# Copy to your project directory
cp swiss-table.mojopkg /path/to/your/project/
```

**Import and use:**
```mojo
from swisstable import SwissTable

var table = SwissTable[String, Int]()  # Easy creation with defaults!
_ = table.insert("hello", 42)
var result = table.lookup("hello")
if result:
    print("Found:", result.value())  # Found: 42
```

**Run your project:**
```bash
mojo run -I . your_app.mojo
```

### Package Information
- **Package size**: ~2.5MB
- **Mojo version**: Compatible with Mojo 24.5+
- **Platforms**: macOS (Apple Silicon), Linux (x64, ARM64)

## Key Features
- **Maximum performance** - 1.16x faster insertions, 2.38x faster lookups (production validated)
- **Bulk operations** - 15-30% throughput improvement for batch processing (16+ items)
- **Specialized tables** - Up to 147% additional speedup for common type combinations
- **Dict-compatible API** - `table[key]`, `keys()`, `values()`, `items()`, `update()` syntax (see compatibility notes)
- **Streamlined API** - `insert()`, `lookup()`, `delete()`, `get()`, `contains()`, `pop()`, `reserve()`
- **Iterator support** - Full `keys()`, `values()`, `items()` iteration with proper Mojo iterator protocol
- **Python-like helpers** - `len(table)`, `bool(table)` for familiar usage patterns
- **Custom hash functions** - Trait-based design with `MojoHashFunction`
- **Memory efficient** - 7/8 load factor, cache-friendly layout
- **Production tested** - Based on hashbrown's proven algorithms

## Documentation

- **[Migration Guide](docs/migration-from-dict.md)** - Complete guide for migrating from stdlib Dict
- **[Performance Guide](docs/performance-guide.md)** - Optimization techniques and thread safety
- **[Examples](examples/)** - Practical usage examples and patterns
- **[CHANGELOG](CHANGELOG.md)** - Version history and release notes
- **[Contributing](CONTRIBUTING.md)** - Development and contribution guidelines

## Testing

Run the test suite to verify functionality:

```bash
# Basic functionality tests
pixi run test-basic

# Edge cases and memory safety
pixi run test-edge
pixi run test-memory
pixi run test-stress

# Bulk operations testing
pixi run test-bulk

# v0.2.0 comprehensive testing
pixi run mojo run -I . test/test_comprehensive_v02.mojo
pixi run mojo run -I . test/benchmark_simple_v02.mojo

# Performance benchmarks
pixi run benchmark

# Python bindings demo (proof of concept)
pixi run demo-python-concept
```

## Architecture

### Algorithm Design
SwissTable uses the following core algorithms:
- **Triangular probe sequence** - Mathematical guarantee to visit all slots
- **Unified operations** - Same algorithm for insert/lookup/delete
- **Cache-friendly layout** - Optimized memory access patterns
- **SIMD-compatible** - Efficient metadata scanning

### Memory Layout
```
[control_bytes][padding][slots]
```
- **Control bytes**: 1-byte metadata per slot (empty=255, deleted=128, full=0-127)
- **Padding**: For SIMD safety and cache alignment
- **Slots**: Key-value pairs in flat array

## Usage Guidelines

### When to Use SwissTable
- **Performance critical** - Maximum speed is priority (1.23x faster insertions, 2.82x faster lookups)
- **High-throughput applications** - Need fastest possible hash table operations
- **Dict-like usage** - Want familiar `table[key]`, `key in table` syntax with zero performance cost
- **Memory efficiency** - Want optimal memory usage with 7/8 load factor
- **Custom hash functions** - Need control over hashing strategy

### When to Use stdlib Dict
- **Insertion order required** - Need to maintain insertion order 
- **Deterministic iteration** - Code depends on predictable `keys()`, `values()`, `items()` order
- **Legacy compatibility** - Code requires exact Dict behavior including popitem()

## Advanced Usage

### Dict-Compatible API

SwissTable provides **Dict-compatible syntax** with important differences:

**✅ Compatible:**
- `table[key]` get/set operations
- `key in table` membership testing  
- `len(table)`, `bool(table)` helpers
- `get()`, `pop()`, `setdefault()`, `update()` methods

**⚠️  Different behavior:**
- **No insertion order** - `keys()`, `values()`, `items()` return arbitrary order
- **No popitem()** - Method removed to avoid confusion with Dict's LIFO behavior
- **Different performance** - Faster but different algorithmic characteristics

```mojo
from swisstable import SwissTable

fn main() raises:
    var table = SwissTable[String, Int]()  # Easy creation!
    
    # Dict-style operations
    table["hello"] = 42        # Same as table.insert("hello", 42)
    var value = table["hello"] # Same as table.lookup("hello").value()
    
    if "hello" in table:       # Same as table.contains("hello")
        print("Found!")
    
    # Dict methods
    var default_val = table.setdefault("new_key", 100)
    print("Value:", default_val)  # 100
    
    # Iterator support
    var keys_iter = table.keys()
    for i in range(len(keys_iter)):
        try:
            var key = keys_iter.__next__()
            print("Key:", key)
        except:
            break
    
    # Update with another table
    var other_table = SwissTable[String, Int]()
    other_table["extra"] = 999
    table.update(other_table)
```

**Dict-Compatible API Methods:**
- **`table[key]`** - Get item with KeyError on missing key
- **`table[key] = value`** - Set item  
- **`key in table`** - Check key existence
- **`setdefault(key, default)`** - Get or set default value
- **`keys()`** - Iterator over keys (⚠️ arbitrary order, not insertion order)
- **`values()`** - Iterator over values (⚠️ arbitrary order, not insertion order)  
- **`items()`** - Iterator over key-value pairs (⚠️ arbitrary order, not insertion order)
- **`update(other)`** - Update with another table
- **`fromkeys(keys, default)`** - Create table from key list with default values
- **`len(table)`** - Get table size
- **`bool(table)`** - Check if non-empty

**Performance Results (Dict API vs Direct API):**
- **`table[key]`**: 102% performance (slightly faster than `lookup()`)
- **`table[key] = value`**: 115% performance (faster than `insert()`)
- **`key in table`**: 100% performance (identical to `contains()`)
- **`setdefault()`**: 99% performance (optimized single-pass implementation)
- **Iterators**: Zero-cost abstractions over direct slot access

### Custom Hash Functions

```mojo
from swisstable import SwissTable, HashFunction

struct MyHashFunction(HashFunction):
    fn hash(self, key: String) -> UInt64:
        # Custom hash implementation
        return UInt64(hash(key) * 31)

fn main() raises:
    var hasher = MyHashFunction()
    var table = SwissTable[String, Int](hasher)  # Use custom hasher
    table["custom"] = 42  # Works with Dict API too
    
    # Or use convenience function for built-in hash function
    var simple_table = create_table[String, Int]()  # Uses MojoHashFunction
```

### Performance Optimization

```mojo
from swisstable import SwissTable, MojoHashFunction

# Pre-allocate capacity for known size
var table = SwissTable[String, Int](1000)  # Easy creation with capacity

# Bulk insertions (both APIs work)
for i in range(1000):
    table["key_" + String(i)] = i  # Dict API
    # Or: _ = table.insert("key_" + String(i), i)  # Direct API

# Create from key list
var keys = List[String]()
keys.append("a")
keys.append("b")  
keys.append("c")
var from_keys = SwissTable[String, Int].fromkeys(keys, 0, MojoHashFunction())
```

## Performance Characteristics

### SwissTable Performance
- **1.23x faster insertions** - Optimized unified algorithm for maximum speed
- **2.82x faster lookups** - Triangular probe sequence with efficient scanning
- **Zero-cost Dict API** - Dict-style operations with no performance penalty
- **Cache-friendly** - Metadata locality for better cache usage
- **Memory efficient** - 7/8 load factor vs Dict's 2/3
- **Minimal overhead** - Streamlined operations without compatibility layers
- **Production validated** - 100% correctness with consistent performance improvements

## Safety Features

### Memory Safety
- **Reference stability** - Safe references during resize operations
- **Resource management** - Proper cleanup of allocated memory
- **Bounds checking** - Safe access to internal structures

### Iterator Safety
- **Generation tracking** - Detect modifications during iteration
- **Invalid iterator handling** - Graceful failure without crashes
- **Thread-safe patterns** - Read-only access supports concurrent use

## Testing

```bash
# Run basic tests
pixi run test-basic

# Run comprehensive tests
pixi run test-comprehensive

# Run performance benchmarks
pixi run benchmark
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## Acknowledgments

- **Google Abseil team** - Original SwissTable design
- **Rust hashbrown team** - Production-tested algorithms
- **Go team** - Swiss table implementation patterns
- **Mojo team** - Systems programming capabilities and SIMD support