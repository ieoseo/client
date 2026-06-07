import 'package:flutter/widgets.dart';

import 'tweaks.dart';

/// sRGB 선형 보간으로 CSS `color-mix(in srgb, a p%, b)`를 재현한다.
///
/// 프로토타입의 `color-mix(in srgb, P 88%, #000)` 같은 식을 Flutter에서 그대로
/// 계산하기 위한 헬퍼. [pct]는 첫 색([a])의 비율(0~100).
Color _mix(Color a, Color b, double pct) {
  // Color.lerp(a, b, t)는 t=0에서 a, t=1에서 b. color-mix의 p%는 a의 비율이므로
  // t = 1 - p/100.
  return Color.lerp(a, b, 1 - pct / 100)!;
}

/// 카테고리 / 출처 색(hue). 프로토타입 `DK_HUE`를 그대로 이식.
@immutable
class DkHue {
  const DkHue(this.color, this.subtle);

  /// 본색.
  final Color color;

  /// 옅은 배경(반투명).
  final Color subtle;

  static const DkHue blue = DkHue(Color(0xFF0066FF), Color(0x1A0066FF));
  static const DkHue violet = DkHue(Color(0xFF6541F2), Color(0x1A6541F2));
  static const DkHue orange = DkHue(Color(0xFFFF9200), Color(0x1FFF9200));
  static const DkHue green = DkHue(Color(0xFF00BF40), Color(0x1F00BF40));
  static const DkHue sky = DkHue(Color(0xFF00AEFF), Color(0x1F00AEFF));
  static const DkHue cool = DkHue(Color(0xFF70737C), Color(0x1F70737C));
  static const DkHue red = DkHue(Color(0xFFFF4242), Color(0x1AFF4242));

  /// hue 이름 → [DkHue]. 미지정/미상은 [cool].
  static DkHue byName(String? name) {
    switch (name) {
      case 'blue':
        return blue;
      case 'violet':
        return violet;
      case 'orange':
        return orange;
      case 'green':
        return green;
      case 'sky':
        return sky;
      case 'red':
        return red;
      case 'cool':
      default:
        return cool;
    }
  }
}

/// 카테고리명 → hue 이름(프로토타입 `CATEGORY_META`).
const Map<String, String> kCategoryHue = <String, String>{
  '자격증': 'violet',
  '어학': 'blue',
  '취업': 'orange',
  '건강': 'green',
  '공부': 'sky',
  '기타': 'cool',
};

/// 합성 그림자(soft). 프로토타입 `--dk-shadow-1/2/3`.
@immutable
class DkShadows {
  const DkShadows(this.s1, this.s2, this.s3);

  final List<BoxShadow> s1;
  final List<BoxShadow> s2;
  final List<BoxShadow> s3;

  static const DkShadows light = DkShadows(
    <BoxShadow>[
      BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x0F171717), offset: Offset(0, 2), blurRadius: 8),
    ],
    <BoxShadow>[
      BoxShadow(color: Color(0x17171717), offset: Offset(0, 4), blurRadius: 14),
      BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 2),
    ],
    <BoxShadow>[
      BoxShadow(
        color: Color(0x24171717),
        offset: Offset(0, 14),
        blurRadius: 34,
      ),
      BoxShadow(color: Color(0x0D000000), offset: Offset(0, 2), blurRadius: 6),
    ],
  );

  static const DkShadows dark = DkShadows(
    <BoxShadow>[
      BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
    ],
    <BoxShadow>[
      BoxShadow(color: Color(0x73000000), offset: Offset(0, 6), blurRadius: 18),
    ],
    <BoxShadow>[
      BoxShadow(
        color: Color(0x8C000000),
        offset: Offset(0, 16),
        blurRadius: 40,
      ),
    ],
  );
}

/// 이어서 디자인 토큰의 단일 출처. 프로토타입 `buildTheme()`의 라이트/다크 값을
/// 그대로 이식한다. `color-mix`는 [_mix]로 계산.
///
/// 트윅(`TweakSettings`)이 바뀌면 [build]로 새 인스턴스를 만들고
/// [DkTheme]가 트리에 내려보낸다.
@immutable
class DkTokens {
  const DkTokens({
    required this.primary,
    required this.primaryHover,
    required this.primarySubtle,
    required this.radius,
    required this.radiusLg,
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
    required this.shadows,
    required this.fontScale,
    required this.isDark,
  });

  // ── 브랜드 ──────────────────────────────────────────────
  final Color primary;
  final Color primaryHover;
  final Color primarySubtle;

  // ── 형태 ────────────────────────────────────────────────
  final double radius;
  final double radiusLg;

  // ── 표면 ────────────────────────────────────────────────
  final Color bg;
  final Color bgSubtle;
  final Color bgPress;
  final Color page;

  // ── 텍스트 ──────────────────────────────────────────────
  final Color fgStrong;
  final Color fg;
  final Color fgMuted;
  final Color fgSubtle;
  final Color fgDisabled;

  // ── 경계 ────────────────────────────────────────────────
  final Color border;
  final Color borderSubtle;
  final Color borderStrong;
  final Color overlay;

  // ── 상태색 ──────────────────────────────────────────────
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

