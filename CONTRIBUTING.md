# Contributing to Swiss-Mojo

Thank you for your interest in contributing to swiss-mojo! This document provides guidelines for contributing to this high-performance Swiss table implementation for Mojo.

## Table of Contents
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Performance](#performance)
- [Submitting Changes](#submitting-changes)
- [Code Style](#code-style)
- [Reporting Issues](#reporting-issues)

## Getting Started

### Prerequisites
- [Mojo SDK](https://modular.com/mojo) (latest stable version)
- [Pixi](https://prefix.dev/) for dependency management
- Git for version control

### Development Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/swiss-table-mojo.git
   cd swiss-table-mojo
   ```

2. **Install dependencies:**
   ```bash
   pixi install
   ```

3. **Run tests to verify setup:**
   ```bash
   pixi run test-basic
   pixi run test-comprehensive
   ```

4. **Run benchmarks:**
   ```bash
   pixi run benchmark
   ```

## Making Changes

### Branch Strategy
- Create feature branches from `main`
- Use descriptive branch names: `feature/add-iterator-safety`, `fix/memory-leak-resize`
- Keep branches focused on single features or fixes

### Commit Messages
Follow conventional commit format:
```
type(scope): description

Examples:
feat(api): add get() method with default parameter
fix(memory): resolve leak in resize operation  
perf(lookup): optimize SIMD operations for ARM64
docs(guide): add thread safety examples
test(stress): add large table benchmarks
```

### Types:
- `feat`: New features
- `fix`: Bug fixes
- `perf`: Performance improvements
- `docs`: Documentation changes
- `test`: Test additions/improvements
- `refactor`: Code refactoring
- `style`: Code style changes

## Testing

### Test Categories

1. **Basic Tests** - Core functionality:
   ```bash
   pixi run test-basic
   ```

2. **Comprehensive Tests** - Advanced scenarios:
   ```bash
   pixi run test-comprehensive
   ```

3. **Enhanced API Tests** - New method validation:
   ```bash
   pixi run mojo run -I . test/test_enhanced_api.mojo
   ```

### Writing Tests

All new features must include:
- **Unit tests** for individual methods
- **Integration tests** for feature interaction
- **Edge case tests** for boundary conditions
- **Performance tests** for critical paths

Test file structure:
```mojo
fn test_feature_name() raises:
    """Test description with expected behavior."""
    var table = SwissTable[String, Int](DefaultHashFunction())
    
    # Test setup
    _ = table.insert("key", 42)
    
    # Test assertion
    assert_equal(table.size(), 1)
    
    # Test cleanup (if needed)
    table.clear()
```

### Performance Testing

For performance-critical changes:

1. **Run statistical benchmarks:**
   ```bash
   pixi run mojo run -I . benchmarks/statistical_benchmark.mojo
   ```

2. **Compare before/after results:**
   - Document performance impact
   - Include confidence intervals
   - Test on different scales (10, 100, 500, 1000 keys)

3. **Regression testing:**
   - Ensure no performance degradation
   - Validate statistical significance

## Performance

### Performance Requirements

- **No regressions**: New changes must not slow down existing operations
- **Statistical validation**: Performance claims require confidence intervals
- **Scale testing**: Test performance at multiple table sizes
- **Platform considerations**: Consider Apple Silicon, Intel x64, ARM64

### Optimization Guidelines

1. **Profile first**: Use benchmarks to identify bottlenecks
2. **Measure impact**: Quantify improvements with statistical rigor  
3. **Consider trade-offs**: Document any memory vs speed decisions
4. **Platform compatibility**: Ensure optimizations work across platforms

## Submitting Changes

### Pull Request Process

1. **Create feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes with tests:**
   - Implement feature
   - Add comprehensive tests
   - Update documentation

3. **Run full test suite:**
   ```bash
   pixi run test-basic
   pixi run test-comprehensive
   pixi run benchmark
   ```

4. **Commit with sign-off:**
   ```bash
   git commit -s -m "feat(api): add new feature with tests"
   ```

5. **Push and create PR:**
   ```bash
   git push origin feature/your-feature-name
   # Create PR through GitHub interface
   ```

### PR Requirements

- [ ] All tests pass
- [ ] New code has test coverage
- [ ] Documentation updated
- [ ] Performance impact assessed
- [ ] Code follows style guidelines
- [ ] Commit messages are clear
- [ ] PR description explains changes

### PR Description Template

```markdown
## Summary
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Performance improvement
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Performance benchmarks run
- [ ] Edge cases covered

## Performance Impact
- Benchmark results (if applicable)
- Memory usage changes
- Compatibility considerations

## Breaking Changes
List any breaking changes and migration guide

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests pass locally
```

## Code Style

### Mojo Style Guidelines

Follow Mojo stdlib conventions:

1. **Naming:**
   - Functions: `snake_case`
   - Structs: `PascalCase`
   - Constants: `UPPER_CASE`
   - Private methods: `_private_method`

2. **Documentation:**
   ```mojo
   fn method_name(self, param: Type) -> ReturnType:
       """Brief description.
       
       Args:
           param: Parameter description.
           
       Returns:
           Description of return value.
       """
   ```

3. **Error Handling:**
   - Use `Optional[T]` for nullable returns
   - Document when functions may raise
   - Provide clear error messages

4. **Performance:**
   - Use `@always_inline` for hot paths
   - Minimize allocations in tight loops
   - Prefer move semantics with `^` operator

### Code Quality

- **No compiler warnings**: Code must compile cleanly
- **Memory safety**: Proper ownership and cleanup
- **Thread safety**: Document concurrent access requirements
- **Error handling**: Robust error conditions

## Reporting Issues

### Bug Reports

Use GitHub issues with:

1. **Environment:**
   - Mojo version
   - Operating system
   - Hardware (Apple Silicon, Intel, etc.)

2. **Reproduction:**
   - Minimal code example
   - Expected vs actual behavior
   - Steps to reproduce

3. **Context:**
   - Performance impact
   - Frequency of occurrence
   - Workarounds tried

### Feature Requests

Include:
- **Use case**: Why this feature is needed
- **Proposed API**: How it would work
- **Alternatives**: Other solutions considered
- **Performance impact**: Expected implications

### Security Issues

**Do not use GitHub issues for security vulnerabilities.**
See [SECURITY.md](SECURITY.md) for reporting process.

## Release Process

### Version Strategy
- **Patch versions** (0.1.x): Bug fixes, performance improvements
- **Minor versions** (0.x.0): New features, API additions
- **Major versions** (x.0.0): Breaking changes

### Release Checklist
- [ ] All tests pass
- [ ] Performance benchmarks updated
- [ ] CHANGELOG.md updated
- [ ] Documentation reviewed
- [ ] Version tagged
- [ ] Release notes published

## Getting Help

- **Questions**: Use GitHub Discussions
- **Bugs**: Create GitHub Issues
- **Security**: Email per SECURITY.md
- **Performance**: Include benchmark results

## Recognition

Contributors will be:
- Listed in git commit history
- Mentioned in release notes for significant contributions
- Added to contributors list for major features

Thank you for contributing to swiss-mojo! Your efforts help make high-performance hash tables available to the Mojo community.