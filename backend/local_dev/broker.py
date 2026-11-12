"""
本地开发用 MQTT Broker (纯标准库实现, 无第三方依赖)

- 1883 : 明文, 给后端 / 调试脚本用
- 8883 : TLS, 给 ESP32 固件用 (固件里 espClient.setInsecure(), 不校验证书)

只实现 MQTT 3.1.1 里本项目用得到的那部分: CONNECT / SUBSCRIBE / PUBLISH(QoS0-1) /
PUBACK / PING / DISCONNECT / 保留消息 / 通配符。够本地联调用, 生产环境请上 EMQX。

启动:
    cd backend && ./.venv/bin/python local_dev/broker.py
"""
import asyncio
import logging
import os
import signal
import ssl
import struct
import sys
from typing import Dict, List, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
CERTS = os.environ.get("MQTT_CERTS", os.path.join(HERE, "certs"))
PLAIN_PORT = int(os.environ.get("MQTT_PORT", "1883"))
TLS_PORT = int(os.environ.get("MQTT_TLS_PORT", "8883"))

log = logging.getLogger("broker")

CONNECT, CONNACK, PUBLISH, PUBACK = 1, 2, 3, 4
PUBREC, PUBREL, PUBCOMP = 5, 6, 7
SUBSCRIBE, SUBACK, UNSUBSCRIBE, UNSUBACK = 8, 9, 10, 11
PINGREQ, PINGRESP, DISCONNECT = 12, 13, 14


def encode_remaining_length(n: int) -> bytes:
    out = bytearray()
    while True:
        digit, n = n % 128, n // 128
        if n:
            out.append(digit | 0x80)
        else:
            out.append(digit)
            return bytes(out)


def encode_string(s: str) -> bytes:
    b = s.encode()
    return struct.pack("!H", len(b)) + b


def topic_matches(filt: str, topic: str) -> bool:
    f, t = filt.split("/"), topic.split("/")
    for i, part in enumerate(f):
        if part == "#":
            return True
        if i >= len(t):
            return False
        if part != "+" and part != t[i]:
            return False
    return len(f) == len(t)


class Client:
    def __init__(self, reader, writer, peer):
        self.reader, self.writer, self.peer = reader, writer, peer
        self.client_id = ""
        self.subs: Dict[str, int] = {}
        self._pid = 0

    def next_pid(self) -> int:
        self._pid = self._pid % 65535 + 1
        return self._pid

    async def send(self, packet: bytes) -> None:
        try:
            self.writer.write(packet)
            await self.writer.drain()
        except (ConnectionResetError, BrokenPipeError):
            pass

    async def publish(self, topic: str, payload: bytes, qos: int, retain: bool = False) -> None:
        qos = min(qos, 1)
        flags = (qos << 1) | (0x01 if retain else 0x00)
        body = encode_string(topic)
        if qos:
            body += struct.pack("!H", self.next_pid())
        body += payload
        header = bytes([(PUBLISH << 4) | flags]) + encode_remaining_length(len(body))
        await self.send(header + body)


