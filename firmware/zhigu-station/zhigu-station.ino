/*
 * 智菇小站 - AI智能家庭小菜园
 * ESP32-S3 主固件
 *
 * 硬件清单:
 *   - ESP32-S3-WROOM-1 (N16R8)
 *   - 6x 电容式土壤湿度传感器 (GPIO34-39 ADC)
 *   - 1x DHT22 温湿度传感器 (GPIO4)
 *   - 1x 非接触式水位传感器 (GPIO5)
 *   - 1x WS2812B LED生长灯板 x48颗 (GPIO2)
 *   - 1x 微型静音水泵 5V (GPIO12 + 继电器)
 *   - 1x ILI9488 4.3寸触控屏 (SPI + 电阻触摸)
 *   - 1x OV2640 摄像头模组 (DVP)
 *   - I2C: AHT20 / BMP280 / BH1750
 *
 * 依赖库 (Arduino Library Manager):
 *   - PubSubClient          (MQTT)
 *   - ArduinoJson           (JSON)
 *   - DHT sensor library
 *   - Adafruit NeoPixel
 *   - TFT_eSPI              (屏幕)
 *   - Adafruit AHTX0
 *   - Adafruit BMP280
 *   - BH1750                (ROBMind)
 *   - Preferences           (NVS 存储, ESP32 内置)
 */

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <DHT.h>
#include <Adafruit_NeoPixel.h>
#include <Wire.h>
#include <Adafruit_AHTX0.h>
#include <Adafruit_BMP280.h>
#include <BH1750.h>
#include <WebServer.h>
#include <DNSServer.h>

// ======================== 配置区 ========================
// 调试串口: ESP32-S3 上 Serial 可能被映射到原生 USB(USB-CDC), 那样 CP2102 串口(COM/cu.usbserial)
// 就看不到任何日志。这里统一用 Serial0 = UART0(GPIO43/44) 输出, 保证调试信息一定能从
// “UART”那一路串口看到。若想改走原生 USB-CDC, 把下面一行改成 #define DBG Serial 即可。
#define DBG                  Serial0

static void startProvisioning();
static void provisioningLoop();
static bool provisioningMode = false;   // true = 正在配网(只跑热点+网页)

#define FIRMWARE_VERSION     "1.0.0"
#define DEVICE_MODEL         "ZHIGU-S1"

// GPIO 定义
#define PIN_DHT22            4
#define PIN_WATER_LEVEL      5
#define PIN_NEOPIXEL         6
#define PIN_PUMP_RELAY       12
#define PIN_SOIL_BASE        34      // ADC1_CH6, 土壤传感器1-6依次占用34-39
#define NUM_SOIL_SENSORS     6
#define NUM_PIXELS           48

// MQTT / WiFi
// 联调时把这里改成“跑 backend 那台电脑”的局域网 IP (手机/设备能 ping 通它即可)
#define MQTT_HOST_DEFAULT    "39.105.145.255"
#define MQTT_PORT            23883
#define MQTT_KEEPALIVE       60

// 工作参数
#define SOIL_MOISTURE_TARGET 62      // 目标土壤湿度 %
#define WATER_PUMP_DURATION  3000    // 水泵单次运行时长 ms
#define SENSOR_INTERVAL      15000   // 传感器上报间隔 ms
#define HEALTH_INTERVAL      60000   // 心跳间隔 ms
#define LIGHT_ON_HOUR        6       // 默认开灯时间 (6:00)
#define LIGHT_OFF_HOUR       22      // 默认关灯时间 (22:00)

// ======================== 数据结构 ========================
struct SensorData {
  float soilMoisture[6];
  float airTemp;
  float airHumidity;
  float waterLevelPct;
  float lux;
  float pressure;
};

struct DeviceConfig {
  char wifiSsid[32];
  char wifiPass[64];
  char mqttHost[64];
  char mqttUser[32];
  char mqttPass[64];
  char deviceId[24];
  int  lightOnHour;
  int  lightOffHour;
  int  redBlueRatio;      // 红蓝光比 0-100
  bool autoWater;
  char currentCrop[24];   // 当前种植品种ID
};

