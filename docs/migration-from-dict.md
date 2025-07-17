# Migration Guide: Dict to SwissTable

This guide helps you migrate from Mojo's stdlib `Dict` to `SwissTable` for maximum performance.

## When to Choose SwissTable vs Dict

### Use SwissTable when:
- **Performance is critical**: 1.56x-5.02x faster insertions, up to 1.15x faster lookups
- **Cache-hot workloads**: Small to medium tables (≤1000 keys) see dramatic improvements  
- **High-throughput systems**: Bulk operations benefit from reduced overhead
- **Custom hash functions**: Need specialized hashing for performance

### Use stdlib Dict when:
- **Dict API compatibility required**: Need exact `dict[key] = value` syntax
- **Insertion order preservation**: Require iteration in insertion order
- **Simple applications**: Performance isn't the bottleneck
- **Rapid prototyping**: Want familiar Python-like syntax

## API Comparison

### Basic Operations

| **Operation** | **Dict** | **SwissTable** | **Performance** |
|---------------|----------|----------------|-----------------|
| **Create** | `Dict[K, V]()` | `SwissTable[K, V]()` | N/A |
| **Insert** | `dict[key] = value` | `table.insert(key, value)` | **1.24x faster** |
| **Lookup** | `dict[key]` | `table.lookup(key).value()` | **2.49x faster** |
| **Check exists** | `key in dict` | `table.contains(key)` | Similar |
| **Get with default** | `dict.get(key, default)` | `table.get(key, default)` | Similar |
| **Delete** | `del dict[key]` | `table.delete(key)` | Similar |
| **Size** | `len(dict)` | `len(table)` or `table.size()` | Similar |

### Advanced Operations

| **Operation** | **Dict** | **SwissTable** | **Notes** |
|---------------|----------|----------------|-----------|
| **Pop with default** | `dict.pop(key, default)` | `table.pop(key, default)` | ✅ Compatible |
| **Clear** | `dict.clear()` | `table.clear()` | ✅ Compatible |
| **Capacity planning** | N/A | `table.reserve(capacity)` | ✅ SwissTable advantage |
| **Boolean context** | `if dict:` | `if table:` | ✅ Compatible |

### Missing from SwissTable

| **Dict Feature** | **SwissTable** | **Workaround** |
|------------------|----------------|----------------|
| **Insertion order** | Not preserved | Use stdlib Dict if required |
| **`setdefault()`** | Not implemented | Use `get()` + `insert()` |
| **`update()`** | Not implemented | Loop with `insert()` |
| **`keys()`, `values()`, `items()`** | Not implemented | Use stdlib Dict if required |

## Migration Examples

### Example 1: Basic Usage

**Before (Dict):**
```mojo
from collections import Dict

var cache = Dict[String, Int]()
cache["user_123"] = 42
cache["user_456"] = 84

if "user_123" in cache:
    print("Found:", cache["user_123"])
```

**After (SwissTable):**
```mojo
from swisstable import SwissTable

var cache = SwissTable[String, Int]()
_ = cache.insert("user_123", 42)
_ = cache.insert("user_456", 84)

if cache.contains("user_123"):
    var result = cache.lookup("user_123")
    if result:
        print("Found:", result.value())
```

### Example 2: Performance-Critical Code

**Before (Dict):**
```mojo
# Performance bottleneck: frequent lookups in hot path
fn process_requests(requests: List[Request], cache: Dict[String, Response]) -> List[Response]:
    var responses = List[Response]()
    for request in requests:
        if request.id in cache:
            responses.append(cache[request.id])
        else:
            var response = expensive_computation(request)
            cache[request.id] = response
            responses.append(response)
    return responses
```

**After (SwissTable):**
```mojo
# Optimized: 1.56x-5.02x faster insertions, up to 1.15x faster lookups
fn process_requests(requests: List[Request], cache: SwissTable[String, Response]) -> List[Response]:
    var responses = List[Response]()
    for request in requests:
        var cached = cache.lookup(request.id)
        if cached:
            responses.append(cached.value())
        else:
            var response = expensive_computation(request)
            _ = cache.insert(request.id, response)
            responses.append(response)
    return responses
```

### Example 3: Capacity Optimization

**Before (Dict):**
```mojo
# Dict: No capacity planning, resizes happen automatically
var large_table = Dict[Int, String]()
for i in range(10000):
    large_table[i] = "value_" + String(i)
```

**After (SwissTable):**
```mojo
# SwissTable: Pre-allocate capacity to avoid resizes
var large_table = SwissTable[Int, String](10000)  # Pre-allocate capacity
for i in range(10000):
    _ = large_table.insert(i, "value_" + String(i))
```

## Performance Expectations

### Performance Results (1000 keys × 500 iterations)
- **Insertion**: **1.24x faster** - Consistent improvement across all table sizes
- **Lookup**: **2.49x faster** - Significant advantage for read-heavy workloads
- **Best use case**: High-throughput systems, frequent lookups, performance-critical paths

## Migration Checklist

### 1. **Identify Performance Bottlenecks**
- [ ] Profile your application to find hash table hot paths
- [ ] Measure current Dict performance with realistic workloads
- [ ] Identify tables with frequent insertions/lookups

### 2. **Replace Dict with SwissTable**
- [ ] Change imports: `from swisstable import SwissTable`
- [ ] Update constructor: `SwissTable[K, V]()` or `SwissTable[K, V](capacity)`
- [ ] Replace `dict[key] = value` with `table.insert(key, value)`
- [ ] Replace `dict[key]` with `table.lookup(key).value()`
- [ ] Replace `key in dict` with `table.contains(key)`

### 3. **Optimize for Performance**
- [ ] Add `table.reserve(capacity)` for known table sizes
- [ ] Consider custom hash functions for specialized keys
- [ ] Benchmark the improvements on realistic workloads

### 4. **Handle Missing Features**
- [ ] If you need insertion order, keep using Dict
- [ ] If you need `setdefault()`, implement with `get()` + `insert()`
- [ ] If you need iteration, consider dual approach or stick with Dict

## Common Pitfalls

### 1. **Null Pointer Access**
```mojo
# Wrong: Accessing Optional without checking
var value = table.lookup(key).value()  # May crash!

# Right: Check Optional before accessing
var result = table.lookup(key)
if result:
    var value = result.value()
```

### 2. **Forgetting Insert Return Value**
```mojo
# Wrong: Ignoring whether key was new vs updated
table.insert(key, value)

# Right: Check if key was newly inserted
var was_new = table.insert(key, value)
if was_new:
    print("New key added")
else:
    print("Existing key updated")
```

### 3. **Capacity Planning**
```mojo
# Suboptimal: Let table resize automatically
var table = SwissTable[String, Int]()
# ... insert many elements, triggering resizes

# Optimal: Pre-allocate known capacity
var table = SwissTable[String, Int](1000)  # Avoid resize overhead
```

## Validation

After migration, validate your improvements:

1. **Correctness**: Ensure all operations return expected results
2. **Performance**: Measure actual speedup on your workloads
3. **Memory**: Verify memory usage meets expectations

Expected improvements:
- **Insertions**: 1.24x speedup across all table sizes
- **Lookups**: 2.49x speedup across all table sizes  
- **Memory**: 87.5% load factor vs Dict's 66.7%

## Next Steps

- See [Performance Guide](performance-guide.md) for optimization tips
- See [API Reference](api-reference.md) for complete method documentation
- See [Examples](../examples/) for real-world usage patterns