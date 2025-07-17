# CLAUDE.md - SwissTable Development Guide

This file provides guidance for Claude Code when working with the SwissTable project.

## Project Overview

**SwissTable** is a high-performance hash table implementation for Mojo that delivers **1.24x faster insertions** and **2.49x faster lookups** compared to stdlib Dict. It implements Google's proven Swiss table design with Mojo's systems programming capabilities.

## Repository Structure

```
swiss-table-mojo/
├── swisstable/              # Core implementation
│   ├── swiss_table.mojo     # Main SwissTable struct  
│   ├── hash.mojo           # Hash functions and utilities
│   ├── unified_ops.mojo    # Optimized operations
│   ├── data_structures.mojo # Entry and support types
│   └── iterators.mojo      # Iterator implementations
├── test/                   # Test suite
│   ├── benchmark.mojo      # Performance benchmarks
│   ├── test_edge_cases.mojo
│   ├── test_collisions.mojo
│   ├── test_memory_safety.mojo
│   └── test_stress.mojo
├── docs/                   # Documentation
│   ├── ROADMAP.md         # Strategic development plan
│   ├── migration-from-dict.md
│   └── performance-guide.md
└── examples/              # Usage examples
```

## Current Status (v0.1.0)

✅ **Production Ready**: Comprehensive testing, full Dict-compatible API  
✅ **Performance Validated**: 1.24x insertion, 2.49x lookup speedup  
✅ **Clean Architecture**: Single-commit release with quality documentation  
✅ **GitHub Release**: Live at https://github.com/nijaru/swiss-mojo/releases/tag/v0.1.0

## Development Environment

### Essential Commands

```bash
# Run tests
pixi run test-basic          # Edge cases
pixi run test-collisions     # Hash collision handling  
pixi run test-memory         # Memory safety
pixi run test-stress         # Large datasets
pixi run benchmark           # Performance validation

# Development
pixi run format              # Code formatting
mojo package swisstable -o swiss-table.mojopkg  # Build package
```

