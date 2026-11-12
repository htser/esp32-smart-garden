import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/app_config.dart';
import 'services/api_service.dart';
import 'providers/device_provider.dart';
import 'providers/user_provider.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/health_screen.dart';
import 'ui/screens/shop_screen.dart';
import 'ui/screens/community_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('zhigu_cache');

  runApp(const ZhiguApp());
}

class ZhiguApp extends StatelessWidget {
  const ZhiguApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        Provider(create: (_) => ApiService(baseUrl: AppConfig.baseUrl)),
      ],
      child: MaterialApp(
        title: '智菇小站',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainShell(),
      ),
    );
  }
}

/// 主框架: 底部导航 + 4个Tab
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 首帧后：把 ApiService 注入 DeviceProvider，并拉取设备列表。
    // 之前没有任何地方调用 setApi/loadDevices，所以首页永远显示“未绑定设备”。
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final api = context.read<ApiService>();
    final user = context.read<UserProvider>();
    final devices = context.read<DeviceProvider>();

    devices.setApi(api);
    if (user.userId.isEmpty) {
      // 目前还没有登录页，先落到调试账号（与后端 DEMO_USER_ID 一致）
      await user.loginWithWeChat();
    }
    await devices.loadDevices(user.userId);
  }

  final _pages = const [
    DashboardScreen(),
    HealthScreen(),
    ShopScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass),
            label: '我的菜园',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: '健康管理',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: '商城',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: '社区',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
