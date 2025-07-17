# SwissTable Examples

This directory contains practical examples demonstrating SwissTable usage patterns and best practices.

## Running Examples

All examples can be run using pixi:

```bash
# Basic usage patterns
pixi run mojo run -I . examples/basic_usage.mojo

# Performance optimization techniques  
pixi run mojo run -I . examples/performance_optimization.mojo

# Custom hash function implementation
pixi run mojo run -I . examples/custom_hash_functions.mojo

# Migration from stdlib Dict
pixi run mojo run -I . examples/migration_from_dict.mojo
```

## Example Categories

### 1. **basic_usage.mojo**
Demonstrates fundamental SwissTable operations:
- Construction and basic operations
- Insertion, lookup, deletion
- Enhanced API methods (`get`, `contains`, `pop`)
- Capacity management with `reserve()`
- Error handling with Optional types

### 2. **performance_optimization.mojo** 
Performance optimization techniques:
- Capacity pre-allocation
- Bulk operations
- Hash function selection
- Memory usage patterns
- Benchmarking your workload

### 3. **custom_hash_functions.mojo**
Custom hash function implementation:
- Creating custom hash functions
- Hash quality validation
- Performance trade-offs
- Domain-specific optimizations

### 4. **migration_from_dict.mojo**
Migration from stdlib Dict:
- Side-by-side API comparison
- Performance measurement
- Common migration patterns
- Handling missing features

## Performance Expectations

Based on statistical validation, expect these improvements over stdlib Dict:

| **Table Size** | **Insertion Speedup** | **Lookup Speedup** |
|----------------|----------------------|-------------------|
| 10 keys        | 2.47x (CI: 1.96x-3.25x) | Not significant |
| 100 keys       | 5.02x (CI: 4.76x-5.29x) | 1.15x (CI: 1.07x-1.23x) |
| 500 keys       | 1.90x (CI: 1.83x-1.98x) | 1.08x (CI: 1.06x-1.11x) |
| 1000 keys      | 1.56x (CI: 1.53x-1.60x) | 1.10x (CI: 1.08x-1.11x) |

## Best Practices Demonstrated

### Performance Optimization
- **Pre-allocate capacity**: Use `reserve()` for known table sizes
- **Choose appropriate hash functions**: DefaultHashFunction vs SimpleHashFunction
- **Bulk operations**: Minimize resizes during large insertions
- **Benchmark your workload**: Measure actual performance improvements

### Memory Management
- **Proper cleanup**: SwissTable handles memory automatically
- **Capacity planning**: Reserve capacity to avoid resize overhead
- **Load factor optimization**: Table automatically maintains 7/8 load factor

### Error Handling
- **Optional handling**: Always check Optional return values
- **Default values**: Use `get()` and `pop()` with defaults
- **Graceful degradation**: Handle missing keys appropriately

### API Usage
- **Type safety**: Leverage Mojo's type system
- **Method selection**: Choose appropriate methods for your use case
- **Performance monitoring**: Track performance improvements

## Integration Patterns

### Cache Implementation
```mojo
var cache = SwissTable[String, ExpensiveResult](DefaultHashFunction())
cache.reserve(expected_size)  # Pre-allocate

fn get_or_compute(key: String) -> ExpensiveResult:
    var cached = cache.lookup(key)
    if cached:
        return cached.value()
    else:
        var result = expensive_computation(key)
        _ = cache.insert(key, result)
        return result
```

### Configuration Storage
```mojo
var config = SwissTable[String, String](DefaultHashFunction())

fn load_config(filename: String):
    # Load configuration with defaults
    _ = config.insert("max_threads", "8")
    _ = config.insert("timeout_ms", "5000")
    # ... load from file

fn get_config(key: String, default: String) -> String:
    return config.get(key, default)
```

### Performance-Critical Lookup Tables
```mojo
var lookup_table = SwissTable[Int32, ProcessedData](DefaultHashFunction())
lookup_table.reserve(expected_data_size)

# Bulk population for maximum performance
for data in raw_data:
    _ = lookup_table.insert(data.id, process(data))

# Fast lookups in hot path  
fn fast_lookup(id: Int32) -> Optional[ProcessedData]:
    return lookup_table.lookup(id)  # 1.08x-1.15x faster than Dict
```

## Troubleshooting

### Common Issues

1. **Optional not checked**: Always check Optional return values
2. **Capacity not reserved**: Pre-allocate for bulk operations
3. **Wrong hash function**: Choose appropriate hash function for keys
4. **Thread safety**: SwissTable is not thread-safe, use external synchronization

### Performance Issues

1. **Measure first**: Use benchmarks to identify actual bottlenecks
2. **Scale matters**: Performance advantages vary by table size  
3. **Hash quality**: Poor hash functions can degrade performance
4. **Memory pressure**: Large keys can impact cache performance

See [Performance Guide](../docs/performance-guide.md) for detailed optimization techniques.

## Next Steps

After reviewing these examples:
1. Try the examples with your own data types
2. Benchmark SwissTable with your workload
3. Read the [Migration Guide](../docs/migration-from-dict.md) for Dict replacement
4. Check the [Performance Guide](../docs/performance-guide.md) for advanced optimization