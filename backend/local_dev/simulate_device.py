"""
模拟一台智菇小站设备, 每 15 秒上报一次遥测 —— 没有硬件也能把 App 跑通。

    cd backend && ./.venv/bin/python local_dev/simulate_device.py [device_id]
"""
import json
import os
import random
import ssl
import sys
import time

import paho.mqtt.client as mqtt

HOST = os.environ.get("SIM_MQTT_HOST", "127.0.0.1")
PORT = int(os.environ.get("SIM_MQTT_PORT", "8883"))
DEV = sys.argv[1] if len(sys.argv) > 1 else "ZG-SIM0001"


def main() -> None:
    c = mqtt.Client(client_id=f"sim-{DEV}", protocol=mqtt.MQTTv311)
    c.tls_set(cert_reqs=ssl.CERT_NONE)
    c.tls_insecure_set(True)
    c.connect(HOST, PORT, 60)
    c.loop_start()
    time.sleep(0.5)

    c.publish(f"zhigu/{DEV}/status", json.dumps({"deviceId": DEV, "state": "online"}), qos=1, retain=True)
    print(f"[sim] {DEV} -> {HOST}:{PORT}  (Ctrl-C 退出)")
    try:
        while True:
            payload = {
                "deviceId": DEV,
                "ts": int(time.time() * 1000),
                "soil": round(random.uniform(45, 70), 1),
                "airTemp": round(random.uniform(22, 27), 1),
                "airHum": round(random.uniform(55, 70), 1),
                "lux": round(random.uniform(3000, 12000)),
                "water": 100,
                "pressure": round(random.uniform(1008, 1015), 1),
                "stage": 1,
                "plantDay": 3,
                "pump": False,
            }
            c.publish(f"zhigu/{DEV}/telemetry", json.dumps(payload), qos=1)
            print(f"[sim] telemetry soil={payload['soil']} lux={payload['lux']}")
            time.sleep(15)
    except KeyboardInterrupt:
        pass
    finally:
        c.loop_stop()


if __name__ == "__main__":
    main()