### Performance Baseline
- **Insertions**: 73.1M ops/sec (1.24x vs Dict)
- **Lookups**: 900.9M ops/sec (2.49x vs Dict)  
- **Memory**: 87.5% load factor (vs Dict's 66.7%)
- **Test**: 1000 keys × 500 iterations, 100% correctness

## Key Technical Patterns

### Algorithm Design
- **Unified triangular probe sequence** for all operations
- **Cache-friendly layout**: Control bytes separated from data
- **SIMD-compatible**: Parallel metadata scanning
- **7/8 load factor**: Optimized memory efficiency

### API Design Principles
- **Dict compatibility**: `table[key]`, `key in table`, etc.
- **Enhanced operations**: `insert()`, `lookup()`, `delete()` 
- **Convenience functions**: `create_table[K, V]()` for easy usage
- **Type safety**: Generic with trait constraints

### Performance Optimization
- **Small table fast path**: Linear search for < 16 elements
- **Unified operations**: Same algorithm for all table sizes  
- **Control byte optimization**: Efficient empty/deleted/full tracking
- **Memory layout**: Cache-efficient field ordering

## Strategic Roadmap (see docs/ROADMAP.md)

### Phase 1: Performance Enhancements (Target: 1.8x-2.2x speedup)
1. **Specialized Types**: FastStringIntTable, FastIntIntTable (eliminate generic overhead)
2. **Batch Operations**: Algorithmic improvements, not aggressive SIMD (our SIMD is already good)
3. **Memory Layout**: Cache optimization and prefetching
4. **Skip Thread Safety**: Evidence shows 10-30% performance penalty - focus on speed instead

### Phase 2: Python Ecosystem Expansion (Target: 2x+ vs Python dict)
1. **Market Opportunity**: Weak existing competition identified
2. **Implementation**: Use Modular's PythonModuleBuilder patterns
3. **Focus**: Bulk operations to amortize interop overhead
4. **Timeline**: Proof of concept within 4-6 weeks

## Development Guidelines

### Code Quality Standards
- **Performance First**: Every change must maintain or improve performance
- **Comprehensive Testing**: All modifications require test coverage
- **Documentation**: Update docs for API changes
- **Benchmarking**: Validate performance claims with data

### Commit Conventions
- Use conventional commits: `feat:`, `fix:`, `perf:`, `docs:`
- Include performance impact in commit messages when relevant
- Sign commits: `git commit -s` for CLA compliance
- Reference benchmark results for performance changes

### Release Process
1. Run full test suite and benchmarks
2. Update performance numbers in docs
3. Update CHANGELOG.md with new features
4. Create GitHub release with package asset
5. Verify installation instructions work

## Common Patterns

### Adding New Operations
```mojo
# 1. Add to SwissTable struct
fn new_operation(mut self, ...) -> ReturnType:
    # Implementation using unified_ops patterns

# 2. Add tests  
fn test_new_operation():
    var table = create_table[String, Int]()
    # Test cases...

# 3. Update benchmarks if performance-critical
# 4. Document in README if user-facing
```

### Performance Investigation
```bash
# Always benchmark before/after changes
pixi run benchmark > before.txt
# Make changes...
pixi run benchmark > after.txt
# Compare results and update documentation
```

### Adding Python Bindings (Phase 2)
```mojo
# Follow Modular patterns from private/modular/examples/
@export  
fn PyInit_swisstable() -> PythonObject:
    var module = PythonModuleBuilder("swisstable")
    module.def_function[operation]("operation")
    return module.finalize()
```

## Current Architecture Decisions

### Why These Choices Were Made
- **Single algorithm**: Simplified codebase, easier optimization
- **create_table() functions**: Clean API without Mojo generic limitations  
- **No popitem()**: Avoided confusion with Dict's LIFO behavior
- **MojoHashFunction**: Leverages Mojo's optimized built-in hash()
- **Unified probe sequence**: Consistent performance characteristics

### Future Considerations (Evidence-Based from Modular Repo Analysis)
- **Specialized types**: Worth implementing - eliminate generic overhead
- **Thread safety**: SKIP - evidence shows 10-30% performance penalty
- **Python bindings**: Large market opportunity with weak competition (confirmed)
- **SIMD optimization**: Our current SIMD is already good - focus on algorithms instead
- **Batch operations**: More effective than aggressive SIMD for performance gains

## Testing Philosophy

### Test Coverage Requirements
- **Edge cases**: Empty tables, single elements, capacity boundaries
- **Collision handling**: Pathological hash functions, collision chains
- **Memory safety**: Resource cleanup, iterator invalidation
- **Stress testing**: Large datasets, random patterns, heavy workloads
- **Performance**: Benchmark every release, validate claims

### Performance Testing
- Use realistic workloads (1000 keys typical)
- Multiple iterations for statistical validity  
- Compare against stdlib Dict consistently
- Document environment (Apple Silicon M-series baseline)

## Evidence-Based Strategy (Modular Repo Analysis)

### SIMD Reality Check
- **Our Current SIMD is Good**: We already use `SIMD[DType.uint8, 16]` effectively in `simd_ops.mojo`
- **Modular Pattern**: Standard SIMD types work well, complex intrinsics only for ML workloads
- **Focus**: Algorithmic improvements over more aggressive SIMD

### Thread Safety Assessment  
- **Performance Cost**: 10-30% penalty from mutex overhead and cache contention
- **Modular Evidence**: No thread-safe data structures in core libraries
- **Decision**: Skip thread safety - preserve our speed advantage

### Python Bindings Viability
- **Patterns Available**: `PythonModuleBuilder` and `max.mojo.importer` well-established
- **Example Path**: `private/modular/examples/mojo/python-interop/`
- **Implementation**: Focus on bulk operations to amortize interop overhead

### Performance Expectations (Realistic)
- **Phase 1**: 1.8x-2.2x speedup (not 3x+) through specialized types
- **Phase 2**: 2x+ vs Python dict (confirmed feasible after interop overhead)

## References

- **Swiss Tables Design**: https://abseil.io/about/design/swisstables
- **Performance Roadmap**: docs/ROADMAP.md (revised based on evidence)
- **Migration Guide**: docs/migration-from-dict.md
- **GitHub Release**: https://github.com/nijaru/swiss-mojo/releases/tag/v0.1.0
- **Modular Repo Patterns**: private/modular/ (SIMD, Python bindings evidence)

---

**Last Updated**: 2025-07-17  
**Current Version**: v0.1.0  
**Next Target**: v0.2.0 with specialized types and SIMD bulk operations