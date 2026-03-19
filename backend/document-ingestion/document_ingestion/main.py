from fastapi import FastAPI
from pydantic_settings import BaseSettings

from document_ingestion import __version__


class Settings(BaseSettings):
    """Application settings."""

    database_url: str = "postgresql+asyncpg://localhost/ingestion"
    redis_url: str = "redis://localhost:6379/1"

    class Config:
        env_file = ".env"


settings = Settings()
app = FastAPI(title="document-ingestion", version=__version__)


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
        checks["database"] = f"error: {str(e)}"

    # Check Redis
    try:
        r = redis.from_url(settings.redis_url)
        await r.ping()
        await r.close()
        checks["redis"] = "ok"
    except Exception as e:
        checks["redis"] = f"error: {str(e)}"

    all_ok = all(v == "ok" for v in checks.values())
    status_code = 200 if all_ok else 503

    return {"status": "ok" if all_ok else "degraded", "checks": checks}


@app.get("/health")
async def health():
    """Legacy health endpoint - alias for liveness."""
    return {"status": "ok"}


def run():
    """CLI entrypoint for uvicorn server."""
    import uvicorn

    uvicorn.run("document_ingestion.main:app", host="0.0.0.0", port=8000)
