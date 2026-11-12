"""
种植数据 API - 遥测查询、趋势、生长进度
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import Optional

from ..database import get_db, telemetry_store

router = APIRouter()


@router.get("/{device_id}/current")
async def get_current(device_id: str):
    """设备最新环境数据 - 优先从 InfluxDB 最近一条读取"""
    try:
        data = {
            "soil": await telemetry_store.query_last_hours(device_id, "environment", "soil", 1),
            "air_temp": await telemetry_store.query_last_hours(device_id, "environment", "air_temp", 1),
            "air_humidity": await telemetry_store.query_last_hours(device_id, "environment", "air_humidity", 1),
            "lux": await telemetry_store.query_last_hours(device_id, "environment", "lux", 1),
            "water": await telemetry_store.query_last_hours(device_id, "environment", "water", 1),
        }
        latest = {k: (v[-1]["value"] if v else None) for k, v in data.items()}
        # App(DeviceProvider._applyTelemetry) 读的是驼峰字段, 这里同时给出, 免得刷新时显示 0
        latest.update({
            "airTemp": latest.get("air_temp"),
            "airHum": latest.get("air_humidity"),
        })
        return {"code": 0, "data": latest}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"时序库查询失败: {e}")


@router.get("/{device_id}/trend")
async def get_trend(device_id: str, field: str = "soil", hours: int = 24):
    valid_fields = {"soil", "air_temp", "air_humidity", "lux", "water"}
    if field not in valid_fields:
        raise HTTPException(status_code=400, detail=f"不支持的数据字段: {field}")
    try:
        rows = await telemetry_store.query_last_hours(device_id, "environment", field, hours)
        return {"code": 0, "data": rows}
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@router.get("/{device_id}/plans")
async def get_plans(device_id: str, db: AsyncSession = Depends(get_db)):
    from ..database import CropPlan
    result = await db.execute(
        select(CropPlan).where(CropPlan.device_id == device_id).order_by(CropPlan.started_at.desc())
    )
    plans = result.scalars().all()
    return {
        "code": 0,
        "data": [
            {
                "id": p.id, "crop_id": p.crop_id, "crop_name": p.crop_name,
                "slot": p.slot, "stage": p.stage, "status": p.status,
                "started_at": p.started_at.isoformat(),
                "harvest_at": p.harvest_at.isoformat() if p.harvest_at else None,
            }
            for p in plans
        ],
    }