class Broker:
    def __init__(self):
        self.clients: List[Client] = []
        self.retained: Dict[str, Tuple[bytes, int]] = {}

    async def route(self, topic: str, payload: bytes, qos: int, retain: bool) -> None:
        if retain:
            if payload:
                self.retained[topic] = (payload, qos)
            else:
                self.retained.pop(topic, None)
        for c in list(self.clients):
            for filt, sub_qos in c.subs.items():
                if topic_matches(filt, topic):
                    await c.publish(topic, payload, min(qos, sub_qos), retain=False)
                    break

    async def handle(self, reader, writer) -> None:
        peer = writer.get_extra_info("peername")
        client = Client(reader, writer, peer)
        self.clients.append(client)
        log.info("connect %s", peer)
        try:
            while True:
                fixed = await reader.readexactly(1)
                ptype = fixed[0] >> 4
                flags = fixed[0] & 0x0F
                val, mult = 0, 1
                while True:
                    b = (await reader.readexactly(1))[0]
                    val += (b & 0x7F) * mult
                    mult *= 128
                    if not b & 0x80:
                        break
                body = await reader.readexactly(val) if val else b""
                await self.on_packet(client, ptype, flags, body)
        except (asyncio.IncompleteReadError, ConnectionResetError):
            pass
        except Exception as e:  # noqa: BLE001
            log.warning("connection %s error: %r", peer, e)
        finally:
            if client in self.clients:
                self.clients.remove(client)
            try:
                writer.close()
                await writer.wait_closed()
            except Exception:  # noqa: BLE001
                pass
            log.info("disconnect %s (%s)", peer, client.client_id or "?")

    async def on_packet(self, c: Client, ptype: int, flags: int, body: bytes) -> None:
        if ptype == CONNECT:
            i = 2 + struct.unpack("!H", body[0:2])[0] + 4   # proto name + level + flags + keepalive
            cid_len = struct.unpack("!H", body[i:i + 2])[0]
            c.client_id = body[i + 2:i + 2 + cid_len].decode(errors="replace")
            await c.send(bytes([CONNACK << 4, 2, 0, 0]))
            log.info("CONNACK -> %s (client_id=%s)", c.peer, c.client_id)

        elif ptype == SUBSCRIBE:
            pid = struct.unpack("!H", body[0:2])[0]
            i, codes = 2, []
            while i < len(body):
                n = struct.unpack("!H", body[i:i + 2])[0]
                filt = body[i + 2:i + 2 + n].decode()
                qos = body[i + 2 + n] & 0x03
                i += 3 + n
                c.subs[filt] = qos
                codes.append(min(qos, 1))
                log.info("SUB %s <- %s (qos %d)", filt, c.client_id, qos)
                for topic, (payload, rqos) in list(self.retained.items()):
                    if topic_matches(filt, topic):
                        await c.publish(topic, payload, min(rqos, qos), retain=True)
            payload = struct.pack("!H", pid) + bytes(codes)
            await c.send(bytes([SUBACK << 4]) + encode_remaining_length(len(payload)) + payload)

        elif ptype == PUBLISH:
            qos = (flags >> 1) & 0x03
            retain = bool(flags & 0x01)
            n = struct.unpack("!H", body[0:2])[0]
            topic = body[2:2 + n].decode()
            i = 2 + n
            pid = None
            if qos:
                pid = struct.unpack("!H", body[i:i + 2])[0]
                i += 2
            payload = body[i:]
            log.info("PUB %s = %s (qos %d%s)", topic,
                     payload[:160].decode(errors="replace"), qos,
                     ", retain" if retain else "")
            await self.route(topic, payload, qos, retain)
            if qos == 1:
                await c.send(bytes([PUBACK << 4, 2]) + struct.pack("!H", pid))
            elif qos == 2:
                await c.send(bytes([PUBREC << 4, 2]) + struct.pack("!H", pid))

        elif ptype == PUBREL:
            pid = struct.unpack("!H", body[0:2])[0]
            await c.send(bytes([PUBCOMP << 4, 2]) + struct.pack("!H", pid))

        elif ptype == UNSUBSCRIBE:
            pid = struct.unpack("!H", body[0:2])[0]
            i = 2
            while i < len(body):
                n = struct.unpack("!H", body[i:i + 2])[0]
                c.subs.pop(body[i + 2:i + 2 + n].decode(), None)
                i += 2 + n
            await c.send(bytes([UNSUBACK << 4, 2]) + struct.pack("!H", pid))

        elif ptype == PINGREQ:
            await c.send(bytes([PINGRESP << 4, 0]))

        elif ptype == DISCONNECT:
            raise asyncio.IncompleteReadError(b"", 1)


async def main() -> None:
    logging.basicConfig(level=logging.INFO,
                        format="%(asctime)s %(levelname)-7s %(message)s")
    broker = Broker()

    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(os.path.join(CERTS, "server.crt"), os.path.join(CERTS, "server.key"))

    s1 = await asyncio.start_server(broker.handle, "0.0.0.0", PLAIN_PORT, reuse_address=True)
    s2 = await asyncio.start_server(broker.handle, "0.0.0.0", TLS_PORT, ssl=ctx, reuse_address=True)
    log.info("MQTT broker up: tcp://0.0.0.0:%d  tls://0.0.0.0:%d", PLAIN_PORT, TLS_PORT)

    stop = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, stop.set)
        except NotImplementedError:
            pass
    async with s1, s2:
        await stop.wait()

    s1.close()
    s2.close()
    log.info("broker stopped")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        sys.exit(0)
