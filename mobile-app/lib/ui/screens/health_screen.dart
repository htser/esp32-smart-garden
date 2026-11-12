import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../widgets/stat_card.dart';
import 'chronic_assessment_screen.dart';

/// 健康管理 - 群集管理理念的三层入口
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final _api = ApiService(baseUrl: 'https://api.zhigu.example.com');
  List<dynamic> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final res = await _api.listPlans();
    if (res['code'] == 0) {
      setState(() {
        _plans = res['data'] as List;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('健康管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // 群集管理理念横幅
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('改善畅通群集管理',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                      SizedBox(height: 6),
                      Text('种植 → 食用 → 数据 → 健康, 让健康管理融入每一天',
                          style: TextStyle(fontSize: 13, color: Color(0xE6FFFFFF))),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 慢病种植定制入口（检查指标 → 专业种植方案）
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2E7D32), width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x142E7D32), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChronicAssessmentScreen()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.monitor_heart_outlined,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('慢病种植定制 · 智能评估',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w600)),
                                  SizedBox(height: 4),
                                  Text('填写检查指标，自动分层并生成专属种植方案',
                                      style:
                                          TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFF2E7D32)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 三层入口
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _LayerCard(icon: Icons.person, title: '个人', desc: '健康档案\n饮食记录', color: const Color(0xFF185FA5), onTap: () {}),
                      const SizedBox(width: 10),
                      _LayerCard(icon: Icons.family_restroom, title: '家庭', desc: '亲子种植\n家庭报告', color: const Color(0xFF2E7D32), onTap: () {}),
                      const SizedBox(width: 10),
                      _LayerCard(icon: Icons.groups, title: '社区', desc: '邻里互助\n群集统计', color: const Color(0xFFBA7517), onTap: () {}),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 今日健康数据
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('今日健康数据', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: StatCard(
                        icon: Icons.restaurant_menu, label: '今日摄入',
                        value: 1650, unit: 'kcal', color: const Color(0xFF2E7D32),
                        progress: 0.55, target: '目标 2100 kcal')),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(
                        icon: Icons.directions_walk, label: '今日步数',
                        value: 6820, unit: '步', color: const Color(0xFF185FA5),
                        progress: 0.68, target: '目标 10000 步')),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 慢病方案
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('慢病定制化种植方案',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('选择方案后, 系统为您推荐种植品种与饮食建议',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                ..._plans.map((p) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text('${p['crop_count']}种',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32))),
                    ),
                    title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(p['disclaimer'], maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // 进入慢病评估, 预选该病种
                      final planId = p['id']?.toString();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChronicAssessmentScreen(
                            initialConditions:
                                planId != null ? [planId] : const [],
                          ),
                        ),
                      );
                    },
                  ),
                )),
              ],
            ),
    );
  }
}

class _LayerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  const _LayerCard({
    required this.icon, required this.title, required this.desc,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x14000000)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(desc, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
