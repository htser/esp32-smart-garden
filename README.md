# 智菇小站 AI智能家庭小菜园

面向城市小户型家庭的智能种植产品。核心创新：**生物质基质板 + 富硒矿物质土**替代水培，结合AI智能管理，以东北「九真十八品」为特色品类，针对慢病患者提供定制化种植方案，形成「改善畅通群集管理」健康管理商业模式。

## 项目结构

```
smart-garden/
├── firmware/                      # 嵌入式固件
│   └── zhigu-station/
│       ├── zhigu-station.ino      # ESP32-S3 主固件
│       └── platformio.ini         # PlatformIO 配置
├── backend/                       # 后端服务
│   └── app/
│       ├── main.py                # FastAPI 入口
│       ├── config.py              # 环境配置
│       ├── database.py            # PostgreSQL + InfluxDB
│       ├── mqtt_client.py         # EMQX MQTT 订阅
│       ├── api/
│       │   ├── devices.py         # 设备管理 API
│       │   ├── telemetry.py       # 种植数据 API
│       │   ├── ai.py              # AI 识别/推荐 API
│       │   ├── community.py       # 社区 API
│       │   └── shop.py            # 商城/租赁 API
│       └── ai/
│           ├── crop_catalog.py    # 九真十八品 + 慢病方案库
│           ├── vision.py          # 品种识别 + 病虫害检测
│           └── recommender.py     # 慢病推荐引擎
├── mobile-app/                    # Flutter 移动端
│   └── lib/
│       ├── main.dart              # 入口 + 底部导航
│       ├── config/                # 应用配置
│       ├── services/              # API 服务层
│       ├── providers/             # 状态管理
│       └── ui/
│           ├── screens/           # 5大页面
│           ├── widgets/           # 复用组件
│           └── theme/             # 主题
└── docs/                          # 文档
```

## 硬件清单

| 组件      | 型号                       | 接口              | 数量  |
| ------- | ------------------------ | --------------- | --- |
| 主控      | ESP32-S3-WROOM-1 (N16R8) | -               | 1   |
| 土壤湿度传感器 | 电容式                      | ADC (GPIO34-39) | 6   |
| 温湿度传感器  | DHT22 + AHT20            | GPIO4 / I2C     | 2   |
| 气压传感器   | BMP280                   | I2C             | 1   |
| 光照传感器   | BH1750                   | I2C             | 1   |
| LED生长灯  | WS2812B 全光谱              | GPIO2 PWM       | 48颗 |
| 微型水泵    | 5V 静音泵                   | GPIO12 + 继电器    | 1   |
| 触控屏     | ILI9488 4.3寸             | SPI             | 1   |
| 摄像头     | OV2640                   | DVP             | 1   |
| 电池      | 5000mAh 锂电 + TP4056      | -               | 1   |

## 快速开始

### 1. 固件烧录

```bash
cd firmware/zhigu-station
pio run -t upload          # 烧录固件
pio device monitor         # 查看串口日志
```

### 2. 后端部署

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
docker-compose up -d postgres influxdb redis emqx    # 基础设施
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 3. 移动端运行

```bash
cd mobile-app
flutter pub get
flutter run                # 连接真机/模拟器
```

## 核心功能

| 模块       | 功能                            |
| -------- | ----------------------------- |
| **智能种植** | 环境自动调控（光照/温湿度/水分）、生长阶段追踪、收获提醒 |
| **AI识别** | 品种识别（50+）、病虫害检测（12类）、生长阶段判定   |
| **慢病方案** | 糖尿病/高血压/高血脂/胃病/失眠/免疫 6大定制方案   |
| **群集管理** | 个人→家庭→社区三层健康数据管理              |
| **社区运营** | 社区种植站、邻里动态、社区团购               |
| **商城**   | 设备销售、4档租赁订阅、基质板/种子补给          |

## 商业模式

- **社区种植站**：以社区为单位，50-100台设备/站，服务2000-5000户
- **家庭租赁**：99-599元/月四档订阅
- **利润分配**：用户10-15% / 社区合伙人25-35% / 平台20-25% / 供应链20-30%

## API 概览

```
POST   /api/v1/devices/bind                    设备绑定
GET    /api/v1/devices/list                    设备列表
POST   /api/v1/devices/{id}/command            指令下发
POST   /api/v1/devices/{id}/set-crop           设置品种
GET    /api/v1/telemetry/{id}/current          实时环境数据
GET    /api/v1/telemetry/{id}/trend            历史趋势
POST   /api/v1/ai/recognize                    品种识别
POST   /api/v1/ai/detect-disease               病虫害检测
POST   /api/v1/ai/recommend-crops              个性化推荐
POST   /api/v1/ai/health-advice                健康建议
GET    /api/v1/shop/products                   商品列表
GET    /api/v1/shop/rental-plans               租赁方案
WS     /ws/telemetry/{device_id}               实时推送
```

## 安全与合规

- 全链路 TLS 加密（MQTT over TLS 8883）
- JWT 鉴权 + 设备证书双向认证
- 健康数据匿名化处理，符合《个人信息保护法》
- 富硒含量符合国家富硒农产品标准（0.15-0.25mg/kg）

## 免责声明

慢病种植方案仅供饮食辅助参考，不替代药物治疗。用户应遵医嘱使用。
