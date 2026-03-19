from fastapi import FastAPI, Response
from pydantic_settings import BaseSettings

from conversation_orchestrator import __version__


class Settings(BaseSettings):
    """Application settings."""

    # Use plain PostgreSQL URL format for asyncpg (without +asyncpg driver prefix)
    database_url: str = "postgresql://postgres:postgres@localhost:5432/orchestrator"
    redis_url: str = "redis://localhost:6379/0"

    class Config:
        env_file = ".env"


settings = Settings()
app = FastAPI(title="conversation-orchestrator", version=__version__)


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

    checks = {}

    # Check database
    try:
        conn = await asyncpg.connect(settings.database_url)
        await conn.close()
        checks["database"] = "ok"
    except Exception as e:
        checks["database"] = sanitize_error(e)

    # Check Redis
    try:
        r = redis.from_url(settings.redis_url)
        await r.ping()
        await r.close()
        checks["redis"] = "ok"
    except Exception as e:
        checks["redis"] = sanitize_error(e)

    all_ok = all(v == "ok" for v in checks.values())

    return Response(
        content='{"status": "' + ("ok" if all_ok else "degraded") + '", "checks": ' + str(checks).replace("'", '"') + '}',
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

    uvicorn.run("conversation_orchestrator.main:app", host="0.0.0.0", port=8000)
