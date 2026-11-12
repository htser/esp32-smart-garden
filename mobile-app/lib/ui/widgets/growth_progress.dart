import 'package:flutter/material.dart';

/// 生长进度卡片
class GrowthProgress extends StatelessWidget {
  final String cropName;
  final int plantDay;
  final int totalDays;
  final String stage;

  const GrowthProgress({
    super.key,
    required this.cropName,
    required this.plantDay,
    required this.totalDays,
    required this.stage,
  });

  static const _stageInfo = {
    'seed': ('播种期', '保持基质湿润, 等待发芽', Icons.eco_outlined, Color(0xFF888780)),
    'sprout': ('发芽期', '幼苗出土, 注意保温', Icons.spa_outlined, Color(0xFF639922)),
    'growth': ('生长期', '快速生长, 保证水肥', Icons.local_florist_outlined, Color(0xFF2E7D32)),
    'harvest': ('收获期', '可以采摘啦!', Icons.agriculture_outlined, Color(0xFFBA7517)),
  };

  @override
  Widget build(BuildContext context) {
    final info = _stageInfo[stage] ?? _stageInfo['seed']!;
    final progress = (plantDay / totalDays).clamp(0.0, 1.0);
    final remain = (totalDays - plantDay).clamp(0, totalDays);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (info.$4).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(info.$4 as IconData, color: info.$4),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$cropName · 第$plantDay天',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Text(info.$2,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${(progress * 100).toInt()}%',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500,
                            color: Color(0xFF2E7D32))),
                    Text('剩$remain天',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 阶段指示器
            Row(
              children: List.generate(4, (i) {
                final stages = ['seed', 'sprout', 'growth', 'harvest'];
                final active = stages.indexOf(stage) >= i;
                final labels = ['播种', '发芽', '生长', '收获'];
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF2E7D32) : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(labels[i],
                            style: TextStyle(
                              fontSize: 10,
                              color: active ? const Color(0xFF2E7D32) : Colors.grey,
                              fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                            )),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
