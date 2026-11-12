import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/device_provider.dart';

/// 灯光调试页 —— 直接给设备下发 `light` 指令（走 MQTT: zhigu/<id>/command）
///
/// 固件侧 onMqttMessage() 里处理:
///   {"cmd":"light","ratio":0-100,"brightness":0-255}
/// ratio = 红光占比(%)，剩下的用蓝光；brightness = 0 就是关灯。
class LightDebugScreen extends StatefulWidget {
  const LightDebugScreen({super.key});

  @override
  State<LightDebugScreen> createState() => _LightDebugScreenState();
}

class _LightDebugScreenState extends State<LightDebugScreen> {
  double _ratio = 50;      // 红光占比
  double _brightness = 180;
  bool _sending = false;
  String _last = '还没下发过';

  Future<void> _send({double? ratio, double? brightness}) async {
    final provider = context.read<DeviceProvider>();
    final device = provider.activeDevice;
    if (device == null) {
      setState(() => _last = '还没有选中设备，先回首页刷新一下');
      return;
    }
    final r = (ratio ?? _ratio).round();
    final b = (brightness ?? _brightness).round();

    setState(() {
      _sending = true;
      _ratio = r.toDouble();
      _brightness = b.toDouble();
    });
    try {
      await provider.setLight(r, brightness: b);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _last = '已下发 → ${device.deviceId}：红光 $r% / 亮度 $b';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _last = '下发失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceProvider>().activeDevice;

    return Scaffold(
      appBar: AppBar(title: const Text('灯光调试')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(device == null ? Icons.link_off : Icons.link,
                      size: 18,
                      color: device == null
                          ? Colors.orange
                          : const Color(0xFF3B6D11)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      device == null
                          ? '未选中设备（回首页下拉刷新）'
                          : '${device.name} · ${device.deviceId} · ${device.online ? "在线" : "离线"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _slider(
            label: '红光占比',
            value: _ratio,
            max: 100,
            unit: '%',
            hint: '0% = 纯蓝光，100% = 纯红光',
            onChanged: (v) => setState(() => _ratio = v),
            onEnd: (v) => _send(ratio: v),
          ),
          const SizedBox(height: 12),
          _slider(
            label: '亮度',
            value: _brightness,
            max: 255,
            unit: '',
            hint: '0 = 关灯，255 = 最亮（48 颗 WS2812 全开约 3A，注意供电）',
            onChanged: (v) => setState(() => _brightness = v),
            onEnd: (v) => _send(brightness: v),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _preset('全红', 100, 180),
              _preset('全蓝', 0, 180),
              _preset('暖白', 60, 200),
              _preset('柔和', 50, 80),
              _preset('关灯', 50, 0),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _sending ? null : () => _send(),
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_sending ? '下发中...' : '应用当前设置'),
            ),
          ),
          const SizedBox(height: 16),
          Text(_last, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          const Text('说明', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            '· 指令走 MQTT：zhigu/<设备号>/command，固件收到后立即执行\n'
            '· 调试下发后 30 分钟内不会被“光照定时”覆盖，之后恢复自动\n'
            '· 亮度建议先给 60~120，48 颗全亮电流较大，USB 供电可能掉压',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _preset(String label, int ratio, int brightness) => OutlinedButton(
        onPressed: _sending
            ? null
            : () => _send(ratio: ratio.toDouble(), brightness: brightness.toDouble()),
        child: Text(label),
      );

  Widget _slider({
    required String label,
    required double value,
    required double max,
    required String unit,
    required String hint,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onEnd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('${value.round()}$unit',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32))),
          ],
        ),
        Slider(
          value: value,
          max: max,
          divisions: max.round(),
          onChanged: onChanged,
          onChangeEnd: onEnd,
        ),
        Text(hint, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}
