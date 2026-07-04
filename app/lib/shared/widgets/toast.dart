// 对照 DESIGN_SPEC §4.6 Toast 提示
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

class ToastService {
  ToastService._();
  static final ToastService instance = ToastService._();
  final _overlay = ToastOverlayController();

  void show(BuildContext context, String message) {
    _overlay.show(context, message);
  }
}

class ToastOverlayController {
  OverlayEntry? _entry;

  void show(BuildContext context, String message) {
    hide();
    _entry = OverlayEntry(
      builder: (_) => _ToastView(message: message),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    Future.delayed(const Duration(seconds: 2), hide);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xE62C2C2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// 简便调用
void showToast(BuildContext context, String message) {
  ToastService.instance.show(context, message);
}
