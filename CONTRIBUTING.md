# Contributing to Test Endeelo

🎉 Thank you for your interest in contributing to Test Endeelo!

This project features **AI-powered automated workflows** that will analyze and review your contributions. Here's how to get started:

## 🚀 Quick Start

1. **Fork the repository**
2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/test_endeelo.git
   cd test_endeelo
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/amazing-feature
   ```
4. **Make your changes**
5. **Commit with descriptive messages**:
   ```bash
   git commit -m "feat: Add amazing feature"
   ```
6. **Push to your fork**:
   ```bash
   git push origin feature/amazing-feature
   ```
7. **Open a Pull Request**

## 🤖 AI Will Review Your PR

When you submit a PR, our AI workflows will automatically:
- 🔍 Analyze code quality
- 🛡️ Check for security issues
- ⚡ Suggest performance improvements
- 📚 Verify documentation
- 🧪 Review test coverage
- 🏷️ Add appropriate labels

## 📝 Commit Message Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks
- `perf:` - Performance improvements
- `ci:` - CI/CD changes

### Examples
```bash
feat: Add user authentication system
fix: Resolve memory leak in data processor
docs: Update installation instructions
test: Add unit tests for API endpoints
```

## 🎯 Code Style

### Python
- Follow PEP 8
- Use type hints
- Maximum line length: 100 characters
- Use docstrings for functions and classes

### Example
```python
def process_data(input_data: dict) -> dict:
    """
    Process input data and return results.
    
    Args:
        input_data: Dictionary containing raw data
        
    Returns:
        Dictionary with processed results
    """
    # Your code here
    return result
```

## 🧪 Testing

- Write tests for new features
- Ensure existing tests pass
- Aim for >80% code coverage

```bash
# Run tests
pytest tests/

# With coverage
pytest --cov=. tests/
```

## 📚 Documentation

- Update README.md if adding features
- Add docstrings to new functions/classes
- Include inline comments for complex logic
- Update workflow documentation if modifying .github/workflows/

## ✅ PR Checklist

Before submitting your PR, ensure:

- [ ] Code follows project style guidelines
- [ ] Tests added/updated and passing
- [ ] Documentation updated
- [ ] Commit messages follow convention
- [ ] No merge conflicts
- [ ] Branch is up to date with main
- [ ] Self-review completed

## 🔄 Workflow Contributions

When modifying GitHub Actions workflows:

1. **Test locally** if possible
2. **Add comments** explaining complex logic
3. **Update documentation** in README.md
4. **Ensure secrets** are not hardcoded
5. **Test with fork** before submitting PR

### Workflow Structure
```yaml
name: "Descriptive Name"

on:
  push:
    branches: [main]
  workflow_dispatch:  # Enable manual triggering

jobs:
  job-name:
    runs-on: ubuntu-latest
    steps:
      - name: "Clear Step Name"
        run: |
          # Your commands
```

## 🐛 Bug Reports

When reporting bugs, include:

1. **Description**: Clear description of the issue
2. **Steps to reproduce**: Detailed steps
3. **Expected behavior**: What should happen
4. **Actual behavior**: What actually happens
5. **Environment**: OS, Python version, etc.
6. **Logs/Screenshots**: If applicable

### Bug Report Template
```markdown
## Bug Description
Clear and concise description

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. See error

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., Ubuntu 22.04]
- Python: [e.g., 3.11]
- Version: [e.g., v2.0.0]

## Additional Context
Any other relevant information
```

## 💡 Feature Requests

For feature requests, include:

1. **Problem**: What problem does this solve?
2. **Proposed Solution**: Your suggested approach
3. **Alternatives**: Other solutions considered
4. **Additional Context**: Examples, mockups, etc.

## 🤝 Code Review Process

1. **AI Review**: Automated analysis within minutes
2. **Human Review**: Maintainer review within 48 hours
3. **Feedback**: Address any comments/suggestions
4. **Approval**: At least one maintainer approval required
5. **Merge**: Maintainers will merge approved PRs

## 🎓 Learning Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Python Best Practices](https://docs.python-guide.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Testing with Pytest](https://docs.pytest.org/)

## ❓ Questions?

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Pull Requests**: For code contributions

## 🙏 Recognition

All contributors are recognized in our README.md and release notes!

## 📜 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all.

### Our Standards

**Positive behaviors:**
- ✅ Using welcoming and inclusive language
- ✅ Being respectful of differing viewpoints
- ✅ Gracefully accepting constructive criticism
- ✅ Focusing on what is best for the community
- ✅ Showing empathy towards others

**Unacceptable behaviors:**
- ❌ Trolling, insulting, or derogatory comments
- ❌ Public or private harassment
- ❌ Publishing others' private information
- ❌ Other conduct inappropriate in a professional setting

### Enforcement

Instances of unacceptable behavior may be reported to project maintainers. All complaints will be reviewed and investigated.

## 🚀 Getting Help

- Check existing issues and discussions
- Review documentation
- Ask in GitHub Discussions
- Tag maintainers if urgent

---

**Thank you for contributing to Test Endeelo! 🎉**

*Made with 🤖 AI and ❤️ by the community*
