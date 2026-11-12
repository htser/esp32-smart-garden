# 本地联调环境

不装 PostgreSQL / InfluxDB / Redis / EMQX，用最少的组件把「设备 → Broker → 后端 → App」这条链路跑通。

## 组成

| 组件 | 说明 | 端口 |
|---|---|---|
| `broker.py` | 纯标准库实现的 MQTT 3.1.1 Broker（CONNECT/SUB/PUB QoS0-1/保留消息/通配符），带自签 TLS | 1883 明文 / 8883 TLS |
| `certs/` | 自签 CA + 服务端证书（固件里 `setInsecure()`，不校验证书） | - |
| `simulate_device.py` | 模拟一台设备，每 15 秒上报遥测 | - |
| `app/` | 原 FastAPI 后端，改成：SQLite 代替 PG、内存代替 InfluxDB、设备首次上线自动建档并绑到 demo 用户 | 8000 |

## 启动

```bash
cd backend
python3 -m venv .venv && ./.venv/bin/pip install -r local_dev/requirements-local.txt
cp .env.example .env              # 已经给你放了一份

# 1. MQTT Broker
./.venv/bin/python local_dev/broker.py

# 2. 后端 (另开一个终端; 首次启动要 30s 左右, 因为要 import numpy/AI 模块)
./.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000

# 3. 没有硬件时, 用模拟设备验证链路
./.venv/bin/python local_dev/simulate_device.py
```

## 验证

```bash
curl http://127.0.0.1:8000/health
curl "http://127.0.0.1:8000/api/v1/devices/list?user_id=u_8829103"
curl "http://127.0.0.1:8000/api/v1/telemetry/ZG-SIM0001/current"
curl "http://127.0.0.1:8000/api/v1/telemetry/ZG-SIM0001/trend?field=soil&hours=24"
```

App 端：`mobile-app/lib/config/app_config.dart` 里的默认地址已经是本机
`http://<电脑IP>:8000`，也可以用 `flutter run --dart-define=API_BASE=http://x.x.x.x:8000` 覆盖。

## 与生产的差异（上线前要换掉的部分）

- `broker.py` 只够联调：没有认证、没有 QoS2、没有集群；生产用 EMQX。
- `.env` 里 `INFLUX_URL` 留空 = 遥测只存在内存里，重启即丢；生产接 InfluxDB。
- `DATABASE_URL` 用 SQLite；生产是 `postgresql+asyncpg://...`。
- 设备首次上线自动绑到 `DEMO_USER_ID`，这是联调便利，生产要走 `POST /api/v1/devices/bind`。

## 接真机（ESP32）

固件启动后 10 秒内，串口里发送一行就能配网，不用重新烧录：

```
wifi 你的SSID 你的密码
```

- 密码里有空格请换成 2.4GHz 热点/路由，ESP32 不支持 5GHz。
- 这条命令只对本次运行生效（关机丢失）；持久化存储有个 NVS 写入异常待查（见根目录 issue 记录）。
- 连上后固件会去连 `MQTT_HOST_DEFAULT`（`firmware/zhigu-station/zhigu-station.ino` 顶部）
  指向的 8883 TLS 端口，也就是本机 `local_dev/broker.py`。

验证设备是否上报：

```bash
# broker 日志里应看到 PUB zhigu/ZG-xxxx/telemetry ...
tail -f /tmp/broker.log
curl "http://127.0.0.1:8000/api/v1/devices/list?user_id=u_8829103"
```

## 设备配网（产品流程，不是串口）

真机不需要串口，走 **SoftAP + 内嵌网页**：

1. 设备上电，NVS 里没有 WiFi → 广播热点 `ZHIGU-XXXX`（密码 `12345678`），同时跑一个 WebServer + DNS 劫持（强制门户）。
2. 手机连上这个热点，打开 `http://192.168.4.1`（或任意网址都会被劫持过去）。
3. 页面里选 WiFi、填密码 → `POST /api/provision {ssid, pass}` → 设备写 NVS、重启、连路由器。
4. 连不上（密码错/路由器不在）会自动回到配网热点。

设备端 HTTP 接口：

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/` | 配网页面（手机浏览器直接可用） |
| GET | `/api/info` | `{model, deviceId, version, ap, state}` |
| GET | `/api/scan` | `{networks:[{ssid,rssi,enc}]}` |
| POST | `/api/provision` | `{ssid, pass}` → `{ok:true, deviceId}`，随后重启 |

App 里的入口：我的 → 设置 → **设备配网**（`mobile-app/lib/ui/screens/provision_screen.dart`）。

### 60 秒自测（不用装 App）

```bash
# 1. 手机连热点 ZHIGU-xxxx（密码 12345678）
# 2. 浏览器打开 http://192.168.4.1 ，选 WiFi 填密码，点“连接并保存”
# 3. 手机连回原来的 WiFi，等 15 秒
tail -f /tmp/broker.log          # 应出现 PUB zhigu/ZG-xxxx/telemetry
curl "http://<电脑IP>:8000/api/v1/devices/list?user_id=u_8829103"
```
