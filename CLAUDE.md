# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a template repository for Domain-Driven Design (DDD) Python projects using FastAPI. The project demonstrates DDD principles and patterns in Python with a clean architecture approach.

## Architecture

This template follows DDD architectural patterns:

- **Domain Layer** (`src/domain/`): Core business logic, entities, value objects, and domain services
- **Application Layer** (`src/application/`): Use cases, application services, and DTOs
- **Infrastructure Layer** (`src/infrastructure/`): Database repositories, external service adapters, and technical concerns
- **Presentation Layer** (`src/presentation/`): FastAPI routes, schemas, and dependency injection

## Development Setup

### Prerequisites
- [Devbox](https://www.jetpack.io/devbox) for development environment
- The project uses `uv` for Python package management (no virtual env needed in devbox)

### Getting Started

1. **Enter development environment:**
   ```bash
   devbox shell
   ```

2. **Install dependencies:**
   ```bash
   uv sync
   ```

3. **Run the application:**
   ```bash
   uv run python -m src.main
   ```

4. **Run tests:**
   ```bash
   uv run pytest
   ```

5. **Run linting and formatting:**
   ```bash
   uv run ruff check
   uv run ruff format
   ```

6. **Run type checking:**
   ```bash
   uv run mypy src/
   ```

### Development Commands

- **Install new dependency:** `uv add <package>`
- **Install dev dependency:** `uv add --dev <package>`
- **Run tests with coverage:** `uv run pytest --cov=src`
- **Run specific test:** `uv run pytest tests/unit/domain/test_user.py`
- **Format code:** `uv run ruff format`
- **Lint code:** `uv run ruff check --fix`
- **Type check:** `uv run mypy src/`

### Docker Development

1. **Build and run with Docker Compose:**
   ```bash
   docker-compose up --build
   ```

2. **Run API only:**
   ```bash
   docker build -t ddd-api .
   docker run -p 8000:8000 ddd-api
   ```

## Template Usage

This repository serves as a starting point for new DDD Python projects:

1. Clone or use as GitHub template
2. Update `pyproject.toml` with your project details
3. Customize domain models for specific business requirements
4. Implement infrastructure adapters for chosen technologies
5. Configure CI/CD pipelines for deployment

## Key DDD Concepts Implemented

- **Value Objects**: `Email` with validation and immutability
- **Entities**: `User` with identity and business logic
- **Domain Events**: `UserCreatedEvent` for domain event handling
- **Domain Services**: `UserDomainService` for business logic coordination
- **Repository Pattern**: `SqlAlchemyUserRepository` for data persistence
- **Use Cases**: `CreateUserUseCase` for application logic orchestration
- **Dependency Injection**: Using `dependency-injector` for IoC

## Examples System

The template includes a modular examples system that demonstrates DDD patterns without polluting the core template.

### Using Examples for Learning
```bash
# List available example modules
task examples:list

# Get detailed information about a module
task examples:info -- _template

# Validate module structure
task examples:validate -- _template
```

### Using Template for New Projects
For a clean starting point, simply delete the examples directory:
```bash
rm -rf examples/
```

The template remains fully functional with all tooling and architecture intact.

### Creating Example Modules
```bash
# Create a new example module from template
task examples:scaffold -- my-example

# Clean up all examples except template
task examples:clean
```

See `examples/README.md` for comprehensive documentation on the examples system and `examples/_template/` for the module creation template.