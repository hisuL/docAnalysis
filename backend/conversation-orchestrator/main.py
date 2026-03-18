from fastapi import FastAPI

app = FastAPI(title="conversation-orchestrator", version="1.0.0")

@app.get("/health")
async def health():
    return {"status": "ok"}