  // ── 잉크(프리미엄 다크 표면) ─────────────────────────────
  final Color ink;
  final Color onInk;
  final Color onInkMuted;

  // ── 기타 ────────────────────────────────────────────────
  final DkShadows shadows;
  final double fontScale;
  final bool isDark;

  /// 트윅 설정으로부터 토큰 세트를 만든다. 프로토타입 `buildTheme(t)` 대응.
  factory DkTokens.build(TweakSettings t) {
    final Color p = Color(t.primary);
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);

    if (t.dark) {
      const Color darkBg = Color(0xFF1C1C1E);
      return DkTokens(
        primary: p,
        primaryHover: _mix(p, black, 88),
        primarySubtle: _mix(p, darkBg, 26),
        radius: t.radius,
        radiusLg: t.radius + 8,
        bg: darkBg,
        bgSubtle: const Color(0xFF161617),
        bgPress: const Color(0xFF2C2C2E),
        page: const Color(0xFF0E0E0F),
        fgStrong: white,
        fg: const Color(0xFFF2F2F4),
        fgMuted: const Color(0xD1FFFFFF), // rgba(255,255,255,0.82)
        fgSubtle: const Color(0x8EEBEBF5), // rgba(235,235,245,0.56)
        fgDisabled: const Color(0x4DEBEBF5), // rgba(235,235,245,0.30)
        border: const Color(0x1FFFFFFF), // .12
        borderSubtle: const Color(0x12FFFFFF), // .07
        borderStrong: const Color(0x42FFFFFF), // .26
        overlay: const Color(0x99000000), // .6
        success: const Color(0xFF2BD968),
        successSubtle: const Color(0x292BD968), // .16
        successFg: const Color(0xFF37E075),
        warning: const Color(0xFFFFA726),
        warningSubtle: const Color(0x29FFA726),
        warningFg: const Color(0xFFFFB851),
        danger: const Color(0xFFFF5B5B),
        dangerSubtle: const Color(0x29FF5B5B),
        info: const Color(0xFF3AC0FF),
        infoSubtle: const Color(0x293AC0FF),
        infoFg: const Color(0xFF5CCBFF),
        violetSubtle: const Color(0x2E7C61FF), // rgba(124,97,255,0.18)
        violetFg: const Color(0xFFA892FF),
        ink: black,
        onInk: const Color(0xF2FFFFFF), // .95
        onInkMuted: const Color(0x94FFFFFF), // .58
        shadows: DkShadows.dark,
        fontScale: t.fontScale,
        isDark: true,
      );
    }

    return DkTokens(
      primary: p,
      primaryHover: _mix(p, black, 88),
      primarySubtle: _mix(p, white, 11),
      radius: t.radius,
      radiusLg: t.radius + 8,
      bg: white,
      bgSubtle: const Color(0xFFF7F7F8),
      bgPress: const Color(0xFFF1F2F4),
      page: const Color(0xFFF7F7F8),
      fgStrong: const Color(0xFF0A0A0B),
      fg: const Color(0xFF1A1B1E),
      fgMuted: const Color(0xDC2E2F33), // rgba(46,47,51,0.86)
      fgSubtle: const Color(0x9437383C), // rgba(55,56,60,0.58)
      fgDisabled: const Color(0x4D37383C), // rgba(55,56,60,0.30)
      border: const Color(0x3870737C), // rgba(112,115,124,0.22)
      borderSubtle: const Color(0x1F70737C), // .12
      borderStrong: const Color(0x6670737C), // .40
      overlay: const Color(0x6B171719), // rgba(23,23,25,0.42)
      success: const Color(0xFF00BF40),
      successSubtle: const Color(0xFFE3FBEC),
      successFg: const Color(0xFF018A33),
      warning: const Color(0xFFFF9200),
      warningSubtle: const Color(0xFFFFF2E0),
      warningFg: const Color(0xFFB86200),
      danger: const Color(0xFFFF4242),
      dangerSubtle: const Color(0xFFFFEBEB),
      info: const Color(0xFF00AEFF),
      infoSubtle: const Color(0xFFE3F5FF),
      infoFg: const Color(0xFF0079C2),
      violetSubtle: const Color(0xFFF0ECFE),
      violetFg: const Color(0xFF5B30E8),
      ink: const Color(0xFF17181C),
      onInk: const Color(0xF5FFFFFF), // .96
      onInkMuted: const Color(0x99FFFFFF), // .60
      shadows: DkShadows.light,
      fontScale: t.fontScale,
      isDark: false,
    );
  }

  /// 기본 UI 폰트 크기(15px)에 트윅 배율을 곱한 값.
  double get baseFontSize => 15 * fontScale;
}

/// 토큰을 위젯 트리에 내려보내는 InheritedWidget. `DkTheme.of(context)`로 접근.
class DkTheme extends InheritedWidget {
  const DkTheme({super.key, required this.tokens, required super.child});

  final DkTokens tokens;

  static DkTokens of(BuildContext context) {
    final DkTheme? theme = context
        .dependOnInheritedWidgetOfExactType<DkTheme>();
    assert(theme != null, 'DkTheme.of()는 DkTheme 하위에서만 호출할 수 있어요.');
    return theme!.tokens;
  }

  @override
  bool updateShouldNotify(DkTheme oldWidget) => oldWidget.tokens != tokens;
}
