import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// 设备配网
///
/// 产品流程(SoftAP + 内嵌网页, 不依赖蓝牙也不需要串口):
///   1. 设备上电, 没有存过 WiFi -> 广播热点 `ZHIGU-XXXX` (密码 12345678)
///   2. 手机连上这个热点 -> 打开本页
///   3. 本页把 `{ssid, pass}` POST 给设备 `http://192.168.4.1/api/provision`
///   4. 设备写 NVS 并重启, 连上路由器后通过 MQTT 上线
///   5. 手机连回原来的 WiFi, 后端 `/devices/list` 里就会出现这台设备
class ProvisionScreen extends StatefulWidget {
  const ProvisionScreen({super.key});

  @override
  State<ProvisionScreen> createState() => _ProvisionScreenState();
}

class _ProvisionScreenState extends State<ProvisionScreen> {
  static const String _deviceBase = 'http://192.168.4.1'; // 设备热点的固定地址

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _deviceBase,
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 10),
  ));
  final TextEditingController _ssidCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _busy = false;
  bool _connected = false;
  String _status = '正在检测设备...';
  String _apName = 'ZHIGU-XXXX';
  List<dynamic> _networks = <dynamic>[];

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    setState(() {
      _busy = true;
      _status = '正在读取设备信息...';
    });
    try {
      final info = await _dio.get('/api/info');
      final scan = await _dio.get('/api/scan');
      if (!mounted) return;
      final data = info.data as Map<String, dynamic>;
      setState(() {
        _busy = false;
        _connected = true;
        _apName = (data['ap'] ?? _apName).toString();
        _status = '已连接设备 ${data['deviceId'] ?? ''}';
        final raw = (scan.data['networks'] as List?) ?? <dynamic>[];
        final seen = <String>{};
        _networks = raw.where((n) {
          final ssid = (n['ssid'] ?? '').toString();
          if (ssid.isEmpty || !seen.add(ssid)) return false;
          return true;
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _connected = false;
        _status = '没有连上设备。请先到 设置 → WLAN 连接热点 $_apName（密码 12345678）';
      });
    }
  }

  Future<void> _submit() async {
    final ssid = _ssidCtrl.text.trim();
    final pass = _passCtrl.text;
    if (ssid.isEmpty) {
      setState(() => _status = '请填写或选择 WiFi 名称');
      return;
    }
    setState(() {
      _busy = true;
      _status = '正在把 WiFi 交给设备...';
    });
    try {
      await _dio.post('/api/provision', data: {'ssid': ssid, 'pass': pass});
    } catch (e) {
      // 设备收到后会立刻重启, 连接被掐断属于正常现象
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = '已提交，设备正在重启并连接「$ssid」';
    });
    _showDone(ssid);
  }

  void _showDone(String ssid) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('配网完成'),
        content: Text(
          '设备正在连接「$ssid」。\n\n'
          '1. 请把手机连回原来的 WiFi\n'
          '2. 回到首页下拉刷新，设备会自动出现在列表里\n'
          '3. 若 60 秒后仍不出现，请检查路由器是不是 2.4GHz（ESP32 不支持 5GHz）',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设备配网')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StepCard(
            index: 1,
            title: '连上设备热点',
            body: '到手机的 WLAN 设置里连接「$_apName」，密码 12345678。'
                '连上后回到本页点“重新检测”。',
          ),
          const SizedBox(height: 12),
          _StepCard(
            index: 2,
            title: '选择家里的 WiFi',
            body: '只支持 2.4GHz。填好后点“开始配网”。',
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: '扫描到的 WiFi'),
            items: _networks
                .map((n) => DropdownMenuItem<String>(
                      value: (n['ssid'] ?? '') as String,
                      child: Text('${n['ssid']}  (${n['rssi']}dBm)',
                          style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) _ssidCtrl.text = v;
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ssidCtrl,
            decoration: const InputDecoration(labelText: 'WiFi 名称(SSID)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'WiFi 密码'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _loadInfo,
                  child: const Text('重新检测'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (_busy || !_connected) ? null : _submit,
                  child: Text(_busy ? '处理中...' : '开始配网'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(_connected ? Icons.check_circle : Icons.info_outline,
                  size: 16,
                  color: _connected ? const Color(0xFF2E7D32) : Colors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_status,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final String title;
  final String body;
  const _StepCard({required this.index, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A2E7D32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF2E7D32),
            child: Text('$index',
                style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
