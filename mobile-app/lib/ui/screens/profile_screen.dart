import 'package:flutter/material.dart';
import 'provision_screen.dart';

/// 我的 - 个人中心
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          // 用户信息
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text('王', style: TextStyle(fontSize: 22, color: Color(0xFF2E7D32))),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('种植小王子', style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w500, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('ID: 8829103 · 加入128天', style: TextStyle(
                          fontSize: 12, color: Color(0xCCFFFFFF))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('社区达人', style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ],
            ),
          ),

          // 种植统计
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _ProfileStat(value: '23', label: '累计种植'),
                _ProfileStat(value: '18.6', label: '累计收获(kg)'),
                _ProfileStat(value: '96', label: '健康积分'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 功能列表
          _MenuGroup(
            title: '我的种植',
            items: [
              _MenuItem(Icons.eco, '我的种植计划', '3个进行中'),
              _MenuItem(Icons.photo_library, '种植相册', '128张照片'),
              _MenuItem(Icons.insights, '健康报告', '查看月度报告'),
              _MenuItem(Icons.family_restroom, '家庭群组', '3位成员'),
            ],
          ),
          _MenuGroup(
            title: '账户与订单',
            items: [
              _MenuItem(Icons.receipt_long, '我的订单', ''),
              _MenuItem(Icons.card_membership, '会员中心', '社区会员'),
              _MenuItem(Icons.local_shipping, '收货地址', '2个地址'),
              _MenuItem(Icons.headset_mic, '联系客服', '7×12小时'),
            ],
          ),
          _MenuGroup(
            title: '设置',
            items: [
              _MenuItem(Icons.bluetooth, '设备配网', ''),
              _MenuItem(Icons.notifications_outlined, '消息通知', ''),
              _MenuItem(Icons.privacy_tip_outlined, '隐私与数据', ''),
              _MenuItem(Icons.info_outline, '关于智菇小站', 'v1.0.0'),
            ],
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text('智菇小站 · 让每个家庭都能种出健康',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF2E7D32))),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ),
          ...items.map((e) => e.build()),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String trailing;
  const _MenuItem(this.icon, this.title, this.trailing);
}

extension _MenuItemWidget on _MenuItem {
  Widget build() {
    return Builder(builder: (context) => ListTile(
      leading: Icon(icon, size: 20, color: const Color(0xFF3B6D11)),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty)
            Text(trailing, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
      onTap: () {
        if (title == '设备配网') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProvisionScreen()),
          );
        }
      },
    ));
  }
}
