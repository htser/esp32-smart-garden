"""
智菇小站 - 后端服务
FastAPI + PostgreSQL + InfluxDB + Redis + EMQX
"""
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import json
import logging
from datetime import datetime

from .database import init_db, get_db
from .mqtt_client import mqtt_service
from .api import devices, telemetry, ai, community, shop
from .config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("zhigu")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting Zhigu backend ...")
    await init_db()
    await mqtt_service.connect()
    yield
    await mqtt_service.disconnect()
    logger.info("Zhigu backend stopped")


app = FastAPI(
    title="智菇小站 AI智能家庭小菜园",
    description="设备管理 · 种植数据 · AI识别 · 慢病推荐 · 社区运营",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(devices.router,  prefix="/api/v1/devices",  tags=["设备管理"])
app.include_router(telemetry.router, prefix="/api/v1/telemetry", tags=["种植数据"])
app.include_router(ai.router,       prefix="/api/v1/ai",       tags=["AI引擎"])
app.include_router(community.router, prefix="/api/v1/community", tags=["社区"])
app.include_router(shop.router,     prefix="/api/v1/shop",     tags=["商城"])


@app.get("/health")
async def health():
    return {"status": "ok", "ts": datetime.utcnow().isoformat()}


# ---------- WebSocket: 实时推送种植数据到 App ----------
class ConnectionManager:
    def __init__(self):
        self.active: dict[str, list[WebSocket]] = {}

    async def connect(self, device_id: str, ws: WebSocket):
        await ws.accept()
        self.active.setdefault(device_id, []).append(ws)

    def disconnect(self, device_id: str, ws: WebSocket):
        if device_id in self.active:
            self.active[device_id].remove(ws)

    async def broadcast(self, device_id: str, message: dict):
        for ws in self.active.get(device_id, []):
            try:
                await ws.send_json(message)
            except Exception:
                pass


manager = ConnectionManager()


@app.websocket("/ws/telemetry/{device_id}")
async def telemetry_ws(websocket: WebSocket, device_id: str):
    await manager.connect(device_id, websocket)
    try:
        while True:
            await websocket.receive_text()  # 保持心跳
    except WebSocketDisconnect:
        manager.disconnect(device_id, websocket)
