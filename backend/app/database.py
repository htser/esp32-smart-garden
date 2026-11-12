"""
数据库层 - SQLAlchemy 异步模型 + InfluxDB 时序存储
"""
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, ForeignKey, Text, JSON
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base, relationship
from datetime import datetime, timedelta

from .config import settings

Base = declarative_base()


# ---------- ORM 模型 ----------
class User(Base):
    __tablename__ = "users"
    id = Column(String(36), primary_key=True)
    phone = Column(String(20), unique=True, index=True)
    nickname = Column(String(64))
    avatar = Column(String(256), default="")
    health_profile = Column(JSON, default=dict)   # 身高/体重/血糖/血压/过敏原等
    community_id = Column(String(36), ForeignKey("communities.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    devices = relationship("Device", back_populates="owner")


class Device(Base):
    __tablename__ = "devices"
    id = Column(String(36), primary_key=True)
    device_id = Column(String(24), unique=True, index=True)   # ZG-XXXX
    name = Column(String(64), default="我的智菇小站")
    model = Column(String(32), default="ZHIGU-S1")
    firmware = Column(String(16), default="1.0.0")
    online = Column(Boolean, default=False)
    owner_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    config = Column(JSON, default=dict)  # lightOnHour/lightOffHour/rbRatio/autoWater
    current_crop = Column(String(24), default="")
    plant_day = Column(Integer, default=0)
    last_seen = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="devices")


class Community(Base):
    __tablename__ = "communities"
    id = Column(String(36), primary_key=True)
    name = Column(String(128))
    city = Column(String(64))
    address = Column(String(256))
    partner_id = Column(String(36), nullable=True)      # 社区合伙人
    device_count = Column(Integer, default=0)
    member_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)


class CropPlan(Base):
    """种植计划: 用户选择的品种与种植进度"""
    __tablename__ = "crop_plans"
    id = Column(String(36), primary_key=True)
    device_id = Column(String(24), index=True)
    crop_id = Column(String(24), index=True)             # 对应九真十八品/慢病方案
    crop_name = Column(String(64))
    slot = Column(Integer)                                # 种植位 0-7
    started_at = Column(DateTime, default=datetime.utcnow)
    harvest_at = Column(DateTime, nullable=True)
    stage = Column(String(16), default="seed")           # seed/sprout/growth/harvest
    status = Column(String(16), default="growing")       # growing/harvested/failed
    notes = Column(Text, default="")


class HealthLog(Base):
    """用户健康日志 - 群集管理的数据基础"""
    __tablename__ = "health_logs"
    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), index=True)
    log_type = Column(String(24))    # meal/symptom/mood/sleep/exercise
    value = Column(JSON)             # {"calories":450,"foods":[...]} 等
    recorded_at = Column(DateTime, default=datetime.utcnow)


class Product(Base):
    __tablename__ = "products"
    id = Column(String(36), primary_key=True)
    name = Column(String(128))
    category = Column(String(32))    # device/rental/substrate/seed/membership
    price = Column(Float)
    original_price = Column(Float, nullable=True)
    stock = Column(Integer, default=0)
    images = Column(JSON, default=list)
    description = Column(Text, default="")
    tags = Column(JSON, default=list)


class Order(Base):
    __tablename__ = "orders"
    id = Column(String(36), primary_key=True)
    user_id = Column(String(36))
    items = Column(JSON)
    total = Column(Float)
    status = Column(String(16), default="pending")   # pending/paid/shipped/done
    address = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)


# ---------- 引擎 ----------
# PostgreSQL 用连接池；本地开发用 SQLite 时不支持这些 pool 参数
_engine_kwargs = {"echo": False}
if not settings.database_url.startswith("sqlite"):
    _engine_kwargs.update(pool_size=10, max_overflow=20)
engine = create_async_engine(settings.database_url, **_engine_kwargs)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def get_db():
    async with async_session() as session:
        yield session


# ---------- 时序存储: InfluxDB 或本地内存 ----------
class TelemetryStore:
    """种植环境时序数据。

    - 配了 influx_url  -> 写/查 InfluxDB
    - 没配 influx_url  -> 退回进程内内存(重启即失), 仅供本地联调
    """

    MEM_LIMIT = 20000

    def __init__(self):
        self._client = None
        self._mem = {}          # {(device_id, measurement): [{"ts": datetime, "fields": {...}}]}

    @property
    def _use_influx(self) -> bool:
        return bool(settings.influx_url)

    async def write_point(self, device_id: str, measurement: str, fields: dict, tags: dict = None):
        if not self._use_influx:
            bucket = self._mem.setdefault((device_id, measurement), [])
            bucket.append({
                "ts": datetime.utcnow(),
                "fields": {k: float(v) for k, v in fields.items()},
            })
            if len(bucket) > self.MEM_LIMIT:
                del bucket[: len(bucket) - self.MEM_LIMIT]
            return

        from influxdb_client import InfluxDBClient, Point
        from influxdb_client.client.write_api import SYNCHRONOUS
        if self._client is None:
            self._client = InfluxDBClient(
                url=settings.influx_url, token=settings.influx_token, org=settings.influx_org)
        point = Point(measurement).tag("device_id", device_id)
        for k, v in (tags or {}).items():
            point = point.tag(k, str(v))
        for k, v in fields.items():
            point = point.field(k, float(v))
        write_api = self._client.write_api(write_options=SYNCHRONOUS)
        write_api.write(bucket=settings.influx_bucket, record=point)

    async def query_last_hours(self, device_id: str, measurement: str, field: str, hours: int = 24):
        if not self._use_influx:
            bucket = self._mem.get((device_id, measurement), [])
            cutoff = datetime.utcnow() - timedelta(hours=hours)
            return [
                {"ts": p["ts"].isoformat(), "value": p["fields"].get(field)}
                for p in bucket
                if p["ts"] >= cutoff and field in p["fields"]
            ]

        from influxdb_client import InfluxDBClient
        if self._client is None:
            self._client = InfluxDBClient(
                url=settings.influx_url, token=settings.influx_token, org=settings.influx_org)
        query_api = self._client.query_api()
        flux = f'''
        from(bucket: "{settings.influx_bucket}")
          |> range(start: -{hours}h)
          |> filter(fn: (r) => r["_measurement"] == "{measurement}"
              and r["device_id"] == "{device_id}"
              and r["_field"] == "{field}")
          |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
        '''
        tables = query_api.query(flux)
        return [{"ts": rec.get_time().isoformat(), "value": rec.get_value()}
                for table in tables for rec in table.records]


telemetry_store = TelemetryStore()
