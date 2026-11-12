"""
AI API - 植物识别 / 病虫害检测 / 慢病推荐 / 健康建议
"""
from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from pydantic import BaseModel
from typing import Optional

from ..ai.vision import plant_recognizer, disease_detector, growth_classifier
from ..ai.crop_catalog import (
    JIu_ZHEN_18_PIN, CHRONIC_PLANS, get_crop, get_plan,
    all_crops, crops_by_plan,
)
from ..ai.recommender import HealthRecommender

router = APIRouter()
recommender = HealthRecommender()


# ---------- 视觉识别 ----------
@router.post("/recognize")
async def recognize_plant(file: UploadFile = File(...)):
    """上传图片 -> 识别种植品种"""
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="仅支持图片文件")
    image_bytes = await file.read()
    result = plant_recognizer.predict(image_bytes)
    if result.get("code") == 0 and result["data"]:
        top = result["data"][0]
        crop = get_crop(top["class"])
        if crop:
            result["crop_info"] = {"id": top["class"], "name": crop["name"], "zhen": crop["zhen"]}
    return result


@router.post("/detect-disease")
async def detect_disease(file: UploadFile = File(...)):
    """上传叶片照片 -> 病虫害诊断"""
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="仅支持图片文件")
    image_bytes = await file.read()
    return disease_detector.detect(image_bytes)


# ---------- 品种与方案库 ----------
@router.get("/crops")
async def list_crops(zhen: Optional[str] = None):
    """九真十八品品种列表"""
    crops = all_crops()
    if zhen:
        crops = [c for c in crops if c.get("zhen") == zhen]
    return {"code": 0, "data": crops}


@router.get("/plans")
async def list_plans():
    """慢病定制化种植方案列表"""
    return {
        "code": 0,
        "data": [
            {"id": k, "name": v["name"], "crop_count": len(v["crops"]),
             "disclaimer": v["disclaimer"]}
            for k, v in CHRONIC_PLANS.items()
        ],
    }


@router.get("/plans/{plan_id}")
async def get_plan_detail(plan_id: str):
    plan = get_plan(plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="方案不存在")
    return {"code": 0, "data": plan}


@router.get("/plans/{plan_id}/crops")
async def get_plan_crops(plan_id: str):
    return {"code": 0, "data": crops_by_plan(plan_id)}


# ---------- 个性化推荐 ----------
class ProfileIn(BaseModel):
    age: int
    gender: str = "unknown"
    height_cm: float = 170
    weight_kg: float = 65
    conditions: list[str] = []            # ["diabetes","hypertension"]
    diagnosed_conditions: list[str] = []  # 已确诊病种(指标缺省时按确诊层管理)
    # 检查指标(分层引擎V2): fpg/ppg/hba1c, sbp/dbp, tc/tg/ldl/hdl,
    #                    symptom_score(0-5), sleep_latency(分钟), cold_freq(次/年)
    labs: dict = {}
    bmi: Optional[float] = None
    fasting_glucose: Optional[float] = None      # 兼容旧字段
    blood_pressure: Optional[list[int]] = None   # 兼容旧字段 [148, 92]


@router.post("/recommend-crops")
async def recommend_crops(profile: ProfileIn):
    """根据健康档案推荐种植组合"""
    return {
        "code": 0,
        "data": recommender.recommend_crops(profile.dict()),
    }


@router.post("/health-advice")
async def health_advice(profile: ProfileIn, device_id: str = Query(...)):
    """生成个性化健康建议 - 结合当前种植状态"""
    from ..database import async_session
    from ..database import Device
    from sqlalchemy import select

    async with async_session() as db:
        result = await db.execute(select(Device).where(Device.device_id == device_id))
        device = result.scalar_one_or_none()

    context = {
        "profile": profile.dict(),
        "current_crop": device.current_crop if device else None,
        "plant_day": device.plant_day if device else 0,
    }
    return {"code": 0, "data": recommender.generate_advice(context)}


# ---------- 生长阶段 ----------
@router.get("/growth-stage")
async def growth_stage(plant_day: int, crop_id: str):
    crop = get_crop(crop_id)
    if not crop:
        raise HTTPException(status_code=404, detail="品种不存在")
    return {"code": 0, "data": growth_classifier.classify(plant_day, crop)}
