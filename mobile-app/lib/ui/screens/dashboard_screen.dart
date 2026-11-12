import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import 'light_debug_screen.dart';
import '../widgets/stat_card.dart';
import '../widgets/env_chart.dart';
import '../widgets/growth_progress.dart';
import '../widgets/device_actions.dart';
import '../widgets/crop_selector_sheet.dart';

/// 我的菜园 - 种植监控看板
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService(baseUrl: AppConfig.baseUrl);
  Map<String, dynamic>? _advice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdvice();
  }

  Future<void> _loadAdvice() async {
    try {
      final res = await _api.healthAdvice({
        'age': 45, 'gender': 'male', 'height_cm': 172, 'weight_kg': 70,
        'conditions': ['hypertension'],
      }, 'ZG-A1B2C3D4');
      setState(() {
        _advice = res['data'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceProvider>().activeDevice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的菜园'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: '灯光调试',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LightDebugScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _showBindSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<DeviceProvider>().refresh();
          await _loadAdvice();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // 设备状态卡
            _DeviceHeaderCard(device: device),

            const SizedBox(height: 12),

            // 环境指标 2x2
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: StatCard(
                    icon: Icons.water_drop_outlined,
                    label: '土壤湿度',
                    value: device?.soilMoisture ?? 0,
                    unit: '%',
                    color: const Color(0xFF185FA5),
                    progress: (device?.soilMoisture ?? 0) / 100,
                    target: '目标 55-65%',
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(
                    icon: Icons.thermostat_outlined,
                    label: '空气温度',
                    value: device?.airTemp ?? 0,
                    unit: '°C',
                    color: const Color(0xFFC62828),
                    progress: ((device?.airTemp ?? 0) / 40).clamp(0, 1),
                    target: '目标 18-28°C',
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: StatCard(
                    icon: Icons.opacity_outlined,
                    label: '空气湿度',
                    value: device?.airHumidity ?? 0,
                    unit: '%',
                    color: const Color(0xFF0F6E56),
                    progress: (device?.airHumidity ?? 0) / 100,
                    target: '目标 50-70%',
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(
                    icon: Icons.lightbulb_outline,
                    label: '光照强度',
                    value: device?.lux ?? 0,
                    unit: 'lux',
                    color: const Color(0xFFBA7517),
                    progress: ((device?.lux ?? 0) / 10000).clamp(0, 1),
                    target: '灯照 6:00-22:00',
                  )),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 生长进度
            GrowthProgress(
              cropName: device?.currentCrop.isNotEmpty == true
                  ? device!.currentCrop : '快菜',
              plantDay: device?.plantDay ?? 0,
              totalDays: 28,
              stage: device?.stage ?? 'seed',
            ),

            const SizedBox(height: 12),

            // 24小时趋势
            const EnvChartCard(field: 'soil', hours: 24),

            const SizedBox(height: 12),

            // 今日健康建议
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_advice != null)
              _AdviceCard(advice: _advice!),

            const SizedBox(height: 12),
            const DeviceActions(),
          ],
        ),
      ),
    );
  }

  void _showBindSheet(BuildContext context) {
    final ctrl = TextEditingController();
    final api = context.read<ApiService>();
    final user = context.read<UserProvider>();
    final devices = context.read<DeviceProvider>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('绑定新设备',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: '设备编号',
                hintText: 'ZG-XXXX (设备底部标签)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final id = ctrl.text.trim().toUpperCase();
                if (id.isEmpty) return;
                try {
                  final res = await api.bindDevice(id, user.userId);
                  await devices.loadDevices(user.userId);
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['message']?.toString() ?? '绑定成功'),
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('绑定失败: $e'),
                    ));
                  }
                }
              },
              child: const Text('绑定'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(sheetCtx),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceHeaderCard extends StatelessWidget {
  final DeviceState? device;
  const _DeviceHeaderCard({this.device});

  @override
  Widget build(BuildContext context) {
    final online = device?.online ?? false;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.grass, color: Color(0xFF3B6D11), size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device?.name ?? '未绑定设备',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: online ? const Color(0xFF3B6D11) : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        online ? '在线 · ${device?.firmware ?? ''}' : '离线',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => CropSelectorSheet.show(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('选品种'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final Map<String, dynamic> advice;
  const _AdviceCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    final diet = (advice['diet'] as List?) ?? [];
    final activity = (advice['activity'] as List?) ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 8),
                const Text('今日健康建议', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
            if (advice['plant_tip'] != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3DE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.spa, color: Color(0xFF3B6D11), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(advice['plant_tip'],
                        style: const TextStyle(fontSize: 12, color: Color(0xFF27500A)))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            ...diet.map((d) => _bullet(Icons.restaurant_menu, d)),
            ...activity.map((a) => _bullet(Icons.directions_walk, a)),
          ],
        ),
      ),
    );
  }

  Widget _bullet(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}
