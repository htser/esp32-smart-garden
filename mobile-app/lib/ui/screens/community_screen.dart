import 'package:flutter/material.dart';

/// 社区 - 邻里种植交流 + 社区站
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('社区')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // 我的社区站
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.location_city, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('哈尔滨 · 碧水庄园社区站',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            SizedBox(height: 3),
                            Text('服务周边5个小区 · 覆盖 3,200 户',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('切换'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatBox(label: '社区设备', value: '86', unit: '台'),
                      _StatBox(label: '活跃邻居', value: '412', unit: '人'),
                      _StatBox(label: '本周团购', value: '23', unit: '单'),
                      _StatBox(label: '累计收获', value: '1.2', unit: '吨'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 邻里动态
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('邻里动态', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          _PostCard(
            user: '花匠老李',
            avatar: '李',
            time: '2小时前',
            content: '我的紫苏丰收了! 用了富硒功能土, 香味比菜市场买的浓多了。周末烧烤正好用上!',
            images: 2,
            likes: 36,
            comments: 12,
            crop: '紫苏 · 45天',
          ),
          _PostCard(
            user: '控糖的张阿姨',
            avatar: '张',
            time: '5小时前',
            content: '跟着糖尿病方案种的苦瓜可以收了, 清炒了一盘。坚持吃了两个月, 今早测血糖比之前稳了不少, 分享给群里糖友们!',
            images: 3,
            likes: 89,
            comments: 34,
            crop: '苦瓜 · 70天',
          ),
          _PostCard(
            user: '豆豆妈',
            avatar: '豆',
            time: '昨天',
            content: '带孩子种的小土豆刨出来了, 小家伙兴奋了一整天。这比玩手机强多了, 已经准备种下一批大蒜苗。',
            images: 4,
            likes: 56,
            comments: 18,
            crop: '黄心土豆 · 90天',
          ),
          _PostCard(
            user: '社区站·小王',
            avatar: '王',
            time: '昨天',
            content: '本周社区团购开始接龙: 蒲公英嫩叶 5元/份, 快菜 3.5元/份, 德惠老黄瓜 4元/根。明晚8点统一配送!',
            images: 1,
            likes: 45,
            comments: 67,
            crop: '社区团购',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add),
        label: const Text('发布动态'),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _StatBox({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8F3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(text: value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2E7D32))),
                TextSpan(text: ' $unit',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            ),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String user;
  final String avatar;
  final String time;
  final String content;
  final int images;
  final int likes;
  final int comments;
  final String crop;

  const _PostCard({
    required this.user, required this.avatar, required this.time,
    required this.content, required this.images, required this.likes,
    required this.comments, required this.crop,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text(avatar,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(crop, style: const TextStyle(fontSize: 10, color: Color(0xFF3B6D11))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(fontSize: 13, height: 1.5)),
            const SizedBox(height: 10),
            // 图片占位
            Row(
              children: List.generate(
                images > 3 ? 3 : images,
                (i) => Container(
                  width: 80, height: 80,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3DE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_outlined, color: Color(0xFF97C459)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.thumb_up_alt_outlined, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('$likes', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('$comments', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const Spacer(),
                Icon(Icons.share_outlined, size: 14, color: Colors.grey[500]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