enum GrowStage { STAGE_SEED, STAGE_SPROUT, STAGE_GROWTH, STAGE_HARVEST };

// ======================== 全局对象 ========================
SensorData   sensors;
DeviceConfig config;
Preferences  prefs;
WiFiClientSecure espClient;
PubSubClient mqtt(espClient);
DHT          dht(PIN_DHT22, DHT22);
Adafruit_NeoPixel strip(NUM_PIXELS, PIN_NEOPIXEL, NEO_GRB + NEO_KHZ800);
Adafruit_AHTX0   aht;
Adafruit_BMP280  bmp;
BH1750       lightMeter;

unsigned long lastSensorPush = 0;
unsigned long lastHealth    = 0;
unsigned long pumpStartedAt  = 0;
bool          pumpRunning    = false;
unsigned long lightManualUntil = 0;   // 手动调光后 30 分钟内不被“光照定时”覆盖
bool          lightAppliedOn   = false;
int           lightAppliedRatio = -1;
bool          wifiConnected  = false;
GrowStage     currentStage   = STAGE_SEED;
int           plantDay       = 0;      // 种植天数

// MQTT Topic 模板
char topicTelemetry[80];
char topicCommand[80];
char topicStatus[80];
char topicHealth[80];


// 串口配网: 开机后 10 秒内, 在串口里敲  wifi <SSID> <密码>  回车
// 注意: 只对本次运行生效(不做 NVS 持久化, 持久化见 TODO)
static char provSsid[33] = {0};
static char provPass[65] = {0};
static bool provOk = false;

static void serialProvision() {
  DBG.println("[PROV] 5 秒内可发送: wifi <SSID> <密码>  (仅本次运行生效)");
  String line;
  uint32_t start = millis();
  while (millis() - start < 5000) {
    while (Serial0.available()) {
      char ch = (char)Serial0.read();
      if (ch == '\r') continue;
      if (ch == '\n') {
        line.trim();
        if (line.startsWith("wifi ")) {
          int sp = line.indexOf(' ', 5);
          if (sp > 5) {
            strlcpy(provSsid, line.substring(5, sp).c_str(), sizeof(provSsid));
            strlcpy(provPass, line.substring(sp + 1).c_str(), sizeof(provPass));
            provOk = true;
            DBG.printf("[PROV] 收到 WiFi: %s, 开始连接\n", provSsid);
            return;
          }
        }
        line = "";
      } else if (line.length() < 96) {
        line += ch;
      }
    }
    delay(20);
  }
  DBG.println("[PROV] 配网窗口结束");
}


// ======================== 初始化 ========================
void setup() {
  DBG.begin(115200);
  delay(500);
  DBG.println("\n[BOOT] 智菇小站 firmware v" FIRMWARE_VERSION);

  // ---- NVS ----
  prefs.begin("zhigu", false);
  serialProvision();          // 串口配网: 10 秒内发送 "wifi <SSID> <密码>"
  loadConfig();
  if (provOk) {               // 本次运行用串口收到的 WiFi 覆盖 NVS 里的值
    strlcpy(config.wifiSsid, provSsid, sizeof(config.wifiSsid));
    strlcpy(config.wifiPass, provPass, sizeof(config.wifiPass));
  }

  // ---- 引脚 ----
  pinMode(PIN_WATER_LEVEL, INPUT);
  pinMode(PIN_PUMP_RELAY, OUTPUT);
  digitalWrite(PIN_PUMP_RELAY, LOW);   // 继电器低电平触发，默认关闭
  for (int i = 0; i < NUM_SOIL_SENSORS; i++) {
    pinMode(PIN_SOIL_BASE + i, INPUT);
  }

  // ---- 外设 ----
  dht.begin();
  strip.begin();
  strip.setBrightness(180);
  strip.show();

  Wire.begin();
  if (!aht.begin())  DBG.println("[WARN] AHT20 not found");
  if (!bmp.begin(0x76)) DBG.println("[WARN] BMP280 not found");
  if (lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE)) {
    DBG.println("[OK] BH1750 ready");
  }

  // ---- 网络 ----
  setupWiFi();
  setupMQTT();

  DBG.println("[BOOT] setup complete, entering loop");
}

