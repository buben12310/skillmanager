import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/settings_page.dart';
import 'shared/layouts/app_scaffold.dart';

class SkillManagerApp extends ConsumerWidget {
  const SkillManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);

    // 先应用亮度和强调色,确保 AppColors 状态正确
    final isDark = themeMode == ThemeMode.dark;
    AppColors.applyBrightness(isDark ? Brightness.dark : Brightness.light);
    AppColors.applyAccent(accent);

    // 只构建当前主题,避免 light()/dark() 同时执行导致 AppColors 状态被覆盖
    // ValueKey 强制在主题/强调色变化时完整重建
    return MaterialApp(
      key: ValueKey('theme-${themeMode.name}-$accent'),
      title: 'Agent Skill Manager',
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.dark() : AppTheme.light(),
      home: const AppScaffold(),
    );
  }
}
