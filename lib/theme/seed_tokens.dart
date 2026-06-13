// GENERATED — do not edit. Source: tokens/tokens.json (run `npm run build`).
import 'package:flutter/widgets.dart';

/// 라이트/다크 시맨틱 컬러 스킴(단일 소스). client `DkTokens` 의 기본값 출처.
@immutable
class SeedScheme {
  const SeedScheme({
    required this.bg,
    required this.bgSubtle,
    required this.bgPress,
    required this.page,
    required this.fgStrong,
    required this.fg,
    required this.fgMuted,
    required this.fgSubtle,
    required this.fgDisabled,
    required this.border,
    required this.borderSubtle,
    required this.borderStrong,
    required this.overlay,
    required this.success,
    required this.successSubtle,
    required this.successFg,
    required this.warning,
    required this.warningSubtle,
    required this.warningFg,
    required this.danger,
    required this.dangerSubtle,
    required this.info,
    required this.infoSubtle,
    required this.infoFg,
    required this.violetSubtle,
    required this.violetFg,
    required this.ink,
    required this.onInk,
    required this.onInkMuted,
    required this.primary,
    required this.primaryHover,
    required this.primarySubtle,
  });

  final Color bg;
  final Color bgSubtle;
  final Color bgPress;
  final Color page;
  final Color fgStrong;
  final Color fg;
  final Color fgMuted;
  final Color fgSubtle;
  final Color fgDisabled;
  final Color border;
  final Color borderSubtle;
  final Color borderStrong;
  final Color overlay;
  final Color success;
  final Color successSubtle;
  final Color successFg;
  final Color warning;
  final Color warningSubtle;
  final Color warningFg;
  final Color danger;
  final Color dangerSubtle;
  final Color info;
  final Color infoSubtle;
  final Color infoFg;
  final Color violetSubtle;
  final Color violetFg;
  final Color ink;
  final Color onInk;
  final Color onInkMuted;
  final Color primary;
  final Color primaryHover;
  final Color primarySubtle;

  static const SeedScheme light = SeedScheme(
    bg: Color(0xFFFFFFFF),
    bgSubtle: Color(0xFFF7F7F8),
    bgPress: Color(0xFFF1F2F4),
    page: Color(0xFFF7F7F8),
    fgStrong: Color(0xFF0A0A0B),
    fg: Color(0xFF1A1B1E),
    fgMuted: Color(0xDC2E2F33),
    fgSubtle: Color(0x9437383C),
    fgDisabled: Color(0x4D37383C),
    border: Color(0x3870737C),
    borderSubtle: Color(0x1F70737C),
    borderStrong: Color(0x6670737C),
    overlay: Color(0x6B171719),
    success: Color(0xFF00BF40),
    successSubtle: Color(0xFFE3FBEC),
    successFg: Color(0xFF018A33),
    warning: Color(0xFFFF9200),
    warningSubtle: Color(0xFFFFF2E0),
    warningFg: Color(0xFFB86200),
    danger: Color(0xFFFF4242),
    dangerSubtle: Color(0xFFFFEBEB),
    info: Color(0xFF00AEFF),
    infoSubtle: Color(0xFFE3F5FF),
    infoFg: Color(0xFF0079C2),
    violetSubtle: Color(0xFFF0ECFE),
    violetFg: Color(0xFF5B30E8),
    ink: Color(0xFF17181C),
    onInk: Color(0xF5FFFFFF),
    onInkMuted: Color(0x99FFFFFF),
    primary: Color(0xFF0066FF),
    primaryHover: Color(0xFF005AE0),
    primarySubtle: Color(0xFFE3EEFF),
  );

  static const SeedScheme dark = SeedScheme(
    bg: Color(0xFF1C1C1E),
    bgSubtle: Color(0xFF161617),
    bgPress: Color(0xFF2C2C2E),
    page: Color(0xFF0E0E0F),
    fgStrong: Color(0xFFFFFFFF),
    fg: Color(0xFFF2F2F4),
    fgMuted: Color(0xD1FFFFFF),
    fgSubtle: Color(0x8EEBEBF5),
    fgDisabled: Color(0x4DEBEBF5),
    border: Color(0x1FFFFFFF),
    borderSubtle: Color(0x12FFFFFF),
    borderStrong: Color(0x42FFFFFF),
    overlay: Color(0x99000000),
    success: Color(0xFF2BD968),
    successSubtle: Color(0x292BD968),
    successFg: Color(0xFF37E075),
    warning: Color(0xFFFFA726),
    warningSubtle: Color(0x29FFA726),
    warningFg: Color(0xFFFFB851),
    danger: Color(0xFFFF5B5B),
    dangerSubtle: Color(0x29FF5B5B),
    info: Color(0xFF3AC0FF),
    infoSubtle: Color(0x293AC0FF),
    infoFg: Color(0xFF5CCBFF),
    violetSubtle: Color(0x2E7C61FF),
    violetFg: Color(0xFFA892FF),
    ink: Color(0xFF000000),
    onInk: Color(0xF2FFFFFF),
    onInkMuted: Color(0x94FFFFFF),
    primary: Color(0xFF0066FF),
    primaryHover: Color(0xFF005AE0),
    primarySubtle: Color(0xFF152F59),
  );
}

/// 카테고리/출처 hue.
@immutable
class SeedHue {
  const SeedHue(this.color, this.subtle);
  final Color color;
  final Color subtle;

  static const SeedHue blue = SeedHue(Color(0xFF0066FF), Color(0x1A0066FF));
  static const SeedHue violet = SeedHue(Color(0xFF6541F2), Color(0x1A6541F2));
  static const SeedHue orange = SeedHue(Color(0xFFFF9200), Color(0x1FFF9200));
  static const SeedHue green = SeedHue(Color(0xFF00BF40), Color(0x1F00BF40));
  static const SeedHue sky = SeedHue(Color(0xFF00AEFF), Color(0x1F00AEFF));
  static const SeedHue cool = SeedHue(Color(0xFF70737C), Color(0x1F70737C));
  static const SeedHue red = SeedHue(Color(0xFFFF4242), Color(0x1AFF4242));
}

/// 외부 출처 색(캘린더 소스 등).
abstract final class SeedSource {
  static const Color app = Color(0xFF0066FF);
  static const Color google = Color(0xFF34A853);
  static const Color apple = Color(0xFF111111);
  static const Color notion = Color(0xFF7B61FF);
}

abstract final class SeedRadius {
  static const double base = 24;
  static const double lg = 32;
  static const double chip = 8;
  static const double button = 14;
}

abstract final class SeedType {
  static const String sans = 'Pretendard';
  static const String brand = 'Wanted Sans';
  static const double baseSize = 15;
}
