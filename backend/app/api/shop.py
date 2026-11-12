"""
商城 API - 设备销售 / 租赁订阅 / 基质板种子 / 会员
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import Optional
import uuid

from ..database import get_db

router = APIRouter()


# ---------- 商品 ----------
@router.get("/products")
async def list_products(category: Optional[str] = None, db: AsyncSession = Depends(get_db)):
    from ..database import Product
    query = select(Product).where(Product.stock > 0)
    if category:
        query = query.where(Product.category == category)
    result = await db.execute(query)
    return {"code": 0, "data": [
        {
            "id": p.id, "name": p.name, "category": p.category,
            "price": p.price, "original_price": p.original_price,
            "images": p.images, "description": p.description, "tags": p.tags,
        }
        for p in result.scalars().all()
    ]}


# ---------- 订单 ----------
class OrderCreate(BaseModel):
    user_id: str
    items: list[dict]          # [{"product_id":..., "qty":1}]
    address: str


@router.post("/orders")
async def create_order(body: OrderCreate, db: AsyncSession = Depends(get_db)):
    from ..database import Product, Order

    total = 0.0
    for item in body.items:
        product = await db.get(Product, item["product_id"])
        if not product:
            raise HTTPException(status_code=404, detail=f"商品 {item['product_id']} 不存在")
        if product.stock < item.get("qty", 1):
            raise HTTPException(status_code=409, detail=f"{product.name} 库存不足")
        total += product.price * item.get("qty", 1)

    order = Order(
        id=str(uuid.uuid4()), user_id=body.user_id,
        items=body.items, total=round(total, 2),
        address=body.address, status="pending")
    db.add(order)
    await db.commit()
    return {"code": 0, "data": {"order_id": order.id, "total": order.total}}


@router.post("/orders/{order_id}/pay")
async def pay_order(order_id: str, db: AsyncSession = Depends(get_db)):
    """支付回调 (微信支付/支付宝) - 生产环境需验签"""
    from ..database import Order, Product
    from sqlalchemy import update

    order = await db.get(Order, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")
    if order.status != "pending":
        raise HTTPException(status_code=409, detail="订单状态不允许支付")

    # 扣减库存
    for item in order.items:
        product = await db.get(Product, item["product_id"])
        if product:
            product.stock -= item.get("qty", 1)

    order.status = "paid"
    await db.commit()
    return {"code": 0, "message": "支付成功"}


# ---------- 租赁订阅 ----------
RENTAL_PLANS = [
    {"id": "basic", "name": "基础版", "price": 99, "devices": 1,
     "includes": ["智能种植机1台", "基础基质板", "4种种子/6个月"]},
    {"id": "standard", "name": "标准版", "price": 199, "devices": 1,
     "includes": ["智能种植机1台", "富硒功能土", "8种种子/6个月", "AI健康建议"]},
    {"id": "premium", "name": "高级版", "price": 399, "devices": 2,
     "includes": ["智能种植机2台", "富硒功能土", "九真十八品全套", "1对1健康咨询/月"]},
    {"id": "custom", "name": "专属定制版", "price": 599, "devices": 0,
     "includes": ["定制种植方案", "专属健康管理师", "每周回访"]},
]


@router.get("/rental-plans")
async def rental_plans():
    return {"code": 0, "data": RENTAL_PLANS}
