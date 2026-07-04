// 对照 DESIGN_SPEC §7.1 滑动开关 36x18
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 18,
        padding: EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: value ? AppColors.successLight : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: value ? AppColors.success : AppColors.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
