# 🤝 contributing to Telegem

 Thank you for your interest in contributing to Telegem! This document provides guidelines and instructions for contributing to Telegem. 
 whether you are fixing bugs, improving documentation or proposing new features, your contributions are welcome 
 
 ## 📋 Table of Contents
- [Code of Conduct](#-code-of-conduct)
- [Getting Started](#-getting-started)
- [How to Contribute](#-how-to-contribute)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)
- [Code Contributions](#code-contributions)
- [Documentation](#documentation)
- [Development Setup](#-development-setup)
- [Pull Request Process](#-pull-request-process)
- [Style Guides](#-style-guides)
- [Community](#-community)
- [Recognition](#-recognition)

## code of conduct

We are committed to providing a welcoming and inspiring community for all. Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before participating.

## 🚀 Getting Started

### Prerequisites
- Ruby v3.x
- Git

### Quick Start
1. **Fork the repository** on GitLab
2. **Clone your fork:**
   ```bash
   git clone https://gitlab.com/your-username/telegem.git
   cd telegem
   ```
 3. Install dependencies 
   ```bash 
   $ gem install 
   ```
 4. run test 
 ```bash 
  $ rspec test/spec.rb
  ```
  ## How to contribute 
  
  ##reporting bugs 
   Bugs are tracked as Gitlab Issues 
   
   **before submitting a bug report:**
   - check if the issue has already been reported 
   - update to the latest version to see if issues persists
   - check the documentation and existing solutions to the issue 
   **A good report includes:**
   1. clear descriptive title
   2. steps to be reproduced (be specific)
   3. expected behavior 
   4. relevant logs or message 
   
   Code Contributions

1. Find an issue to work on:
   - Check issues labeled good first issue or help wanted
   - Comment on the issue to let us know you're working on it
2. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```
3. Make your changes
4. Write/update tests
5. Update documentation if needed
6. Run tests locally:
   ```bash
   rspec test/spec.rb
   ```

Documentation

Good documentation is crucial! You can help by:

- Fixing typos or unclear explanations
- Adding examples to existing documentation
- Writing tutorials or how-to guides
- Improving API documentation
- Translating documentation

Testing

```bash
# Run all tests
 rspec test/spec.rb
 
bundle exec bundle-audit
```

🎯 Pull Request Process

1. Update your fork with the latest changes from upstream:
   ```bash
   git remote add upstream https://gitlab.com/ruby-telegem/telegem.git
   git fetch upstream
   git rebase upstream/main
   ```
2. Ensure all tests pass
3. Update documentation if your changes affect functionality
4. Create a Merge Request (MR) on GitLab:
   - Use a clear, descriptive title
   - Reference any related issues (e.g., "Closes #123")
5. Address review feedback promptly
6. Once approved, a maintainer will merge your changes





👥 Community

Discussion

- Issues: GitLab Issues
- Merge Requests: GitLab MRs

Getting Help

- Search existing issues and documentation first
- Be respectful and patient with other community members
- Provide as much context as possible when asking for help

🏆 Recognition

All contributors are recognized in our HALL_OF_FAME.md. We appreciate every contribution, big or small!

Contributors who make significant impact may be:

- Added to the "Active Contributors" section
-  Given commit access (for trusted, regular contributors)
- Featured in release notes



Release Cycle

-  We follow Semantic Versioning
- Major releases
- Minor releases
- Patch releases 

License

By contributing, you agree that your contributions will be licensed under the project's LICENSE.

---

Thank you for contributing to Telegem! Your efforts help make this project better for everyone. 🚀

```
  

 