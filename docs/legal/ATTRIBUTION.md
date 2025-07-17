# Attribution and Acknowledgments

This SwissTable implementation draws inspiration from several proven designs and algorithms. We acknowledge the excellent work of these projects and teams.

## Algorithm References

### Swiss Tables Design
**Source**: [Abseil C++](https://github.com/abseil/abseil-cpp)  
**License**: Apache 2.0  
**Contribution**: Original Swiss table design with control bytes, SIMD optimization patterns, and memory layout strategies. The foundational research and implementation provided the algorithmic basis for this work.

### Production Implementation Patterns  
**Source**: [Hashbrown](https://github.com/rust-lang/hashbrown)  
**License**: MIT/Apache 2.0  
**Contribution**: Production-quality Swiss table implementation with SSE2 group operations, H1/H2 hash splitting techniques, and control byte encoding patterns.

### Performance Optimization Insights
**Source**: Mojo Standard Library Dict Implementation  
**License**: Modular proprietary  
**Contribution**: Performance analysis insights, probe sequence optimization patterns, and single-pass insertion algorithm concepts that informed our adaptive algorithm selection.

## Technical Concepts

- **Control Byte Design**: 1-byte metadata per slot with MSB encoding (empty=255, deleted=128, full=0-127)
- **SIMD Group Operations**: Processing 16 control bytes simultaneously via SSE2 instructions
- **H1/H2 Hash Splitting**: Using high bits for control bytes, full hash for probe sequence
- **Quadratic Probing**: Group-based probing with mathematical collision guarantees
- **Cache-Friendly Layout**: Separating metadata from data for improved memory access patterns

## Implementation Notes

This implementation is an independent clean-room implementation for Mojo, designed specifically for:
- **Mojo ownership model compatibility**: Leveraging Mojo's memory safety and move semantics
- **Dict API compatibility**: Providing a drop-in replacement for standard Dict operations
- **Performance optimization**: Achieving superior performance through SIMD and adaptive algorithms
- **Iterator safety**: Adding generation tracking for modification detection during iteration

## Differences from Reference Implementations

- **Iterator Safety**: Addition of generation tracking to detect table modifications during iteration
- **API Compatibility**: Complete Dict API including __len__, __bool__, pop(), get() methods
- **Adaptive Algorithms**: Size-based selection between SIMD and simplified algorithms
- **Memory Safety**: Mojo-specific safety features and ownership model compliance

## License Compatibility

All referenced works use permissive licenses (Apache 2.0, MIT) that allow derivative works. This implementation:
- Does not redistribute any external source code
- Implements algorithms independently in Mojo
- Adds original contributions for safety and compatibility
- Maintains Apache 2.0 licensing for compatibility

## Research Papers and Documentation

- **"Swiss Tables Design"** - Abseil Team, Google
- **"Swiss Tables and Hash Tables"** - CppCon presentations
- **"High Performance Hash Tables"** - Various algorithmic research

---

*This attribution acknowledges the foundational work that made this implementation possible while maintaining clear boundaries between reference materials and our independent implementation.*