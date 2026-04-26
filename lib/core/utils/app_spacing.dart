import 'package:flutter/widgets.dart';

/// Design-system spacing scale (8 / 12 / 16 / 20 / 24).
class AppSpacing {
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(vertical: s16);
  static const EdgeInsets sectionPadding = EdgeInsets.only(top: s24);
  static const EdgeInsets cardPadding = EdgeInsets.all(s16);
  static const EdgeInsets listGap = EdgeInsets.only(bottom: s12);
}

