import 'package:flutter/material.dart';

import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';
import '../../features/vehicle/presentation/screens/home_screen.dart';
import '../../features/voice/presentation/screens/voice_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../motion/app_haptics.dart';
import '../motion/scene_motion.dart';
import 'animated_background.dart';
import 'subtle_particle_field.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final SceneMotionController _scene;

  final _pages = const <Widget>[
    HomeScreen(),
    ExpensesScreen(),
    TripsScreen(),
    VoiceScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _scene = SceneMotionController();
  }

  @override
  void dispose() {
    _scene.dispose();
    super.dispose();
  }

  void _selectTab(int i) {
    if (i == _index) return;
    AppHaptics.selection();
    _scene.onTabChanged(_index, i);
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: isDark ? (e) => _scene.setTouchFromLocal(e.localPosition, size) : null,
            onPointerUp: isDark ? (_) => _scene.clearTouch() : null,
            onPointerCancel: isDark ? (_) => _scene.clearTouch() : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isDark) ...[
                  AnimatedBackground(motion: _scene),
                  SubtleParticleField(motion: _scene),
                ] else
                  ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
                NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (!isDark) return false;
                    if (n is ScrollUpdateNotification) {
                      final d = n.scrollDelta ?? 0.0;
                      if (n.metrics.axis == Axis.vertical) {
                        _scene.onScrollDelta(d);
                      } else if (n.metrics.axis == Axis.horizontal) {
                        _scene.onScrollDelta(-d * 0.22);
                      }
                    }
                    return false;
                  },
                  child: _pages[_index],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.mic_none), selectedIcon: Icon(Icons.mic), label: 'Voice'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
