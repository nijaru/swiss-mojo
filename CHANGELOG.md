# Changelog

All notable changes to swiss-mojo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-07-18

Initial production release of SwissTable - a high-performance hash table implementation for Mojo.

### Added

- **SwissTable**: High-performance hash table with 1.16x faster insertions and 2.38x faster lookups vs stdlib Dict
- **Specialized implementations**: FastStringIntTable, FastIntIntTable, FastStringStringTable with 5-147% additional speedup
- **Bulk operations**: High-performance batch processing APIs
  - `bulk_insert()`: Insert multiple key-value pairs with 15-30% throughput improvement
  - `bulk_lookup()`: Look up multiple keys in a single operation
  - `bulk_update()`: Update table with all entries from another table
  - `bulk_insert_fast()`: Ultra-fast insertion without result collection
  - `bulk_contains_fast()`: Fast existence check returning only count
- **Dict-compatible API**: Drop-in replacement for stdlib Dict with enhanced performance methods
- **Enhanced API**: `insert()`, `lookup()`, `delete()`, `contains()`, `reserve()` for maximum performance
- **Custom hash functions**: Support for `MojoHashFunction` and custom hash implementations
- **Memory efficiency**: 87.5% load factor vs Dict's 66.7%
- **Thread safety documentation**: Comprehensive analysis and safe usage patterns
- **Performance regression testing**: Automated framework for continuous validation
- **Package distribution**: Pre-built `.mojopkg` for easy installation
- **Comprehensive documentation**: Examples, migration guide, and performance optimization guide
- **Production testing**: 100% correctness validation with comprehensive test suite

### Performance

- **1.16x faster insertions** than stdlib Dict (68.3M vs 58.7M ops/sec)
- **2.38x faster lookups** than stdlib Dict (857.6M vs 361.0M ops/sec)
- **15-30% throughput improvement** for bulk operations with 16+ items
- **FastStringIntTable**: +5.4% insertion speedup over generic SwissTable
- **FastIntIntTable**: +11% insertion speedup over generic SwissTable  
- **FastStringStringTable**: +147% insertion speedup over generic SwissTable

Based on proven algorithms from Google's Abseil library, Rust's hashbrown, and Go 1.24+ maps.