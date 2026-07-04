// 对照 DESIGN_SPEC §2.1 底部导航栏
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../layouts/detail_nav_state.dart';

enum NavTab { agents, marketplace, settings }

final currentNavTabProvider = StateProvider<NavTab>((ref) => NavTab.agents);

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentNavTabProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(
          top: BorderSide(width: 0.5, color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          _NavItem(
            tab: NavTab.agents,
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view,
            label: 'Agents',
            selected: current == NavTab.agents,
            onTap: () => _switchTab(ref, NavTab.agents),
          ),
          _NavItem(
            tab: NavTab.marketplace,
            icon: Icons.store_outlined,
            activeIcon: Icons.store,
            label: '技能市场',
            selected: current == NavTab.marketplace,
            onTap: () => _switchTab(ref, NavTab.marketplace),
          ),
          _NavItem(
            tab: NavTab.settings,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: '设置',
            selected: current == NavTab.settings,
            onTap: () => _switchTab(ref, NavTab.settings),
          ),
        ],
      ),
    );
  }

  void _switchTab(WidgetRef ref, NavTab tab) {
    ref.read(currentNavTabProvider.notifier).state = tab;
    // 清空详情栈,让根 Tab 可见
    ref.read(detailStackProvider.notifier).clear();
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final NavTab tab;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textTertiary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                color: color,
                size: 22,
                fill: selected ? 1.0 : 0.0,
              ),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
