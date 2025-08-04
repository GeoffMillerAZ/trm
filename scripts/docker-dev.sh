#!/usr/bin/env bash
# Convenience script for Docker development commands

set -euo pipefail

COMMAND=${1:-help}
shift || true

case "$COMMAND" in
    up)
        echo "🚀 Starting development services..."
        docker-compose -f docker/compose/docker-compose.dev.yml up "$@"
        ;;
    
    devbox)
        echo "📦 Starting Devbox environment..."
        docker-compose -f docker/compose/docker-compose.devbox-test.yml up "$@"
        ;;
    
    prod)
        echo "🏭 Starting production stack..."
        docker-compose -f docker/compose/docker-compose.prod.yml up "$@"
        ;;
    
    test)
        echo "🧪 Running tests..."
        docker-compose -f docker/compose/docker-compose.devbox-test.yml run --rm test-runner
        ;;
    
    build)
        echo "🔨 Building images..."
        DOCKER_BUILDKIT=1 docker-compose -f docker/compose/docker-compose.prod.yml build "$@"
        ;;
    
    clean)
        echo "🧹 Cleaning up..."
        docker-compose -f docker/compose/docker-compose.dev.yml down -v
        docker-compose -f docker/compose/docker-compose.prod.yml down -v
        docker-compose -f docker/compose/docker-compose.devbox-test.yml down -v
        ;;
    
    logs)
        docker-compose -f docker/compose/docker-compose.dev.yml logs -f "$@"
        ;;
    
    shell)
        echo "🐚 Opening shell in container..."
        docker-compose -f docker/compose/docker-compose.devbox.yml run --rm devbox devbox shell
        ;;
    
    help|*)
        echo "Docker development helper"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  up       Start development services (Redis, DynamoDB)"
        echo "  devbox   Start Devbox development environment"
        echo "  prod     Start production stack"
        echo "  test     Run tests in container"
        echo "  build    Build Docker images"
        echo "  clean    Stop and remove all containers/volumes"
        echo "  logs     Show logs (follow mode)"
        echo "  shell    Open shell in Devbox container"
        echo "  help     Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 up               # Start dev services"
        echo "  $0 devbox           # Start with devbox"
        echo "  $0 test             # Run tests"
        echo "  $0 logs api         # Show API logs"
        echo "  $0 clean            # Clean everything"
        ;;
esac