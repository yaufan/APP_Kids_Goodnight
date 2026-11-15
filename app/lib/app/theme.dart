import 'package:flutter/material.dart';

/// The app's colours (docs/design.md 「畫風：星光剪影風」): a deep blue
/// night; only warm lights, the stars and the moon are bright.
abstract final class Night {
  static const deep = Color(0xFF10142E);
  static const sky = Color(0xFF1B2150);
  static const skyLow = Color(0xFF2B3070);
  static const duskTop = Color(0xFF2E2C6E);
  static const duskLow = Color(0xFFC97A8C);
  static const card = Color(0xFF232A5C);
  static const cardEdge = Color(0xFF39427E);
  static const warm = Color(0xFFFFE6A6);
  static const warmDeep = Color(0xFFFFCB73);
  static const moon = Color(0xFFFFE8A8);
  static const text = Color(0xFFF2EAD3);
  static const soft = Color(0xFFA9B0DA);
  static const faint = Color(0xFF6F78AE);
  static const silhouette = Color(0xFF24193A);

  // Parent mode is a plain, light page (it is for grown-ups, and short).
  static const parentBg = Color(0xFFF3F1F7);
  static const parentInk = Color(0xFF2C2A3A);
  static const parentSoft = Color(0xFF7A768C);
  static const accent = Color(0xFF4A8F8C);
}

abstract final class NightTheme {
  /// jf open 粉圓 (OFL): a rounded typeface made in Taiwan.
  static const font = 'Huninn';

  static ThemeData dark() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Night.accent, brightness: Brightness.dark, surface: Night.deep),
      scaffoldBackgroundColor: Night.deep,
      fontFamily: font,
    );
    return base.copyWith(textTheme: base.textTheme.apply(bodyColor: Night.text, displayColor: Night.text, fontFamily: font));
  }

  static ThemeData parent() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Night.accent, surface: Colors.white),
      scaffoldBackgroundColor: Night.parentBg,
      fontFamily: font,
    );
    return base.copyWith(textTheme: base.textTheme.apply(bodyColor: Night.parentInk, displayColor: Night.parentInk, fontFamily: font));
  }
}
