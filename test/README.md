# SwissTable Test Suite

Comprehensive testing infrastructure for SwissTable with organized, focused test categories.

## Test Organization

### 🧪 Unit Tests (`test/unit/`)
Focused tests for individual components and edge cases:

- **`test_edge_cases.mojo`** - Boundary conditions, empty tables, single elements
- **`test_collisions.mojo`** - Hash collision handling, pathological hash functions  
- **`test_memory_safety.mojo`** - Resource cleanup, memory leak prevention

### 🔗 Integration Tests (`test/integration/`)
Tests for components working together and real-world usage:

- **`test_comprehensive.mojo`** - Full API compatibility, bulk operations
- **`test_stress.mojo`** - Large datasets, heavy workloads, random patterns
- **`test_installation.mojo`** - README examples, package installation simulation
- **`test_package.mojo`** - .mojopkg functionality validation

### ⚡ Performance Benchmarks (`test/benchmarks/`)
Statistical benchmarking with rigorous performance validation:

- **`core_performance.mojo`** - SwissTable vs stdlib Dict comparison
- **`specialized_performance.mojo`** - Specialized vs generic table performance
- **`regression_guard.mojo`** - Automated performance regression detection

## Running Tests

### Individual Test Categories
```bash
# Unit tests
pixi run test-edge         # Edge cases and boundaries
pixi run test-collisions   # Hash collision handling  
pixi run test-memory       # Memory safety

# Integration tests
pixi run test-comprehensive # Full API testing
pixi run test-stress       # Stress testing
pixi run test-installation # Installation validation
pixi run test-package      # Package functionality

# Performance benchmarks
pixi run benchmark         # Core performance vs Dict
pixi run benchmark-specialized # Specialized table performance
pixi run benchmark-regression  # Regression detection
```

### Test Suites
```bash
# Run all unit tests
pixi run test-unit

# Run all integration tests  
pixi run test-integration

# Run all tests
pixi run test-all

# Run all benchmarks
pixi run benchmark-all
```

### Convenience Commands
```bash
# Default test (unit tests)
pixi run test

# Basic edge case testing
pixi run test-basic
```

## Test Coverage

### ✅ Comprehensive Coverage Areas
- **Core API**: All public methods tested (insert, lookup, delete, etc.)
- **Dict Compatibility**: Full dict-like interface validation
- **Edge Cases**: Empty tables, single elements, capacity boundaries
- **Memory Safety**: Resource cleanup, leak prevention
- **Performance**: Statistical validation with confidence intervals
- **Specialized Tables**: FastStringIntTable, FastIntIntTable, FastStringStringTable
- **Bulk Operations**: Batch processing APIs
- **Error Conditions**: Invalid inputs, missing keys
- **Installation**: Package building and usage simulation

### 📊 Performance Validation
- **1.16x insertion speedup** vs stdlib Dict (validated)
- **2.38x lookup speedup** vs stdlib Dict (validated)
- **Specialized table improvements**: 5.4% to 147% additional speedup
- **Bulk operation improvements**: 15-30% throughput increase
- **Memory efficiency**: 87.5% load factor validation

### 🎯 Quality Standards
- **Statistical rigor**: Multiple iterations, variance analysis
- **Production patterns**: Real-world usage simulation
- **Regression protection**: Automated baseline comparison
- **Documentation validation**: All README examples tested

## Test Organization Principles

### File Naming Convention
- **Unit tests**: `test_[component].mojo` (focused, single responsibility)
- **Integration tests**: `test_[feature].mojo` (multiple components)
- **Benchmarks**: `[category]_performance.mojo` (performance focus)

### Directory Structure
```
test/
├── unit/           # Individual component tests
├── integration/    # Multi-component and real-world tests
├── benchmarks/     # Performance measurement and validation
└── README.md       # This documentation
```

### Test Quality Guidelines
1. **Single Responsibility**: Each test file has one clear focus
2. **Clear Naming**: Descriptive names indicating test purpose
3. **Statistical Validity**: Benchmarks use multiple iterations
4. **Production Simulation**: Tests mirror real usage patterns
5. **Comprehensive Coverage**: All public APIs and edge cases tested

## Adding New Tests

### For New Features
1. Add unit tests in `test/unit/` for individual components
2. Add integration tests in `test/integration/` for feature combinations
3. Add performance tests in `test/benchmarks/` if performance-critical

### For Bug Fixes
1. Add regression test in appropriate unit test file
2. Ensure test fails without fix, passes with fix
3. Update integration tests if behavior changes

The SwissTable test suite provides comprehensive coverage with clear organization, ensuring production-ready quality and performance validation.