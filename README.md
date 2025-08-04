# DDD Python Template 🏗️
<!-- Deployment trigger: 2025-08-04 v4 - After comprehensive CloudWatch cleanup -->

[![Python](https://img.shields.io/badge/python-3.11+-blue.svg)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-green.svg)](https://fastapi.tiangolo.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Code style: ruff](https://img.shields.io/badge/code%20style-ruff-000000.svg)](https://github.com/astral-sh/ruff)

A comprehensive template for building scalable Python APIs using Domain-Driven Design (DDD) principles, FastAPI, and modern development practices.

## 🎯 What You Get

This template provides a production-ready foundation for DDD Python projects with:

- **Clean Architecture**: Properly separated domain, application, infrastructure, and presentation layers
- **Modern Python Stack**: FastAPI, SQLAlchemy 2.0, Pydantic v2, async/await throughout
- **Development Experience**: Devbox environment, automated tooling, comprehensive examples
- **Production Ready**: Docker containers, dependency injection, structured logging
- **Quality Assurance**: Type checking (mypy), linting (ruff), testing (pytest), git hooks

## 🚀 Quick Start

### Prerequisites

Choose one development environment:

**Option A: Devbox (Recommended)**
```bash
# Install devbox: https://www.jetpack.io/devbox/docs/installing_devbox/
devbox shell
```

**Option B: Development Container**
```bash
# Open in VS Code with Dev Containers extension
# Or use GitHub Codespaces
```

### Get Started

1. **Clone and setup:**
   ```bash
   git clone <your-repo-url>
   cd ddd-python-template
   task setup  # Complete project initialization
   ```

2. **Start developing:**
   ```bash
   task dev:run     # Start development server with auto-reload
   task test:all    # Run complete test suite
   task check       # Run code quality checks
   ```

3. **Access your API:**
   - API: http://localhost:8000
   - Docs: http://localhost:8000/docs
   - Health: http://localhost:8000/health

## 🏛️ Architecture Overview

### Domain-Driven Design Layers

```
src/
├── domain/          # 🧠 Business logic and rules
│   ├── entities/    # Core business objects with identity
│   ├── value_objects/ # Immutable descriptive objects
│   ├── events/      # Domain events for decoupling
│   └── services/    # Domain logic coordination
├── application/     # 🎯 Use cases and workflows  
│   ├── use_cases/   # Application business flows
│   ├── dtos/        # Data transfer objects
│   └── services/    # Application workflow coordination
├── infrastructure/ # 🔧 Technical implementation
│   ├── repositories/ # Data persistence implementations
│   ├── adapters/    # External service integrations
│   └── database/    # ORM models and connections
└── presentation/   # 🌐 HTTP API and external interfaces
    ├── api/         # FastAPI route handlers
    ├── schemas/     # Request/response validation
    └── dependencies/ # Dependency injection setup
```

### Key DDD Patterns Implemented

- **Entities & Value Objects**: `User` entity with `Email` value object
- **Domain Events**: `UserCreatedEvent` for decoupled communication
- **Repository Pattern**: `UserRepository` interface with SQLAlchemy implementation
- **Use Cases**: `CreateUserUseCase` for application workflow orchestration
- **Dependency Injection**: Clean IoC container using `dependency-injector`

## 🛠️ Development Workflow

### Available Commands

```bash
# Development
task dev:run          # Start server with auto-reload
task dev:install      # Install/update dependencies
task dev:shell        # Enter development shell

# Code Quality  
task check            # Run all quality checks
task fix              # Auto-fix formatting and imports
task lint             # Run linting checks
task format           # Format code with ruff
task typecheck        # Run mypy type checking

# Testing
task test:all         # Run complete test suite
task test:unit        # Run unit tests only
task test:integration # Run integration tests
task test:e2e         # Run end-to-end tests
task test:coverage    # Run tests with coverage report

# Examples System
task examples:list    # Show available DDD pattern examples
task examples:info    # Get detailed module information
task examples:clean   # Clean up example modules

# Versioning
task version          # Show current version
task version:validate-all # Validate versioning files
```

### Code Quality Standards

This template enforces high code quality through:

- **Linting**: Ruff for fast Python linting and formatting
- **Type Checking**: MyPy with strict configuration
- **Testing**: Pytest with async support and coverage reporting
- **Git Hooks**: Lefthook for automated pre-commit checks
- **Import Sorting**: Organized imports with known first-party handling

## 📚 Learning & Examples

### Examples System

The template includes a modular examples system demonstrating DDD patterns:

```bash
task examples:list    # See available pattern examples
task examples:info -- user-management  # Deep dive into specific patterns
```

For a clean starting template, simply delete the `examples/` directory.

### Key Learning Resources

- **[Repository Structure](docs/repository-structure.md)**: Complete codebase organization
- **[Architecture Decisions](docs/adr/)**: Design rationale and trade-offs
- **[Style Guide](STYLE_GUIDE.md)**: Code, commit, and documentation standards
- **[Contributing Guide](CONTRIBUTING.md)**: Development workflow and practices

## 🔧 Development Environment

### Devbox Environment

This project uses [Devbox](https://www.jetpack.io/devbox) for reproducible development environments:

- **Python 3.11+**: Latest Python with uv package manager
- **Development Tools**: Task, Git LFS, CUE, Nushell scripting
- **Quality Tools**: Ruff, MyPy, Pytest, Lefthook
- **No Virtual Env Needed**: Devbox provides isolated shell environment

### Package Management

Uses **UV** for fast, reliable Python package management:

```bash
uv add package-name           # Add runtime dependency
uv add --dev package-name     # Add development dependency  
uv sync                       # Install all dependencies
uv run python script.py       # Run with proper environment
```

## 🐳 Production Deployment

### Docker Support

```bash
# Build production image
docker build -t ddd-api .

# Run with Docker Compose (includes database)
docker-compose up --build

# Production deployment
task build:docker:push        # Build and push to registry
```

### Configuration

Environment-based configuration using Pydantic Settings:

```python
# src/infrastructure/config.py
class Settings(BaseSettings):
    database_url: str = "postgresql://..."
    log_level: str = "INFO"
    # ... other settings
```

## 🤖 AI-Assisted Development

This template is optimized for AI-assisted development:

- **[Claude Code Instructions](CLAUDE.md)**: Comprehensive AI assistant guidance
- **Spec-Driven Development**: Structured requirements in `.guidance/spec/`
- **Automated Documentation**: Self-updating project structure and patterns
- **Quality Automation**: AI-friendly tooling and validation

## 📋 Project Roadmap

Current focus areas:

- [ ] Advanced domain event handling patterns
- [ ] Multi-tenant architecture support  
- [ ] OpenAPI specification automation
- [ ] Performance monitoring integration
- [ ] Advanced testing patterns and fixtures

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for:

- Development workflow and standards
- Code review process and requirements
- Architecture decision guidelines
- Testing and documentation expectations

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: Report bugs and request features via [GitHub Issues](https://github.com/yourusername/ddd-python-template/issues)
- **Discussions**: Ask questions and share ideas in [GitHub Discussions](https://github.com/yourusername/ddd-python-template/discussions)  
- **Documentation**: Check our comprehensive [docs/](docs/) directory

---

**Built with ❤️ for the Python DDD community**

*This template helps you focus on business logic while providing enterprise-grade infrastructure and development experience.*