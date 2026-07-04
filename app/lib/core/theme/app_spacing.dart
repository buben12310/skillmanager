// 对照 DESIGN_SPEC §6.3 圆角 / §6.4 间距
import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 12;
}

class AppSpacing {
  AppSpacing._();
  static const double pagePadding = 20;
  static const double cardPadding = 16;
  static const double cardPaddingSm = 12;
  static const double rowHeight = 44;
  static const double rowHeightLg = 48;
  static const double itemGap = 8;
  static const double itemGapSm = 4;
  static const double sectionGap = 16;
  static const double elementGap = 12;
  static const double elementGapSm = 8;
}

class AppBorder {
  AppBorder._();
  static BorderSide thin = const BorderSide(
    width: 0.5,
    color: Color(0x26000000),
  );
}
