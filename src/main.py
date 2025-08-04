import os
import sys
from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from src.infrastructure.config.container import get_container
from src.infrastructure.config.settings import (
    ConfigurationError,
    create_settings,
    get_settings,
)
from src.presentation.api.blockchain import router as blockchain_router
from src.presentation.api.health import router as health_router
from src.presentation.api.legacy_blockchain import router as legacy_blockchain_router
from src.presentation.api.legacy_health import router as legacy_health_router

logger = structlog.get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    try:
        # Validate configuration on startup
        settings = get_settings()

        # Log startup information
        logger.info(
            "Starting TRM Block Explorer API",
            environment=settings.environment,
            debug=settings.debug,
            config_info=settings.get_environment_info(),
        )

        # Initialize container to verify all dependencies can be created
        container = get_container()

        # Test critical services
        await container.get_logger()
        await container.get_cache()
        await container.get_database()

        logger.info("Application startup completed successfully")

        yield
    except ConfigurationError as e:
        logger.error(f"Configuration error during startup: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Unexpected error during startup: {e}")
        sys.exit(1)
    finally:
        # Cleanup on shutdown
        try:
            container = get_container()
            await container.close()
            logger.info("Application shutdown completed")
        except Exception as e:
            logger.error(f"Error during shutdown: {e}")


def create_app() -> FastAPI:
    """Create FastAPI application with configuration validation."""
    try:
        # Load and validate configuration
        config_file = os.getenv("CONFIG_FILE")
        settings = create_settings(config_file=config_file, validate=True)

    except ConfigurationError as e:
        print(f"Configuration Error: {e}", file=sys.stderr)
        print("\nPlease check your configuration and try again.", file=sys.stderr)
        print("\nFor configuration help, see:", file=sys.stderr)
        print("  - .env.example for environment variables", file=sys.stderr)
        print("  - configs/ directory for YAML configuration files", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error during configuration: {e}", file=sys.stderr)
        sys.exit(1)

    app = FastAPI(
        title=settings.api_title,
        description=settings.api_description,
        version=settings.api_version,
        debug=settings.debug,
        lifespan=lifespan,
    )

    # Configure CORS
    if settings.enable_cors:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.api_cors_origins,
            allow_credentials=True,
            allow_methods=settings.api_cors_methods,
            allow_headers=["*"],
        )

    # Add global exception handler for configuration errors
    @app.exception_handler(ConfigurationError)
    async def configuration_error_handler(request, exc: ConfigurationError):
        return JSONResponse(
            status_code=500,
            content={
                "error": "Configuration Error",
                "message": str(exc),
                "type": "configuration_error",
            },
        )

    # Legacy endpoints (no prefix, matching original Flask API)
    app.include_router(legacy_blockchain_router, tags=["blockchain"])
    app.include_router(legacy_health_router, tags=["health"])

    # Modern API endpoints (keeping for future use)
    app.include_router(health_router, prefix="/api/v1", tags=["health"])
    app.include_router(blockchain_router, prefix="/api/v1", tags=["blockchain"])

    return app


app = create_app()


def handler(event, context):
    """AWS Lambda handler."""
    from mangum import Mangum

    handler_instance = Mangum(app)
    return handler_instance(event, context)


if __name__ == "__main__":
    import uvicorn

    # Get settings for uvicorn configuration
    try:
        settings = get_settings()

        uvicorn.run(
            "src.main:app",
            host="0.0.0.0",
            port=8080,
            reload=settings.debug,
            log_level=settings.log_level.lower(),
            access_log=settings.debug,
        )
    except ConfigurationError as e:
        print(f"Configuration Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Startup Error: {e}", file=sys.stderr)
        sys.exit(1)
