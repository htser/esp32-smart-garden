import 'dart:convert';
import 'package:dio/dio.dart';

/// API 服务 - 对接 FastAPI 后端
class ApiService {
  final Dio _dio;

  ApiService({required String baseUrl}) : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // TODO: 从本地存储注入 JWT
        options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) {
        // 统一错误处理
        handler.next(e);
      },
    ));
  }

  String token = '';

  // ---------- 设备 ----------
  Future<Map<String, dynamic>> bindDevice(String deviceId, String userId) =>
      _post('/api/v1/devices/bind', {'device_id': deviceId, 'user_id': userId});

  Future<Map<String, dynamic>> listDevices(String userId) =>
      _get('/api/v1/devices/list?user_id=$userId');

  Future<Map<String, dynamic>> updateDeviceConfig(
      String deviceId, Map<String, dynamic> config) =>
      _put('/api/v1/devices/$deviceId/config', config);

  Future<Map<String, dynamic>> sendCommand(String deviceId, String cmd, {Map<String, dynamic>? params}) =>
      // 后端 DeviceCommand 的结构是 {cmd, params:{...}}，平铺展开参数会丢
      _post('/api/v1/devices/$deviceId/command', {'cmd': cmd, 'params': params ?? {}});

  Future<Map<String, dynamic>> setCrop(String deviceId, String cropId, {int slot = 0}) =>
      _post('/api/v1/devices/$deviceId/set-crop?crop_id=$cropId&slot=$slot', {});

  // ---------- 种植数据 ----------
  Future<Map<String, dynamic>> currentTelemetry(String deviceId) =>
      _get('/api/v1/telemetry/$deviceId/current');

  Future<Map<String, dynamic>> trend(String deviceId, String field, int hours) =>
      _get('/api/v1/telemetry/$deviceId/trend?field=$field&hours=$hours');

  Future<Map<String, dynamic>> cropPlans(String deviceId) =>
      _get('/api/v1/telemetry/$deviceId/plans');

  // ---------- AI ----------
  Future<Map<String, dynamic>> recognizePlant(String imagePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(imagePath),
    });
    final res = await _dio.post('/api/v1/ai/recognize', data: form);
    return res.data;
  }

  Future<Map<String, dynamic>> detectDisease(String imagePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(imagePath),
    });
    final res = await _dio.post('/api/v1/ai/detect-disease', data: form);
    return res.data;
  }

  Future<Map<String, dynamic>> listCrops({String? zhen}) =>
      _get('/api/v1/ai/crops${zhen != null ? '?zhen=$zhen' : ''}');

  Future<Map<String, dynamic>> listPlans() => _get('/api/v1/ai/plans');

  Future<Map<String, dynamic>> planDetail(String planId) =>
      _get('/api/v1/ai/plans/$planId');

  Future<Map<String, dynamic>> recommendCrops(Map<String, dynamic> profile) =>
      _post('/api/v1/ai/recommend-crops', profile);

  Future<Map<String, dynamic>> healthAdvice(
      Map<String, dynamic> profile, String deviceId) =>
      _post('/api/v1/ai/health-advice?device_id=$deviceId', profile);

  Future<Map<String, dynamic>> growthStage(int plantDay, String cropId) =>
      _get('/api/v1/ai/growth-stage?plant_day=$plantDay&crop_id=$cropId');

  // ---------- 社区 ----------
  Future<Map<String, dynamic>> communities({String? city}) =>
      _get('/api/v1/community${city != null ? '?city=$city' : ''}');

  Future<Map<String, dynamic>> communityStats(String communityId) =>
      _get('/api/v1/community/$communityId/stats');

  // ---------- 商城 ----------
  Future<Map<String, dynamic>> products({String? category}) =>
      _get('/api/v1/shop/products${category != null ? '?category=$category' : ''}');

  Future<Map<String, dynamic>> rentalPlans() => _get('/api/v1/shop/rental-plans');

  Future<Map<String, dynamic>> createOrder(
          String userId, List<Map<String, dynamic>> items, String address) =>
      _post('/api/v1/shop/orders',
          {'user_id': userId, 'items': items, 'address': address});

  // ---------- 基础方法 ----------
  Future<Map<String, dynamic>> _get(String path) async {
    final res = await _dio.get(path);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await _dio.post(path, data: jsonEncode(body));
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final res = await _dio.put(path, data: jsonEncode(body));
    return res.data as Map<String, dynamic>;
  }
}
