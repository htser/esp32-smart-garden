import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../config/app_config.dart';
import '../services/api_service.dart';

/// 设备状态模型
class DeviceState {
  final String deviceId;
  final String name;
  final bool online;
  final String firmware;
  final String currentCrop;
  final int plantDay;
  final double soilMoisture;
  final double airTemp;
  final double airHumidity;
  final double lux;
  final double water;
  final String stage;

  DeviceState({
    required this.deviceId,
    required this.name,
    this.online = false,
    this.firmware = '1.0.0',
    this.currentCrop = '',
    this.plantDay = 0,
    this.soilMoisture = 0,
    this.airTemp = 0,
    this.airHumidity = 0,
    this.lux = 0,
    this.water = 0,
    this.stage = 'seed',
  });

  DeviceState copyWith({
    double? soilMoisture, double? airTemp, double? airHumidity,
    double? lux, double? water, String? stage, int? plantDay,
  }) => DeviceState(
    deviceId: deviceId, name: name, online: online,
    firmware: firmware, currentCrop: currentCrop, plantDay: plantDay ?? this.plantDay,
    soilMoisture: soilMoisture ?? this.soilMoisture,
    airTemp: airTemp ?? this.airTemp,
    airHumidity: airHumidity ?? this.airHumidity,
    lux: lux ?? this.lux, water: water ?? this.water,
    stage: stage ?? this.stage,
  );
}

/// 设备Provider - 管理设备列表与实时遥测
class DeviceProvider extends ChangeNotifier {
  final List<DeviceState> _devices = [];
  String _activeDeviceId = '';
  WebSocketChannel? _channel;
  Timer? _refreshTimer;
  ApiService? _api;

  List<DeviceState> get devices => List.unmodifiable(_devices);
  String get activeDeviceId => _activeDeviceId;
  DeviceState? get activeDevice =>
      _devices.where((d) => d.deviceId == _activeDeviceId).firstOrNull;

  void setApi(ApiService api) => _api = api;

  Future<void> loadDevices(String userId) async {
    final res = await _api?.listDevices(userId);
    if (res == null || res['code'] != 0) return;
    _devices.clear();
    for (final d in (res['data'] as List)) {
      _devices.add(DeviceState(
        deviceId: d['device_id'], name: d['name'],
        online: d['online'] == true, firmware: d['firmware'] ?? '1.0.0',
        currentCrop: d['current_crop'] ?? '', plantDay: d['plant_day'] ?? 0,
      ));
    }
    if (_devices.isNotEmpty && _activeDeviceId.isEmpty) {
      _activeDeviceId = _devices.first.deviceId;
    }
    notifyListeners();
    _startRealtime();
  }

  void selectDevice(String deviceId) {
    _activeDeviceId = deviceId;
    notifyListeners();
    _startRealtime();
  }

  /// WebSocket 订阅实时遥测
  void _startRealtime() {
    _channel?.sink.close(status.goingAway);
    _channel = WebSocketChannel.connect(
      Uri.parse('${AppConfig.wsUrl}/ws/telemetry/$_activeDeviceId'),
    );
    _channel!.stream.listen((raw) {
      try {
        final msg = jsonDecode(raw) as Map<String, dynamic>;
        if (msg['type'] == 'telemetry') {
          _applyTelemetry(msg['data'] as Map<String, dynamic>);
        }
      } catch (_) {}
    });

    // 兜底轮询 (WebSocket断开时)
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  Future<void> _poll() async {
    final res = await _api?.currentTelemetry(_activeDeviceId);
    if (res != null && res['code'] == 0) {
      _applyTelemetry(res['data'] as Map<String, dynamic>);
    }
  }

  /// 公开的刷新入口（下拉刷新等场景）
  Future<void> refresh() => _poll();

  void _applyTelemetry(Map<String, dynamic> data) {
    final idx = _devices.indexWhere((d) => d.deviceId == _activeDeviceId);
    if (idx < 0) return;
    _devices[idx] = _devices[idx].copyWith(
      soilMoisture: (data['soil'] as num?)?.toDouble(),
      airTemp: (data['airTemp'] as num?)?.toDouble(),
      airHumidity: (data['airHum'] as num?)?.toDouble(),
      lux: (data['lux'] as num?)?.toDouble(),
      water: (data['water'] as num?)?.toDouble(),
      stage: data['stage'] as String?,
      plantDay: data['plantDay'] as int?,
    );
    notifyListeners();
  }

  // ---------- 设备控制 ----------
  Future<void> water({int duration = 3}) async {
    await _api?.sendCommand(_activeDeviceId, 'water', params: {'duration': duration});
  }

  Future<void> setLight(int ratio, {int brightness = 180}) async {
    await _api?.sendCommand(_activeDeviceId, 'light',
        params: {'ratio': ratio, 'brightness': brightness});
  }

  Future<void> setSchedule(int onHour, int offHour) async {
    await _api?.updateDeviceConfig(_activeDeviceId,
        {'light_on_hour': onHour, 'light_off_hour': offHour});
  }

  Future<void> setCrop(String cropId) async {
    await _api?.setCrop(_activeDeviceId, cropId);
    final idx = _devices.indexWhere((d) => d.deviceId == _activeDeviceId);
    if (idx >= 0) {
      _devices[idx] = _devices[idx].copyWith(plantDay: 0, stage: 'seed');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
