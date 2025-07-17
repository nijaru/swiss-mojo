# Security Policy

## Supported Versions

We currently support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability in swiss-mojo, please report it by emailing:

**Email**: nijaru7@gmail.com

Include the following information:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Any suggested fixes or mitigations

## Security Considerations

### Thread Safety
- SwissTable is **NOT thread-safe** by design
- Concurrent access requires external synchronization
- See [Performance Guide](docs/performance-guide.md) for safe patterns

### Memory Safety
- All memory operations use Mojo's safe ownership model
- No unsafe pointer dereferencing in public API
- Automatic memory cleanup via `__del__` methods

### Hash Function Security
- `DefaultHashFunction`: Provides good hash distribution, not cryptographically secure
- `SimpleHashFunction`: Fast but predictable, unsuitable for untrusted input
- Use cryptographic hash functions for security-sensitive applications

### Denial of Service (DoS) Protection
- SwissTable is vulnerable to algorithmic complexity attacks with predictable hash functions
- For applications processing untrusted input, use:
  - Cryptographically secure hash functions
  - Input validation and rate limiting
  - Random seeds for hash functions

### Memory Disclosure
- No intentional memory disclosure in the implementation
- All memory is properly zeroed on deallocation
- No information leakage through timing attacks in normal usage

## Best Practices for Secure Usage

1. **Input Validation**: Validate all external input before using as hash table keys
2. **Hash Function Selection**: Use appropriate hash functions for your threat model
3. **Memory Limits**: Set reasonable limits on table size for untrusted input
4. **Thread Safety**: Properly synchronize concurrent access
5. **Error Handling**: Handle all Optional return values to prevent crashes

## Response Timeline

- **Initial Response**: Within 48 hours of receiving the report
- **Acknowledgment**: Within 1 week with preliminary assessment
- **Fix Timeline**: Critical vulnerabilities patched within 30 days
- **Disclosure**: Coordinated disclosure after fix is available

## Security Updates

Security updates will be:
- Released as patch versions (e.g., 0.1.1)
- Announced in the CHANGELOG.md
- Tagged in GitHub releases with security advisory
- Documented with CVE numbers when applicable

Thank you for helping keep swiss-mojo and our users safe!