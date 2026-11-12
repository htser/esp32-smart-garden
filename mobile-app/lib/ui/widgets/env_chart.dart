import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 环境趋势折线图卡片
class EnvChartCard extends StatelessWidget {
  final String field;
  final int hours;
  const EnvChartCard({super.key, required this.field, required this.hours});

  static const _meta = {
    'soil': ('土壤湿度', '%', Color(0xFF185FA5), 0, 100),
    'air_temp': ('空气温度', '°C', Color(0xFFC62828), 0, 40),
    'air_humidity': ('空气湿度', '%', Color(0xFF0F6E56), 0, 100),
    'lux': ('光照强度', 'lux', Color(0xFFBA7517), 0, 10000),
  };

  @override
  Widget build(BuildContext context) {
    final m = _meta[field] ?? _meta['soil']!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$hours小时趋势 · ${m.$1}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Text(m.$2, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (m.$5 - m.$4) / 4,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, reservedSize: 38,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, interval: 6,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}h',
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: (m.$4 as num).toDouble(), maxY: (m.$5 as num).toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _demoData(),
                      isCurved: true,
                      color: m.$3,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: m.$3.withValues(alpha: 0.10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 演示数据 - 生产环境替换为 API 返回
  List<FlSpot> _demoData() {
    final base = { 'soil': 60.0, 'air_temp': 22.0, 'air_humidity': 58.0, 'lux': 4500.0 }[field] ?? 60.0;
    return List.generate(13, (i) {
      final noise = [0, 3, -2, 4, -3, 2, -1, 5, -4, 1, 3, -2, 0][i] * (base * 0.02);
      return FlSpot((i * 2).toDouble(), base + noise);
    });
  }
}
