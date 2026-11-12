"""
设备管理 API
"""
from fastapi import APIRouter, Depends, HTTPException, WebSocket
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

from ..database import get_db
from ..mqtt_client import mqtt_service

router = APIRouter()


class DeviceBind(BaseModel):
    device_id: str
    user_id: str


class DeviceConfigUpdate(BaseModel):
    light_on_hour: Optional[int] = None
    light_off_hour: Optional[int] = None
    rb_ratio: Optional[int] = None
    auto_water: Optional[bool] = None


class DeviceCommand(BaseModel):
    cmd: str
    params: dict = {}


@router.post("/bind")
async def bind_device(body: DeviceBind, db: AsyncSession = Depends(get_db)):
    from ..database import Device
    result = await db.execute(select(Device).where(Device.device_id == body.device_id))
    device = result.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=404, detail="设备不存在, 请确认设备已联网")
    if device.owner_id and device.owner_id != body.user_id:
        raise HTTPException(status_code=409, detail="设备已被其他用户绑定")
    device.owner_id = body.user_id
    await db.commit()
    return {"code": 0, "message": "绑定成功", "device": {"id": device.id, "name": device.name}}


@router.get("/list")
async def list_devices(user_id: str, db: AsyncSession = Depends(get_db)):
    from ..database import Device
    result = await db.execute(select(Device).where(Device.owner_id == user_id))
    devices = result.scalars().all()
    return {
        "code": 0,
        "data": [
            {
                "id": d.id, "device_id": d.device_id, "name": d.name,
                "online": d.online, "firmware": d.firmware,
                "current_crop": d.current_crop, "plant_day": d.plant_day,
                "last_seen": d.last_seen.isoformat(),
            }
            for d in devices
        ],
    }


@router.put("/{device_id}/config")
async def update_config(device_id: str, body: DeviceConfigUpdate, db: AsyncSession = Depends(get_db)):
    from ..database import Device
    result = await db.execute(select(Device).where(Device.device_id == device_id))
    device = result.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=404, detail="设备不存在")

    cmd = {"cmd": "setSchedule", "onHour": body.light_on_hour, "offHour": body.light_off_hour}
    if body.rb_ratio is not None:
        mqtt_service.publish_command(device_id, {"cmd": "light", "ratio": body.rb_ratio})
    if cmd["onHour"] and cmd["offHour"]:
        mqtt_service.publish_command(device_id, cmd)

    cfg = dict(device.config or {})
    if body.light_on_hour is not None:  cfg["lightOnHour"] = body.light_on_hour
    if body.light_off_hour is not None: cfg["lightOffHour"] = body.light_off_hour
    if body.rb_ratio is not None:       cfg["rbRatio"] = body.rb_ratio
    if body.auto_water is not None:     cfg["autoWater"] = body.auto_water
    device.config = cfg
    await db.commit()
    return {"code": 0, "message": "配置已同步到设备"}


@router.post("/{device_id}/command")
async def send_command(device_id: str, body: DeviceCommand):
    payload = {"cmd": body.cmd, **body.params}
    mqtt_service.publish_command(device_id, payload)
    return {"code": 0, "message": f"指令 {body.cmd} 已下发"}


@router.post("/{device_id}/set-crop")
async def set_crop(device_id: str, crop_id: str, slot: int = 0, db: AsyncSession = Depends(get_db)):
    """设置当前种植品种 - 触发设备进入对应生长模式"""
    from ..database import Device, CropPlan
    from ..ai.crop_catalog import get_crop
    crop = get_crop(crop_id)
    if not crop:
        raise HTTPException(status_code=400, detail="未知品种")

    await db.execute(update(Device).where(Device.device_id == device_id).values(
        current_crop=crop_id, plant_day=0))
    db.add(CropPlan(
        device_id=device_id, crop_id=crop_id, crop_name=crop["name"], slot=slot))
    await db.commit()
    mqtt_service.publish_command(device_id, {"cmd": "setCrop", "cropId": crop_id})
    return {"code": 0, "data": crop}
