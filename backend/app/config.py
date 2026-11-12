"""
配置管理 - 环境变量注入
"""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # 数据库
    database_url: str = "postgresql+asyncpg://zhigu:zhigu@localhost:5432/zhigu"
    influx_url: str = "http://localhost:8086"
    influx_token: str = ""
    influx_org: str = "zhigu"
    influx_bucket: str = "telemetry"
    redis_url: str = "redis://localhost:6379/0"

    # MQTT
    mqtt_host: str = "localhost"
    mqtt_port: int = 8883
    mqtt_user: str = "zhigu"
    mqtt_pass: str = "zhigu"
    mqtt_tls: bool = False

    # 本地联调
    demo_user_id: str = "u_8829103"   # 设备首次上线自动绑到这个用户, App 里就能看到

    # AI
    plant_model_path: str = "app/ai/models/plant_mobilenetv3.tflite"
    disease_model_path: str = "app/ai/models/disease_resnet18.pt"
    use_local_inference: bool = True

    # JWT
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 7

    class Config:
        env_file = ".env"


settings = Settings()
