# Contributing

Thank you for your interest in contributing!

## Development Setup

### Prerequisites

- Xcode 15+ or Swift 5.9+ toolchain
- macOS 12+ or Linux with Swift installed

### Installation

```bash
git clone https://github.com/PrivaraXYZ/platform-cofhe-swift-sdk.git
cd platform-cofhe-swift-sdk
swift build
```

### Running Tests

```bash
swift test                                              # Unit tests
COFHE_BASE_URL=https://... swift test --filter E2E      # E2E tests
```

## Code Style

- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Use `Codable` for JSON serialization
- Use `async/await` for asynchronous operations
- Use enums with associated values for error hierarchies
- Minimal comments — code should be self-documenting

## Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — New feature
- `fix:` — Bug fix
- `docs:` — Documentation
- `test:` — Tests
- `refactor:` — Code refactoring
- `chore:` — Build/config changes

## Pull Request Process

1. Fork the repository
2. Create feature branch (`git checkout -b feat/amazing-feature`)
3. Commit changes (`git commit -m 'feat: add amazing feature'`)
4. Push to branch (`git push origin feat/amazing-feature`)
5. Open Pull Request

### PR Checklist

- [ ] Tests pass (`swift test`)
- [ ] No new warnings
- [ ] Documentation updated if needed
- [ ] Follows existing code patterns

## Questions?

Open an issue or start a discussion.
