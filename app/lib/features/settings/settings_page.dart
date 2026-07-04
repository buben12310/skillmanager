// 对照 DESIGN_SPEC §3.6 设置页
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/toast.dart';
import 'backup_service.dart';

// 主题相关 provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());
final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((ref) => AccentColorNotifier());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString('themeMode') ?? 'light';
    state = v == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }
  Future<void> set(ThemeMode mode) async {
    state = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString('themeMode', mode == ThemeMode.dark ? 'dark' : 'light');
  }
}

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier() : super(AppColors.primary) {
    _load();
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getInt('accentColor');
    if (v != null) {
      state = Color(v);
      AppColors.applyAccent(state);
    }
  }
  Future<void> set(Color c) async {
    state = c;
    AppColors.applyAccent(c);
    final p = await SharedPreferences.getInstance();
    await p.setInt('accentColor', c.toARGB32());
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
              SizedBox(width: 10),
              Text('设置', style: AppTextStyles.pageTitle),
            ],
          ),
          SizedBox(height: 24),
          _Section(
            title: '外观',
            children: [
              _Row(
                label: '主题',
                child: _SegmentedControl(
                  items: const ['浅色', '深色'],
                  selectedIndex: themeMode == ThemeMode.dark ? 1 : 0,
                  onSelect: (i) => ref.read(themeModeProvider.notifier).set(i == 1 ? ThemeMode.dark : ThemeMode.light),
                ),
              ),
              SizedBox(height: 8),
              _Row(
                label: '强调色',
                child: Row(
                  children: AppColors.accentPresets.asMap().entries.map((e) {
                    final c = e.value;
                    return Padding(
                      padding: EdgeInsets.only(right: e.key < AppColors.accentPresets.length - 1 ? 8 : 0),
                      child: _ColorDot(
                        color: c,
                        selected: accent.toARGB32() == c.toARGB32(),
                        onTap: () => ref.read(accentColorProvider.notifier).set(c),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _Section(
            title: '市场源',
            children: [
              _Row(
                label: 'GitHub  技能市场唯一来源',
                child: Icon(Icons.toggle_on, color: AppColors.success, size: 36),
              ),
            ],
          ),
          SizedBox(height: 16),
          _Section(
            title: '数据',
            children: [
              _Row(
                label: '导出全部数据',
                child: SecondaryButton(
                  label: '导出',
                  icon: Icons.download,
                  onPressed: () => _exportAll(context, ref),
                ),
              ),
              SizedBox(height: 8),
              _Row(
                label: '导入数据',
                child: SecondaryButton(
                  label: '导入',
                  icon: Icons.upload,
                  onPressed: () => showToast(context, '导入功能将在下一版本实现'),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _Section(
            title: '关于',
            children: [
              _Row(label: '版本', child: Text('1.0.0', style: AppTextStyles.body)),
              _Row(
                label: '检查更新',
                child: TextButtonX(
                  label: '检查',
                  icon: Icons.refresh,
                  onPressed: () => showToast(context, '已是最新版本'),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Agent Skill Manager v1.0.0\nPhase 1 演示版本,部分功能将在后续 Phase 落地。',
              style: AppTextStyles.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAll(BuildContext context, WidgetRef ref) async {
    showToast(context, '正在导出...');
    try {
      final path = await ref.read(backupServiceProvider).exportAll();
      if (!context.mounted) return;
      showToast(context, '已导出: $path');
    } catch (e) {
      if (!context.mounted) return;
      showToast(context, '导出失败: $e');
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 0.5, color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.panelTitle),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.body),
          Spacer(),
          child,
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.items, required this.selectedIndex, required this.onSelect});
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.asMap().entries.map((e) {
          final selected = e.key == selectedIndex;
          return InkWell(
            onTap: () => onSelect(e.key),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.bgPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(e.value, style: AppTextStyles.body.copyWith(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              )),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.selected, required this.onTap});
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: selected ? 2 : 0),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 0, spreadRadius: 2)]
              : null,
        ),
      ),
    );
  }
}