// ======================== 主循环 ========================
void loop() {
  if (provisioningMode) {          // 配网模式: 只跑 DNS + HTTP 服务, 不碰 MQTT/传感器
    provisioningLoop();
    delay(2);
    return;
  }

  unsigned long now = millis();

  // 网络保活
  if (!mqtt.connected()) reconnectMQTT();
  mqtt.loop();

  // 传感器采集与上报
  if (now - lastSensorPush >= SENSOR_INTERVAL) {
    lastSensorPush = now;
    readSensors();
    publishTelemetry();
    autoControl();
  }

  // 心跳
  if (now - lastHealth >= HEALTH_INTERVAL) {
    lastHealth = now;
    publishHealth();
  }

  // 水泵定时关闭保护
  if (pumpRunning && now - pumpStartedAt >= WATER_PUMP_DURATION) {
    stopPump();
  }

  // 补光灯调度
  scheduleLight();
  delay(50);
}

// ======================== 配置管理 ========================
void loadConfig() {
  config.lightOnHour   = prefs.getInt("lightOn",  LIGHT_ON_HOUR);
  config.lightOffHour  = prefs.getInt("lightOff", LIGHT_OFF_HOUR);
  config.redBlueRatio  = prefs.getInt("rbRatio",  50);
  config.autoWater     = prefs.getBool("autoWater", true);
  prefs.getString("ssid", config.wifiSsid, sizeof(config.wifiSsid));
  prefs.getString("pass", config.wifiPass, sizeof(config.wifiPass));
  prefs.getString("host", config.mqttHost, sizeof(config.mqttHost));
  prefs.getString("user", config.mqttUser, sizeof(config.mqttUser));
  prefs.getString("mqpass", config.mqttPass, sizeof(config.mqttPass));
  prefs.getString("devId", config.deviceId, sizeof(config.deviceId));
  prefs.getString("crop", config.currentCrop, sizeof(config.currentCrop));

  // 出厂缺省
  if (strlen(config.deviceId) == 0) {
    strcpy(config.deviceId, getDeviceId().c_str());
    prefs.putString("devId", config.deviceId);
  }
  if (strlen(config.mqttHost) == 0) {
    strcpy(config.mqttHost, MQTT_HOST_DEFAULT);
    prefs.putString("host", config.mqttHost);
  }

  buildTopics();
}

String getDeviceId() {
  uint64_t chipid = ESP.getEfuseMac();
  char buf[24];
  snprintf(buf, sizeof(buf), "ZG-%04X%08X",
           (uint16_t)(chipid >> 32), (uint32_t)chipid);
  return String(buf);
}

void buildTopics() {
  snprintf(topicTelemetry, sizeof(topicTelemetry), "zhigu/%s/telemetry", config.deviceId);
  snprintf(topicCommand,    sizeof(topicCommand),    "zhigu/%s/command",    config.deviceId);
  snprintf(topicStatus,     sizeof(topicStatus),     "zhigu/%s/status",     config.deviceId);
  snprintf(topicHealth,     sizeof(topicHealth),     "zhigu/%s/health",     config.deviceId);
}

// ======================== 配网 (SoftAP + 内嵌网页) ========================
// 产品流程: 上电无配置 -> 开热点 ZHIGU-XXXX / 12345678 -> 手机连上后打开 192.168.4.1
// -> 选择 WiFi + 密码 -> 设备写 NVS 并重启 -> 连上路由器后走 MQTT 上线。
// App 也可以不打开网页, 直接 POST http://192.168.4.1/api/provision
#define AP_PASSWORD          "12345678"

