# 线上部署（39.105.145.255）

| 项目 | 值 |
|---|---|
| 服务器 | 39.105.145.255（Debian 11，Python 3.9） |
| 目录 | `/www/tmprojects/qd-xiaocaiyuan/backend` |
| 运行用户 | `www` |
| API 端口 | **18000**（`http://39.105.145.255:18000`） |
| MQTT 明文 | **21883** |
| MQTT TLS | **23883**（固件连这个） |
| 数据库 | SQLite `/www/tmprojects/qd-xiaocaiyuan/data/zhigu.db` |
| 时序库 | 内存（重启即清空） |
| 服务 | `qd-mqtt.service`、`qd-api.service`（systemd，开机自启） |

> ⚠️ 机器上已经有 EMQX 占着 1883/8883，所以这里改用 21883/23883，互不影响。
> 以后要换成 EMQX，把 `.env` 里的 `MQTT_PORT` 改成 EMQX 的端口即可（broker.py 只用于自建轻量场景）。

## 常用命令

```bash
systemctl status qd-mqtt qd-api
systemctl restart qd-api          # 改完代码重启
journalctl -u qd-api -f           # 看后端日志
journalctl -u qd-mqtt -f          # 看 MQTT 日志（每条 PUB/SUB 都有）
ss -lntp | grep -E '18000|21883|23883'
```

## 目录结构

```
/www/tmprojects/qd-xiaocaiyuan/
├── backend/
│   ├── app/              # FastAPI
│   ├── local_dev/        # broker.py + 自签证书
│   ├── .env              # 端口/数据库/密钥
│   └── .venv/            # 依赖（virtualenv 建的，Debian 的 python3-venv 装不上）
└── data/zhigu.db
```

## 更新代码

```bash
# 本地打包（排除 venv/缓存/数据库）
tar czf /tmp/zhigu_backend.tgz --exclude='.venv' --exclude='__pycache__' \
    --exclude='*.db' --exclude='.env' backend
scp /tmp/zhigu_backend.tgz root@39.105.145.255:/www/tmprojects/qd-xiaocaiyuan/
ssh root@39.105.145.255 'cd /www/tmprojects/qd-xiaocaiyuan && tar xzf zhigu_backend.tgz \
    && chown -R www:www . && systemctl restart qd-api'
```

## 证书

`local_dev/certs/` 是自签 CA + server.crt/key（10 年）。固件里 `espClient.setInsecure()`
不校验证书，所以只要能 TLS 握手就行。**生产环境要换成正规 CA 证书并开启校验。**

## 安全

- 目前 MQTT 是匿名（broker.py 没有认证），公网可写。**上线前必须加账号密码或按设备证书鉴权。**
- 18000 端口无鉴权，任何能访问的人都能读设备数据。
- 建议：用 nginx 反代 18000 加 HTTPS + 限流；MQTT 只放行设备的出口 IP 段。
