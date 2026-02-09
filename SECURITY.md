# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.x.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

### How to Report

Please report security vulnerabilities through GitHub's Security Advisories:

**[Report a vulnerability](https://github.com/PrivaraXYZ/platform-cofhe-swift-sdk/security/advisories/new)**

### What to Include

When reporting a vulnerability, please include:

- A clear description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Any suggested fixes (optional)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 5 business days
- **Resolution Target**: Depends on severity

### Security Measures

This project implements several security measures:

- Input validation for all encryption parameters
- No hardcoded secrets or credentials
- Swift type system for compile-time safety
- Regular dependency updates
- URLSession HTTP client with configurable timeouts

## Security Best Practices

When using this SDK:

1. Always use HTTPS for the CoFHE service URL
2. Use secrets management for sensitive configuration
3. Keep dependencies up to date
4. Monitor logs for suspicious activity
