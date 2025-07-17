# SwissTable Troubleshooting Guide

Common issues and solutions when using SwissTable.

## Installation Issues

### Package Import Errors

**Problem**: `error: unable to import 'swisstable'`

**Solutions**:
1. Ensure the package is in your module path
2. Use `-I .` flag when running: `mojo run -I . your_file.mojo`
3. Install the package properly: `mojo install swiss-table.mojopkg`

### Version Compatibility

**Problem**: `error: incompatible Mojo version`

**Solution**: Ensure you're using Mojo nightly or version >= 24.5

## Performance Issues

### Slower Than Expected Performance

**Problem**: SwissTable performing worse than Dict

**Common Causes**:
1. **Small datasets**: SwissTable optimizes for larger datasets (100+ elements)
2. **Poor hash distribution**: Using a hash function with many collisions
3. **Frequent resizing**: Not using `reserve()` for known sizes

**Solutions**:
```mojo
# Pre-allocate capacity
var table = create_table[String, Int]()
table.reserve(10000)  # If you know approximate size

# Use specialized tables for better performance
var fast_table = FastStringIntTable()  # For String->Int mappings
```

### Memory Usage Higher Than Expected

**Problem**: SwissTable using more memory than anticipated

**Explanation**: SwissTable trades memory for speed with 87.5% load factor vs Dict's 66.7%

**Solutions**:
1. Use `clear()` when tables are no longer needed
2. Consider Dict if memory is more critical than speed
3. Monitor capacity with `capacity()` method

## Runtime Errors

### KeyError on Access

**Problem**: `KeyError: key not found`

**Cause**: Using `table[key]` on non-existent key

**Solution**: Use safe lookup methods:
```mojo
# Instead of this (can raise):
var value = table["might_not_exist"]

# Use this (returns Optional):
var result = table.lookup("might_not_exist")
if result:
    var value = result.value()
else:
    # Handle missing key
```

### Iteration Invalidation

**Problem**: Crash or incorrect behavior when iterating

**Cause**: Modifying table while iterating

**Solution**: Collect modifications and apply after iteration:
```mojo
# Wrong:
for key in table.keys():
    table.delete(key)  # Don't modify during iteration!

# Correct:
var keys_to_delete = List[String]()
for key in table.keys():
    keys_to_delete.append(key)

for key in keys_to_delete:
    _ = table.delete(key)
```

## Compilation Errors

### Trait Constraint Errors

**Problem**: `KeyElement trait not satisfied`

**Solution**: Ensure your key type implements required traits:
```mojo
# Key types must be Hashable, Movable, EqualityComparable
# Built-in types (String, Int) work automatically
# Custom types need trait implementation
```

### Generic Type Errors

**Problem**: `cannot infer type parameters`

**Solution**: Explicitly specify types:
```mojo
# Instead of:
var table = SwissTable(MojoHashFunction())

# Use:
var table = SwissTable[String, Int, MojoHashFunction](MojoHashFunction())
# Or use convenience function:
var table = create_table[String, Int]()
```

## Thread Safety Issues

### Concurrent Access Crashes

**Problem**: Crashes or data corruption with multiple threads

**Cause**: SwissTable is not thread-safe

**Solution**: Add external synchronization:
```mojo
# Use mutex or other synchronization
# See examples/thread_safe_wrapper.mojo
```

## Debug Strategies

### Enable Assertions
```mojo
# Run with debug assertions (when available)
mojo run --debug your_file.mojo
```

### Check Table State
```mojo
# Debug helpers
print("Size:", table.size())
print("Capacity:", table.capacity())
print("Load factor:", Float64(table.size()) / Float64(table.capacity()))
print("Is empty:", table.is_empty())
```

### Verify Hash Function
```mojo
# Test hash distribution
var hasher = MojoHashFunction()
for i in range(10):
    var key = "test_" + String(i)
    print(key, "->", hasher.hash(key))
```

## Common Mistakes

### Using Wrong Table Type
- Use `FastStringIntTable` for String->Int mappings
- Use `FastIntIntTable` for Int->Int mappings
- Use generic `SwissTable` for other types

### Not Handling Optional Returns
- `lookup()` returns `Optional[V]`, not `V`
- Always check if value exists before using

### Forgetting Capacity Planning
- Use `reserve()` when size is known
- Prevents multiple resizes during insertion

## Getting Help

1. Check examples in `examples/` directory
2. Review API documentation in source code
3. Run tests to see usage patterns
4. File issues on GitHub with minimal reproducible examples

## Performance Profiling

To identify bottlenecks:
```mojo
from time import perf_counter_ns

var start = perf_counter_ns()
# Your operation here
var end = perf_counter_ns()
print("Operation took:", Float64(end - start) / 1e6, "ms")
```

Monitor:
- Insertion time
- Lookup time  
- Resize frequency
- Memory usage patterns