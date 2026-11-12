import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';

/// 设备快捷操作: 浇水/灯光/配时/识别
class DeviceActions extends StatelessWidget {
  const DeviceActions({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('快捷操作', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: Icons.water_drop,
                  label: '立即浇水',
                  color: const Color(0xFF185FA5),
                  onTap: () => provider.water(duration: 3),
                ),
                _ActionButton(
                  icon: Icons.light_mode,
                  label: '补光10分钟',
                  color: const Color(0xFFBA7517),
                  onTap: () => provider.setLight(50, brightness: 220),
                ),
                _ActionButton(
                  icon: Icons.schedule,
                  label: '光照定时',
                  color: const Color(0xFF5F5E5A),
                  onTap: () => _showScheduleSheet(context),
                ),
                _ActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: '拍照识别',
                  color: const Color(0xFF3B6D11),
                  onTap: () => _showIdentifySheet(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleSheet(BuildContext context) {
    int onHour = 6, offHour = 22;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('生长灯定时', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('开灯时间'),
                  const Spacer(),
                  DropdownButton<int>(
                    value: onHour,
                    items: List.generate(24, (i) =>
                        DropdownMenuItem(value: i, child: Text('$i:00'))),
                    onChanged: (v) => setState(() => onHour = v!),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('关灯时间'),
                  const Spacer(),
                  DropdownButton<int>(
                    value: offHour,
                    items: List.generate(24, (i) =>
                        DropdownMenuItem(value: i, child: Text('$i:00'))),
                    onChanged: (v) => setState(() => offHour = v!),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<DeviceProvider>().setSchedule(onHour, offHour);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('定时已同步到设备')),
                    );
                  },
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIdentifySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('AI 识别', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
              title: const Text('拍照识别品种'),
              subtitle: const Text('不知道种的什么? 拍一张'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.healing, color: Color(0xFFC62828)),
              title: const Text('病虫害诊断'),
              subtitle: const Text('叶片有异常? 拍照检测'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.insights, color: Color(0xFF185FA5)),
              title: const Text('生长阶段判定'),
              subtitle: const Text('结合种植天数智能分析'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
