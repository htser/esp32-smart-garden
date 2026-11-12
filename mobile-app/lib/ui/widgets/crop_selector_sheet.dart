import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';

/// 品种选择底部弹窗 - 九真十八品 + 慢病方案
class CropSelectorSheet extends StatelessWidget {
  const CropSelectorSheet._();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const CropSelectorSheet._(),
        ),
      ),
    );
  }

  static const _crops = [
    {'id': 'shengcai', 'name': '快菜', 'zhen': '菜真', 'days': 28, 'icon': '🥬', 'diff': 1},
    {'id': 'huanggua', 'name': '德惠老黄瓜', 'zhen': '子真', 'days': 55, 'icon': '🥒', 'diff': 2},
    {'id': 'tudou', 'name': '黄心土豆', 'zhen': '厍真', 'days': 90, 'icon': '🥔', 'diff': 1},
    {'id': 'pugongying', 'name': '蒲公英', 'zhen': '水真', 'days': 40, 'icon': '🌿', 'diff': 1},
    {'id': 'dasuanmiao', 'name': '大蒜苗', 'zhen': '菜真', 'days': 30, 'icon': '🌱', 'diff': 1},
    {'id': 'xihulu', 'name': '西葫芦', 'zhen': '果真', 'days': 50, 'icon': '🥒', 'diff': 2},
    {'id': 'ku_gua', 'name': '苦瓜', 'zhen': '季子苦', 'days': 70, 'icon': '🥬', 'diff': 2},
    {'id': 'zicao', 'name': '紫苏', 'zhen': '花真', 'days': 45, 'icon': '🌿', 'diff': 1},
  ];

  static const _plans = [
    {'id': 'diabetes', 'name': '糖尿病辅助管理', 'crops': '苦瓜/瓠瓜/南瓜'},
    {'id': 'hypertension', 'name': '高血压辅助管理', 'crops': '大蒜苗/芹菜/西瓜'},
    {'id': 'hyperlipidemia', 'name': '高血脂辅助管理', 'crops': '蒲公英/洋葱/豆角'},
    {'id': 'gastritis', 'name': '胃病调理', 'crops': '南瓜/山药/小白菜'},
    {'id': 'insomnia', 'name': '睡眠障碍调理', 'crops': '菊花/香蕉/薄荷'},
    {'id': 'immunity', 'name': '免疫力提升', 'crops': '西葫芦/胡萝卜/黄瓜'},
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('选择种植品种', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),
          const TabBar(
            labelColor: Color(0xFF2E7D32),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2E7D32),
            tabs: [Tab(text: '九真十八品'), Tab(text: '慢病定制方案')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCropList(context),
                _buildPlanList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _crops.map((c) => Card(
        elevation: 0,
        color: const Color(0xFFF6F8F3),
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFEAF3DE),
            child: Text(c['icon'] as String, style: const TextStyle(fontSize: 20)),
          ),
          title: Text('${c['name']} · ${c['zhen']}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text('${c['days']}天收获 · 难度 ${'★' * (c['diff'] as int)}'),
          trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32)),
          onTap: () {
            context.read<DeviceProvider>().setCrop(c['id'] as String);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已开始种植 ${c['name']}, 预计${c['days']}天收获')),
            );
          },
        ),
      )).toList(),
    );
  }

  Widget _buildPlanList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._plans.map((p) => Card(
          elevation: 0,
          color: const Color(0xFFF1F8E9),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFC8E6C9),
              child: Icon(Icons.favorite, color: Color(0xFF2E7D32)),
            ),
            title: Text(p['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(p['crops'] as String),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context),
          ),
        )),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('以上方案仅供饮食辅助参考, 不替代药物治疗。请遵医嘱使用。',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ),
      ],
    );
  }
}
