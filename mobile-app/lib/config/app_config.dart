class AppConfig {
  // 默认指向线上服务器; 本地调试可用 --dart-define=API_BASE=http://<电脑IP>:8000 覆盖
  // 也可以运行时覆盖: flutter run --dart-define=API_BASE=http://192.168.1.10:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://39.105.145.255:18000',
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_BASE',
    defaultValue: 'ws://39.105.145.255:18000',
  );
  static const String mqttHost = 'mqtt.zhigu.example.com';
  static const int mqttPort = 8883;

  static const String brandName = '智菇小站';
  static const String slogan = '让每个家庭都能种出健康';
}
