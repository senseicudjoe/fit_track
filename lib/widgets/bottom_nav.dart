import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final _tabs = const [
    _Tab(icon: Icons.home_outlined,        activeIcon: Icons.home,        label: 'Home',    path: '/dashboard'),
    _Tab(icon: Icons.add_circle_outline,   activeIcon: Icons.add_circle,  label: 'Log',     path: '/log'),
    _Tab(icon: Icons.flag_outlined,        activeIcon: Icons.flag,        label: 'Goals',   path: '/goals'),
    _Tab(icon: Icons.bar_chart_outlined,   activeIcon: Icons.bar_chart,   label: 'Progress',path: '/progress'),
    _Tab(icon: Icons.person_outline,       activeIcon: Icons.person,      label: 'Profile', path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: _tabs.map((tab) {
              final active = location.startsWith(tab.path);
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.go(tab.path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? tab.activeIcon : tab.icon,
                        color: active
                            ? AppColors.primary
                            : AppColors.textHint,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: active
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final IconData icon, activeIcon;
  final String label, path;
  const _Tab({
    required this.icon, required this.activeIcon,
    required this.label, required this.path,
  });
}