static WebServer   provServer(80);
static DNSServer   dnsServer;
static String      apSsid;
static String      scanJson = "{\"networks\":[]}";

static const char PROV_PAGE[] PROGMEM = R"rawliteral(<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>智菇小站 配网</title><style>
body{font-family:-apple-system,sans-serif;margin:0;background:#0f1a12;color:#e8f5e9}
.wrap{max-width:420px;margin:0 auto;padding:28px 20px}
h1{font-size:20px;margin:0 0 4px}p.sub{color:#9ccc9c;font-size:13px;margin:0 0 18px}
label{display:block;font-size:13px;color:#9ccc9c;margin:14px 0 6px}
input,select{width:100%;box-sizing:border-box;padding:12px;border-radius:10px;border:1px solid #2e4a33;background:#16241a;color:#e8f5e9;font-size:15px}
button{width:100%;margin-top:22px;padding:14px;border:0;border-radius:10px;background:#4caf50;color:#08210c;font-size:16px;font-weight:600}
button:disabled{background:#2e4a33;color:#7d8f7f}#msg{margin-top:16px;font-size:13px;color:#ffcc80}
.card{background:#16241a;border:1px solid #2e4a33;border-radius:14px;padding:14px;margin-top:18px;font-size:12px;color:#9ccc9c;line-height:1.7}
</style></head><body><div class="wrap">
<h1>智菇小站 · 配网</h1><p class="sub">选择家里的 WiFi 并输入密码, 设备会自动连接。</p>
<label>WiFi 名称</label>
<select id="list" onchange="document.getElementById('ssid').value=this.value"><option value="">扫描中...</option></select>
<input id="ssid" placeholder="或手动输入 WiFi 名称">
<label>WiFi 密码</label><input id="pass" type="password" placeholder="8 位以上">
<button id="btn" onclick="go()">连接并保存</button><div id="msg"></div>
<div class="card">设备: <span id="dev">-</span><br>热点: <span id="ap">-</span><br>固件: <span id="fw">-</span></div>
</div><script>
const j=async(u,o)=>(await fetch(u,o)).json();
(async()=>{try{const i=await j('/api/info');dev.textContent=i.deviceId;ap.textContent=i.ap;fw.textContent=i.version;
const s=await j('/api/scan');
list.innerHTML='<option value="">选择 WiFi...</option>'+(s.networks.length?s.networks.map(n=>`<option value="${n.ssid}">${n.ssid} (${n.rssi}dBm)</option>`).join(''):'<option value="">没扫到, 请手动输入</option>');}catch(e){}})();
async function go(){const ssid=document.getElementById('ssid').value.trim(),pass=document.getElementById('pass').value;
if(!ssid){msg.textContent='请填写 WiFi 名称';return}
btn.disabled=true;btn.textContent='连接中...';msg.textContent='设备正在连接, 请稍候...';
try{const r=await j('/api/provision',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({ssid,pass})});
msg.textContent=r.ok?('已保存, 设备正在重启并连接 '+ssid+'。请把手机连回原来的 WiFi, 然后在 App 里刷新设备列表。'):('失败: '+(r.error||''));}
catch(e){msg.textContent='设备已重启, 请稍后在 App 里查看设备状态';}}
</script></body></html>)rawliteral";

static void provSendJson(int code, const String &body) {
  provServer.sendHeader("Access-Control-Allow-Origin", "*");
  provServer.send(code, "application/json; charset=utf-8", body);
}

static void startProvisioning() {
  if (provisioningMode) return;
  provisioningMode = true;

  char sfx[8];
  snprintf(sfx, sizeof(sfx), "%04X", (uint16_t)(ESP.getEfuseMac() & 0xFFFF));
  apSsid = String("ZHIGU-") + sfx;

  // 先扫一次周围 WiFi 并缓存: 扫描时会把热点信道让出去, 所以必须在开热点之前做,
  // 之后 /api/scan 直接返回缓存, 页面瞬间出来。
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  DBG.println("[PROV] 扫描周围 WiFi ...");
  int n = WiFi.scanNetworks(false, false, false, 120);
  scanJson = "{\"networks\":[";
  bool firstNet = true;
  for (int i = 0; i < n && i < 24; i++) {
    if (WiFi.SSID(i).length() == 0) continue;
    if (!firstNet) scanJson += ",";
    firstNet = false;
    String ssid = WiFi.SSID(i);
    ssid.replace("\"", "'");
    scanJson += "{\"ssid\":\"" + ssid + "\",\"rssi\":" + String(WiFi.RSSI(i)) + "}";
  }
  scanJson += "]}";
  WiFi.scanDelete();
  DBG.printf("[PROV] 扫到 %d 个 WiFi\n", n);

  WiFi.mode(WIFI_AP_STA);
  WiFi.softAP(apSsid.c_str(), AP_PASSWORD);
  delay(100);

  dnsServer.start(53, "*", WiFi.softAPIP());   // 捕获任意域名 -> 弹出配网页(强制门户)

  provServer.on("/", HTTP_GET, []() {
    provServer.send_P(200, "text/html; charset=utf-8", PROV_PAGE);
  });

  provServer.on("/api/info", HTTP_GET, []() {
    String body = String("{\"model\":\"") + DEVICE_MODEL + "\",\"deviceId\":\"" + config.deviceId +
                  "\",\"version\":\"" + FIRMWARE_VERSION + "\",\"ap\":\"" + apSsid +
                  "\",\"state\":\"provisioning\"}";
    provSendJson(200, body);
  });

  provServer.on("/api/scan", HTTP_GET, []() { provSendJson(200, scanJson); });

  provServer.on("/api/provision", HTTP_POST, []() {
    String raw = provServer.arg("plain");
    StaticJsonDocument<512> doc;
    DeserializationError err = deserializeJson(doc, raw);
    if (err) { provSendJson(400, "{\"ok\":false,\"error\":\"bad json\"}"); return; }

    const char *ssid = doc["ssid"] | "";
    const char *pass = doc["pass"] | "";
    if (strlen(ssid) == 0) { provSendJson(400, "{\"ok\":false,\"error\":\"ssid required\"}"); return; }

    prefs.putString("ssid", ssid);
    prefs.putString("pass", pass);
    DBG.printf("[PROV] got ssid=%s, saved to NVS, restarting\n", ssid);

    String body = String("{\"ok\":true,\"deviceId\":\"") + config.deviceId + "\"}";
    provSendJson(200, body);
    delay(600);
    ESP.restart();
  });

  provServer.onNotFound([]() {                       // 强制门户: 任意地址都跳回首页
    provServer.sendHeader("Location", "http://192.168.4.1/", true);
    provServer.send(302, "text/plain", "");
  });
  provServer.begin();

  DBG.printf("[WIFI] 配网模式已开启: 连热点 %s (密码 %s), 然后打开 http://192.168.4.1\n",
             apSsid.c_str(), AP_PASSWORD);
}

static void provisioningLoop() {
  if (!provisioningMode) return;
  dnsServer.processNextRequest();
  provServer.handleClient();
}

// ======================== 网络 ========================
void setupWiFi() {
  if (strlen(config.wifiSsid) == 0) {
    startProvisioning();          // 没配过网: 开热点 + 网页配网
    return;
  }
  WiFi.mode(WIFI_STA);
  WiFi.begin(config.wifiSsid, config.wifiPass);
  DBG.printf("[WIFI] connecting to %s", config.wifiSsid);
  int tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 40) {
    delay(500); DBG.print(".");
    tries++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    DBG.printf("\n[WIFI] connected, IP: %s\n", WiFi.localIP().toString().c_str());
  } else {
    DBG.println("\n[WIFI] connect failed, 开热点让你重新配网");
    startProvisioning();          // 密码错了/路由器不在: 回到配网热点
  }
}

void setupMQTT() {
  espClient.setInsecure();  // 生产环境应替换为CA证书校验
  mqtt.setServer(config.mqttHost, MQTT_PORT);
  mqtt.setCallback(onMqttMessage);
  mqtt.setBufferSize(2048);
}

void reconnectMQTT() {
  if (WiFi.status() != WL_CONNECTED) {
    setupWiFi();
    if (strlen(config.wifiSsid) == 0) {   // 还在配网模式: 不要每秒重试 MQTT
      delay(1000);
      return;
    }
  }
  if (mqtt.connected()) return;

  DBG.printf("[MQTT] connecting to %s ...\n", config.mqttHost);
  String clientId = String(config.deviceId) + "-" + String(random(0xffff), HEX);
  if (mqtt.connect(clientId.c_str(), config.mqttUser, config.mqttPass)) {
    DBG.println("[MQTT] connected");
    mqtt.subscribe(topicCommand, 1);
    publishStatus("online");
  } else {
    DBG.printf("[MQTT] failed, rc=%d\n", mqtt.state());
    delay(3000);
  }
}

// ======================== 传感器 ========================
void readSensors() {
  // 土壤湿度 (ADC -> 百分比, 干燥值3500 / 浸水值1500 标定区间)
  for (int i = 0; i < NUM_SOIL_SENSORS; i++) {
    int raw = analogRead(PIN_SOIL_BASE + i);
    sensors.soilMoisture[i] = constrain(map(raw, 1500, 3500, 100, 0), 0, 100);
  }

  // 空气温湿度 (DHT22 + AHT20 双冗余, 取AHT20优先)
  sensors.airTemp = dht.readTemperature();
  sensors.airHumidity = dht.readHumidity();
  sensors_event_t humidity, temp;
  if (aht.getEvent(&humidity, &temp)) {
    sensors.airTemp = temp.temperature;
    sensors.airHumidity = humidity.relative_humidity;
  }

  // 水位
  sensors.waterLevelPct = digitalRead(PIN_WATER_LEVEL) ? 100.0 : 15.0;

  // 光照 / 气压
  sensors.lux = lightMeter.readLightLevel();
  sensors.pressure = bmp.readPressure() / 100.0F;
}

float avgSoilMoisture() {
  float sum = 0;
  for (int i = 0; i < NUM_SOIL_SENSORS; i++) sum += sensors.soilMoisture[i];
  return sum / NUM_SOIL_SENSORS;
}

// ======================== 自动控制 ========================
void autoControl() {
  if (config.autoWater && avgSoilMoisture() < SOIL_MOISTURE_TARGET - 10) {
    startPump();
  }
}

void startPump() {
  if (pumpRunning) return;
  digitalWrite(PIN_PUMP_RELAY, HIGH);
  pumpStartedAt = millis();
  pumpRunning = true;
  DBG.println("[PUMP] start");
}

void stopPump() {
  digitalWrite(PIN_PUMP_RELAY, LOW);
  pumpRunning = false;
  DBG.println("[PUMP] stop");
}

void scheduleLight() {
  // 手动调光保护期: 期间不覆盖用户/调试下发的灯光
  if (lightManualUntil && (long)(millis() - lightManualUntil) < 0) return;

  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return;   // NTP未同步则跳过
  int hour = timeinfo.tm_hour;
  bool shouldOn = (hour >= config.lightOnHour && hour < config.lightOffHour);

  if (shouldOn) {
    if (!lightAppliedOn || lightAppliedRatio != config.redBlueRatio) {
      setLight(config.redBlueRatio, 180);
    }
  } else if (lightAppliedOn) {
    strip.clear();
    strip.show();
    lightAppliedOn = false;
  }
}

// 设置灯光: ratio=红光占比百分比
void setLight(int ratio, uint8_t brightness) {
  lightAppliedOn    = brightness > 0;
  lightAppliedRatio = ratio;
  strip.setBrightness(brightness);
  int redCount = NUM_PIXELS * ratio / 100;
  for (int i = 0; i < NUM_PIXELS; i++) {
    if (i < redCount) strip.setPixelColor(i, strip.Color(255, 60, 20));
    else               strip.setPixelColor(i, strip.Color(20, 60, 255));
  }
  strip.show();
}

// ======================== MQTT 通信 ========================
void publishTelemetry() {
  StaticJsonDocument<768> doc;
  doc["deviceId"]   = config.deviceId;
  doc["ts"]         = millis();
  doc["soil"]       = avgSoilMoisture();
  JsonArray soilArr = doc.createNestedArray("soilArr");
  for (int i = 0; i < NUM_SOIL_SENSORS; i++) soilArr.add(sensors.soilMoisture[i]);
  doc["airTemp"]    = round1(sensors.airTemp);
  doc["airHum"]     = round1(sensors.airHumidity);
  doc["water"]      = sensors.waterLevelPct;
  doc["lux"]        = round1(sensors.lux);
  doc["pressure"]   = round1(sensors.pressure);
  doc["stage"]      = currentStage;
  doc["plantDay"]   = plantDay;
  doc["pump"]       = pumpRunning;

  char buf[768];
  serializeJson(doc, buf);
  mqtt.publish(topicTelemetry, buf);
  DBG.printf("[MQTT] telemetry -> %s\n", buf);
}

void publishHealth() {
  StaticJsonDocument<256> doc;
  doc["deviceId"] = config.deviceId;
  doc["fw"]       = FIRMWARE_VERSION;
  doc["model"]    = DEVICE_MODEL;
  doc["rssi"]     = WiFi.RSSI();
  doc["uptime"]   = millis() / 1000;
  doc["heap"]     = ESP.getFreeHeap();
  char buf[256];
  serializeJson(doc, buf);
  mqtt.publish(topicHealth, buf);
}

void publishStatus(const char* state) {
  StaticJsonDocument<192> doc;
  doc["deviceId"] = config.deviceId;
  doc["state"]    = state;
  char buf[192];
  serializeJson(doc, buf);
  mqtt.publish(topicStatus, buf, true);
}

// 指令回调: 云端/APP下发
void onMqttMessage(char* topic, byte* payload, unsigned int len) {
  StaticJsonDocument<512> doc;
  deserializeJson(doc, payload, len);
  const char* cmd = doc["cmd"];

  if (strcmp(cmd, "water") == 0) {
    int sec = doc["duration"] | 3;
    startPump();
    pumpStartedAt = millis() - (WATER_PUMP_DURATION - sec * 1000);
  }
  else if (strcmp(cmd, "light") == 0) {
    int ratio = doc["ratio"] | 50;
    int bri   = doc["brightness"] | 180;
    setLight(ratio, bri);
    lightManualUntil = millis() + 30UL * 60UL * 1000UL;   // 30 分钟内不自动覆盖
    DBG.printf("[LIGHT] 手动下发 ratio=%d brightness=%d\n", ratio, bri);
    config.redBlueRatio = ratio;
    prefs.putInt("rbRatio", ratio);
  }
  else if (strcmp(cmd, "setSchedule") == 0) {
    config.lightOnHour  = doc["onHour"]  | LIGHT_ON_HOUR;
    config.lightOffHour = doc["offHour"] | LIGHT_OFF_HOUR;
    prefs.putInt("lightOn",  config.lightOnHour);
    prefs.putInt("lightOff", config.lightOffHour);
  }
  else if (strcmp(cmd, "setCrop") == 0) {
    strlcpy(config.currentCrop, doc["cropId"] | "unknown", sizeof(config.currentCrop));
    prefs.putString("crop", config.currentCrop);
    plantDay = 0;
    currentStage = STAGE_SEED;
  }
  else if (strcmp(cmd, "restart") == 0) {
    ESP.restart();
  }
  else if (strcmp(cmd, "configWifi") == 0) {
    prefs.putString("ssid", doc["ssid"] | "");
    prefs.putString("pass", doc["pass"] | "");
    delay(500);
    ESP.restart();
  }
}

// ======================== 工具 ========================
float round1(float v) { return round(v * 10.0) / 10.0; }
