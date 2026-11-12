import 'package:flutter/material.dart';

/// 商城 - 设备/租赁/基质板/种子/会员
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商城'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E7D32),
          indicatorColor: const Color(0xFF2E7D32),
          tabs: const [
            Tab(text: '设备购买'),
            Tab(text: '家庭租赁'),
            Tab(text: '种植补给'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDeviceTab(),
          _buildRentalTab(),
          _buildSupplyTab(),
        ],
      ),
    );
  }

  Widget _buildDeviceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProductCard(
          name: '智菇小站 S1 标准版',
          price: '¥1,299',
          originalPrice: '¥1,599',
          desc: '6种植位 · 全光谱生长灯 · AI识别 · 4.3寸触控屏',
          tags: const ['热销', '新品'],
          gradient: const [Color(0xFFEAF3DE), Color(0xFFF1F8E9)],
        ),
        _ProductCard(
          name: '智菇小站 S1 Pro',
          price: '¥1,999',
          originalPrice: '¥2,499',
          desc: '8种植位 · 双摄像头 · 增湿模块 · 语音控制',
          tags: const ['旗舰'],
          gradient: const [Color(0xFFFAEEDA), Color(0xFFFFF8E1)],
        ),
      ],
    );
  }

  Widget _buildRentalTab() {
    final plans = [
      {'name': '基础版', 'price': '¥99/月', 'devices': '1台设备',
       'includes': ['基础基质板', '4种种子/6个月', '社区自提'], 'color': const Color(0xFFE6F1FB)},
      {'name': '标准版', 'price': '¥199/月', 'devices': '1台设备',
       'includes': ['富硒功能土', '8种种子/6个月', 'AI健康建议', '免费配送'], 'color': const Color(0xFFE8F5E9), 'hot': true},
      {'name': '高级版', 'price': '¥399/月', 'devices': '2台设备',
       'includes': ['富硒功能土', '九真十八品全套', '1对1健康咨询/月', '优先配送'], 'color': const Color(0xFFF3E5F5)},
      {'name': '专属定制版', 'price': '¥599/月起', 'devices': '定制方案',
       'includes': ['慢病定制方案', '专属健康管理师', '每周回访'], 'color': const Color(0xFFFAEEDA)},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: plans.map((p) {
        final hot = p['hot'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: p['color'] as Color,
            borderRadius: BorderRadius.circular(16),
            border: hot ? Border.all(color: const Color(0xFF2E7D32), width: 1.5) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(p['name'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    if (hot) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('最受欢迎',
                            style: TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    ],
                    const Spacer(),
                    Text(p['price'] as String,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF2E7D32))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(p['devices'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: (p['includes'] as List).map((f) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(f as String, style: const TextStyle(fontSize: 11)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: hot
                        ? null
                        : ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2E7D32)),
                    child: Text(hot ? '立即租赁' : '选择方案'),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSupplyTab() {
    final supplies = [
      {'name': '生物基质板 6片装', 'price': '¥19.9', 'unit': '/月', 'icon': Icons.layers},
      {'name': '富硒功能土 补充装', 'price': '¥24.9', 'unit': '/袋', 'icon': Icons.grass},
      {'name': '九真十八品 种子盲盒', 'price': '¥6.9', 'unit': '/包', 'icon': Icons.casino_outlined},
      {'name': '慢病定制种子组合', 'price': '¥29.9', 'unit': '/套', 'icon': Icons.medical_services_outlined},
      {'name': '营养液 有机肥', 'price': '¥15.9', 'unit': '/瓶', 'icon': Icons.science},
      {'name': '社区会员月卡', 'price': '¥49', 'unit': '/月', 'icon': Icons.card_membership},
    ];

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: supplies.map((s) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x14000000)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(s['icon'] as IconData, color: const Color(0xFF3B6D11)),
            ),
            const Spacer(),
            Text(s['name'] as String,
                maxLines: 2,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3)),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: s['price'] as String,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2E7D32)),
                ),
                TextSpan(
                  text: s['unit'] as String,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                ),
                child: const Text('加入购物车', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String originalPrice;
  final String desc;
  final List<String> tags;
  final List<Color> gradient;

  const _ProductCard({
    required this.name, required this.price, required this.originalPrice,
    required this.desc, required this.tags, required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: gradient[0],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: gradient[1],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.grass, size: 44, color: Color(0xFF3B6D11)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(t, style: const TextStyle(fontSize: 10, color: Colors.white)),
                    )).toList(),
                  ),
                  const SizedBox(height: 6),
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(price, style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFFC62828))),
                      const SizedBox(width: 6),
                      Text(originalPrice, style: TextStyle(
                          fontSize: 11, color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
