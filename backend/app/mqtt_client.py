"""
MQTT 客户端 - 订阅设备遥测数据, 写入 InfluxDB, 广播到 WebSocket
"""
import json
import ssl
import asyncio
import logging
from typing import Callable, Awaitable

import paho.mqtt.client as mqtt

from .config import settings

logger = logging.getLogger("zhigu.mqtt")


class MQTTService:
    def __init__(self):
        self.client = mqtt.Client(
            client_id="zhigu-backend",
            clean_session=True,
            protocol=mqtt.MQTTv311,
        )
        self.client.on_connect = self._on_connect
        self.client.on_message = self._on_message
        self._handlers: dict[str, Callable[[str, dict], Awaitable[None]]] = {}
        self._dev_lock = None

    def _on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            logger.info("MQTT connected")
            client.subscribe([("zhigu/+/telemetry", 1), ("zhigu/+/health", 1), ("zhigu/+/status", 1)])
        else:
            logger.error("MQTT connect failed rc=%d", rc)

    def _on_message(self, client, userdata, msg):
        try:
            parts = msg.topic.split("/")
            device_id, channel = parts[1], parts[2]
            payload = json.loads(msg.payload.decode())
            asyncio.run_coroutine_threadsafe(
                self._dispatch(device_id, channel, payload),
                self._loop,
            )
        except Exception as e:
            logger.error("MQTT message error: %s", e)

    async def _ensure_device(self, device_id: str, online: bool = None):
        """设备第一次上报时自动建档(本地联调时直接绑到 demo 用户, App 里就能看到)"""
        import uuid
        from datetime import datetime
        from sqlalchemy import select
        from sqlalchemy.exc import IntegrityError
        from .database import async_session, Device

        if self._dev_lock is None:          # 在事件循环内创建, 避免跨 loop 绑定
            self._dev_lock = asyncio.Lock()
        async with self._dev_lock:          # status/telemetry 可能并发到达, 避免重复建档
            async with async_session() as db:
                row = await db.execute(select(Device).where(Device.device_id == device_id))
                dev = row.scalar_one_or_none()
                if dev is None:
                    dev = Device(
                        id=str(uuid.uuid4()),
                        device_id=device_id,
                        name="我的智菇小站",
                        owner_id=settings.demo_user_id or None,
                    )
                    db.add(dev)
                    try:
                        await db.commit()
                        logger.info("new device registered: %s", device_id)
                        dev = (await db.execute(
                            select(Device).where(Device.device_id == device_id)
                        )).scalar_one()
                    except IntegrityError:
                        await db.rollback()
                        dev = (await db.execute(
                            select(Device).where(Device.device_id == device_id)
                        )).scalar_one()
                if online is not None:
                    dev.online = online
                dev.last_seen = datetime.utcnow()
                await db.commit()
                return dev

    async def _dispatch(self, device_id: str, channel: str, payload: dict):
        from .database import telemetry_store

        if channel == "telemetry":
            await self._ensure_device(device_id)
            await telemetry_store.write_point(
                device_id, "environment",
                {
                    "soil": payload.get("soil", 0),
                    "air_temp": payload.get("airTemp", 0),
                    "air_humidity": payload.get("airHum", 0),
                    "lux": payload.get("lux", 0),
                    "water": payload.get("water", 0),
                },
            )
            # WebSocket 广播
            try:
                from .main import manager
                await manager.broadcast(device_id, {"type": "telemetry", "data": payload})
            except Exception:
                pass

        elif channel == "status":
            await self._ensure_device(device_id, online=payload.get("state") == "online")

    async def connect(self):
        self._loop = asyncio.get_running_loop()
        if settings.mqtt_tls:
            # 本地 broker 是自签证书: 只加密不校验链
            self.client.tls_set(cert_reqs=ssl.CERT_NONE)
            self.client.tls_insecure_set(True)
        self.client.username_pw_set(settings.mqtt_user, settings.mqtt_pass)
        self.client.connect_async(settings.mqtt_host, settings.mqtt_port, keepalive=60)
        self.client.loop_start()

    async def disconnect(self):
        self.client.loop_stop()
        self.client.disconnect()

    # ---------- 指令下发 ----------
    def publish_command(self, device_id: str, command: dict):
        topic = f"zhigu/{device_id}/command"
        self.client.publish(topic, json.dumps(command), qos=1)


mqtt_service = MQTTService()
