# SwissTable Thread Safety Documentation

## Overview

The SwissTable implementation is **not thread-safe** and requires external synchronization for concurrent access. This document provides a comprehensive analysis of thread safety characteristics and safe usage patterns.

## Thread Safety Status

❌ **Not Thread-Safe**: The SwissTable implementation contains no internal synchronization mechanisms and is designed for single-threaded use or external synchronization.

## Mutable State Analysis

### Core Shared Data Structures

The SwissTable contains the following mutable state that poses concurrency risks:

- **`_capacity`**: Current table capacity (32-bit integer)
- **`_size`**: Number of elements (32-bit integer)  
- **`_growth_left`**: Available slots before resize (32-bit integer)
- **`_bucket_mask`**: Capacity-1 for fast modulo operations (32-bit integer)
- **`_control_bytes`**: Metadata array storing slot status (UnsafePointer[UInt8])
- **`_slots`**: Key-value data storage (UnsafePointer[DictEntry[K, V]])

### Critical Concurrency Risks

1. **Control Bytes Array**: Contains slot metadata (EMPTY=255, DELETED=128, FULL=0-127)
2. **Slots Array**: Actual key-value pair storage
3. **Size Counters**: Track table state and trigger resize operations
4. **Memory Reallocation**: Resize operations invalidate all pointers

## Operation Classification

### Thread-Safe Operations (Read-Only)
*Safe only if no concurrent modifications occur*

- `lookup(key)` - Read control bytes and slots
- `contains(key)` - Boolean existence check
- `get(key, default)` - Lookup with fallback
- `size()`, `capacity()`, `is_empty()` - Scalar field reads
- `keys()`, `values()`, `items()` - Read-only iteration
- `bulk_lookup()` - Batch read operations
- `bulk_contains_fast()` - Fast existence checks

### Thread-Unsafe Operations (Write Operations)
*Require exclusive access*

- `insert(key, value)` - Modifies control bytes, slots, and counters
- `delete(key)` - Updates control bytes and size counter
- `clear()` - Resets all control bytes and counters
- `setdefault(key, default)` - Conditional write operation
- `update(other)` - Bulk write operations
- `reserve(capacity)` - May trigger resize operation
- `pop(key, default)` - Compound read-write operation
- All bulk write operations (`bulk_insert`, `bulk_update`, `bulk_insert_fast`)

### Extremely Dangerous Operations
*Can cause memory corruption and crashes*

- `_resize()` - Reallocates entire table structure
- `_resize_to_capacity()` - Same risks as resize
- Automatic resize during insertion - Hidden danger for concurrent access

## Specific Concurrency Hazards

### Memory Safety Issues

1. **Iterator Invalidation**: Resize operations invalidate all iterators
2. **Dangling Pointers**: Iterators may access deallocated memory
3. **Use-After-Free**: Concurrent access during destruction

### Race Conditions

1. **Lost Updates**: Multiple threads modifying same slot
2. **Inconsistent Counters**: Size tracking corruption
3. **Control Byte Corruption**: Metadata inconsistency
4. **ABA Problems**: Slot reuse between operations

### Resize Hazards

1. **Memory Reallocation**: Invalidates all existing pointers
2. **Partial State**: Table in inconsistent state during resize
3. **Capacity Changes**: Affects all hash calculations

## Safe Concurrent Usage Patterns

### 1. External Synchronization (Recommended)

```mojo
# Thread-safe wrapper example
struct ThreadSafeSwissTable[K: KeyElement, V: Copyable & Movable]:
    var _table: SwissTable[K, V]
    var _mutex: Mutex  # External synchronization required
    
    fn lookup(self, key: K) -> Optional[V]:
        with self._mutex:
            return self._table.lookup(key)
    
    fn insert(inout self, key: K, value: V) -> Bool:
        with self._mutex:
            return self._table.insert(key, value)
```

### 2. Reader-Writer Lock Pattern

```mojo
# For read-heavy workloads
struct ReadWriteSwissTable[K: KeyElement, V: Copyable & Movable]:
    var _table: SwissTable[K, V]
    var _rw_lock: ReadWriteLock
    
    fn lookup(self, key: K) -> Optional[V]:
        with self._rw_lock.read():
            return self._table.lookup(key)
    
    fn insert(inout self, key: K, value: V) -> Bool:
        with self._rw_lock.write():
            return self._table.insert(key, value)
```

### 3. Immutable Usage Pattern

```mojo
# Build once, read many
fn safe_concurrent_usage():
    # Single-threaded construction
    var table = SwissTable[String, Int](MojoHashFunction())
    populate_table(table)
    
    # Multiple threads can safely read
    # No modifications allowed
    spawn_reader_threads(table)
```

### 4. Copy-on-Write Pattern

```mojo
# For infrequent updates
struct CowSwissTable[K: KeyElement, V: Copyable & Movable]:
    var _table: SwissTable[K, V]
    var _version: Atomic[Int]
    
    fn update(inout self, key: K, value: V):
        # Create new table for modifications
        var new_table = self._table.copy()
        _ = new_table.insert(key, value)
        
        # Atomic swap
        self._table = new_table
        self._version.increment()
```

## Performance Considerations

### Synchronization Overhead

- **Mutex per operation**: 50-100ns overhead per call
- **Reader-writer locks**: Lower overhead for read-heavy workloads
- **Atomic operations**: Minimal overhead but complex to implement

### Lock-Free Alternatives

Consider lock-free hash tables for high-concurrency scenarios:
- Much higher implementation complexity
- Requires careful memory ordering
- ABA problem prevention needed
- Memory reclamation challenges

## Migration Guide

### From Single-Threaded to Concurrent

1. **Audit existing code** for shared SwissTable instances
2. **Identify access patterns** (read-heavy vs write-heavy)
3. **Choose synchronization strategy** based on usage patterns
4. **Implement wrapper types** with appropriate locking
5. **Test thoroughly** under concurrent load

### Testing Concurrent Safety

```mojo
# Example stress test
fn test_concurrent_safety():
    var table = ThreadSafeSwissTable[String, Int]()
    
    # Spawn multiple reader threads
    for i in range(10):
        spawn_reader_thread(table)
    
    # Spawn writer threads
    for i in range(2):
        spawn_writer_thread(table)
    
    # Verify data integrity
    wait_for_completion()
    verify_table_consistency(table)
```

## Conclusion

The SwissTable implementation prioritizes performance over thread safety, making it unsuitable for concurrent access without external synchronization. Choose the appropriate synchronization strategy based on your specific usage patterns and performance requirements.

For high-concurrency scenarios, consider:
- Lock-free hash table implementations
- Thread-local storage with periodic synchronization
- Immutable data structures with functional updates

## References

- SwissTable implementation: `swisstable/swiss_table.mojo`
- Iterator safety: `swisstable/iterators.mojo`
- Data structures: `swisstable/data_structures.mojo`
- Hash functions: `swisstable/hash.mojo`