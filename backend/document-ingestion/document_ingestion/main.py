import json
import asyncio

from fastapi import FastAPI, Response
from pydantic_settings import BaseSettings

from document_ingestion import __version__


DEFAULT_DB_URL = "postgresql://postgres:postgres@localhost:5432/ingestion"


class Settings(BaseSettings):
    """Application settings."""

    # Use plain PostgreSQL URL format for asyncpg (without +asyncpg driver prefix)
    database_url: str = ""  # Require explicit setting
    redis_url: str = "redis://localhost:6379/1"

    class Config:
        env_file = ".env"


settings = Settings()
app = FastAPI(title="document-ingestion", version=__version__)


def sanitize_error(e: Exception) -> str:
    """Sanitize exception message to avoid leaking sensitive info."""
    msg = str(e).lower()
    # Generic error categories
    if "connection" in msg or "connect" in msg:
        return "connection_failed"
    if "auth" in msg or "password" in msg:
        return "authentication_failed"
    if "timeout" in msg:
        return "timeout"
    if "does not exist" in msg or "no such" in msg:
        return "database_not_found"
    return "error"


@app.get("/livez")
async def liveness():
    """Liveness probe - always returns OK if the service is running."""
    return {"status": "ok"}


@app.get("/readyz")
async def readiness():
    """
    Readiness probe - checks if critical dependencies are available.

    Checks:
    - Database connectivity (PostgreSQL)
    - Redis connectivity
    """
    import asyncpg
    import redis.asyncio as redis

    # Validate required settings
    if not settings.database_url:
        return Response(
            content=json.dumps({"status": "degraded", "checks": {"database": "database_url not set"}}),
            status_code=503,
            media_type="application/json"
        )

    checks = {}

    # Check database with timeout
    try:
        conn = await asyncio.wait_for(
            asyncpg.connect(settings.database_url),
            timeout=5.0
        )
        try:
            await conn.close()
        finally:
            pass
        checks["database"] = "ok"
    except asyncio.TimeoutError:
        checks["database"] = "timeout"
    except Exception as e:
        checks["database"] = sanitize_error(e)

    # Check Redis with timeout and proper cleanup
    try:
        r = redis.from_url(settings.redis_url)
        try:
            await asyncio.wait_for(r.ping(), timeout=5.0)
            checks["redis"] = "ok"
        finally:
            await r.close()
    except asyncio.TimeoutError:
        checks["redis"] = "timeout"
    except Exception as e:
        checks["redis"] = sanitize_error(e)

    all_ok = all(v == "ok" for v in checks.values())

    return Response(
        content=json.dumps({"status": "ok" if all_ok else "degraded", "checks": checks}),
        status_code=200 if all_ok else 503,
        media_type="application/json"
    )


@app.get("/health")
async def health():
    """Legacy health endpoint - alias for liveness."""
    return {"status": "ok"}


def run():
    """CLI entrypoint for uvicorn server."""
    import uvicorn

    uvicorn.run("document_ingestion.main:app", host="0.0.0.0", port=8000)
