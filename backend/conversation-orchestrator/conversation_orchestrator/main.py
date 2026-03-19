from fastapi import FastAPI, status
from fastapi.responses import JSONResponse

app = FastAPI(title="conversation-orchestrator", version="1.0.0")


@app.get("/livez")
async def liveness():
    """Liveness probe - always returns OK if the service is running."""
    return {"status": "ok"}


@app.get("/readyz")
async def readiness():
    """
    Readiness probe - checks if critical dependencies are available.

    Currently returns OK unconditionally. In production, this should check:
    - Database connectivity (PostgreSQL)
    - Redis connectivity
    """
    # TODO: Add actual dependency health checks
    return {"status": "ok"}


@app.get("/health")
async def health():
    """Legacy health endpoint - alias for liveness."""
    return {"status": "ok"}


def run():
    """CLI entrypoint for uvicorn server."""
    import uvicorn
    uvicorn.run("conversation_orchestrator.main:app", host="0.0.0.0", port=8000)
