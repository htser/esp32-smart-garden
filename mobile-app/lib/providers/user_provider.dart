import 'package:flutter/material.dart';

/// 用户Provider - 登录态与健康档案
class UserProvider extends ChangeNotifier {
  bool _loggedIn = false;
  String _userId = '';
  String _nickname = '';
  String _token = '';
  Map<String, dynamic> _healthProfile = {};

  bool get loggedIn => _loggedIn;
  String get userId => _userId;
  String get nickname => _nickname;
  String get token => _token;
  Map<String, dynamic> get healthProfile => _healthProfile;

  /// 微信一键登录 (生产环境接入微信SDK)
  Future<void> loginWithWeChat() async {
    // 1. wx.login() 获取 code
    // 2. code -> 后端 -> 自定义登录态 -> JWT
    _loggedIn = true;
    _userId = 'u_8829103';
    _nickname = '种植小王子';
    notifyListeners();
  }

  void updateHealthProfile(Map<String, dynamic> profile) {
    _healthProfile = {..._healthProfile, ...profile};
    notifyListeners();
  }

  /// 慢病方案选择
  void setConditions(List<String> conditions) {
    _healthProfile['conditions'] = conditions;
    notifyListeners();
  }

  void logout() {
    _loggedIn = false;
    _token = '';
    notifyListeners();
  }
}
