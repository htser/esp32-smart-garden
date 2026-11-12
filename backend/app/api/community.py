"""
社区模块 API - 群集管理的数据基础
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from pydantic import BaseModel
from typing import Optional

from ..database import get_db

router = APIRouter()


class CommunityCreate(BaseModel):
    name: str
    city: str = ""
    address: str = ""


class PostCreate(BaseModel):
    user_id: str
    content: str
    images: list[str] = []
    crop_tags: list[str] = []


@router.post("")
async def create_community(body: CommunityCreate, db: AsyncSession = Depends(get_db)):
    from ..database import Community
    import uuid
    community = Community(
        id=str(uuid.uuid4()), name=body.name, city=body.city, address=body.address)
    db.add(community)
    await db.commit()
    return {"code": 0, "data": {"id": community.id, "name": community.name}}


@router.get("")
async def list_communities(city: Optional[str] = None, db: AsyncSession = Depends(get_db)):
    from ..database import Community
    query = select(Community)
    if city:
        query = query.where(Community.city == city)
    result = await db.execute(query)
    return {"code": 0, "data": [
        {"id": c.id, "name": c.name, "city": c.city,
         "device_count": c.device_count, "member_count": c.member_count}
        for c in result.scalars().all()
    ]}


@router.get("/{community_id}/stats")
async def community_stats(community_id: str, db: AsyncSession = Depends(get_db)):
    """社区健康群集统计 - 匿名化聚合"""
    from ..database import Community, User, Device, HealthLog
    from sqlalchemy import func as f

    member_count = await db.scalar(
        select(f.count(User.id)).where(User.community_id == community_id))
    device_count = await db.scalar(
        select(f.count(Device.id)).join(User, User.id == Device.owner_id)
        .where(User.community_id == community_id))

    # 社区热门种植品种
    hot_crops = await db.execute(
        select(Device.current_crop, f.count(Device.id).label("cnt"))
        .join(User, User.id == Device.owner_id)
        .where(User.community_id == community_id)
        .group_by(Device.current_crop)
        .order_by(f.count(Device.id).desc())
        .limit(5)
    )
    return {
        "code": 0,
        "data": {
            "member_count": member_count or 0,
            "device_count": device_count or 0,
            "hot_crops": [{"crop": r[0], "count": r[1]} for r in hot_crops.all()],
        },
    }


@router.get("/{community_id}/posts")
async def community_posts(community_id: str, page: int = 1, size: int = 20):
    # 生产环境: 从 posts 表分页查询
    return {"code": 0, "data": {"list": [], "total": 0, "page": page, "size": size}}
