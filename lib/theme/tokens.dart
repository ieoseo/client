import 'package:flutter/widgets.dart';
import 'package:ieoseo/theme/seed_tokens.dart';

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

/// 카테고리 / 출처 색(hue). 값은 seed [SeedHue] 단일 소스에서 가져온다.
@immutable
class DkHue {
  const DkHue(this.color, this.subtle);

  /// 본색.
  final Color color;

  /// 옅은 배경(반투명).
  final Color subtle;

  // 값은 seed [SeedHue] 단일 소스에서. (DkHue.blue 등 API 유지)
  static final DkHue blue = DkHue(SeedHue.blue.color, SeedHue.blue.subtle);
  static final DkHue violet = DkHue(
    SeedHue.violet.color,
    SeedHue.violet.subtle,
  );
  static final DkHue orange = DkHue(
    SeedHue.orange.color,
    SeedHue.orange.subtle,
  );
  static final DkHue green = DkHue(SeedHue.green.color, SeedHue.green.subtle);
  static final DkHue sky = DkHue(SeedHue.sky.color, SeedHue.sky.subtle);
  static final DkHue cool = DkHue(SeedHue.cool.color, SeedHue.cool.subtle);
  static final DkHue red = DkHue(SeedHue.red.color, SeedHue.red.subtle);

  /// hue 이름 → [DkHue]. 미지정/미상은 [cool].
  static DkHue byName(String? name) => switch (name) {
    'blue' => blue,
    'violet' => violet,
    'orange' => orange,
    'green' => green,
    'sky' => sky,
    'red' => red,
    _ => cool,
  };
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

/// 이어서 디자인 토큰의 단일 출처. 정적 팔레트(색)는 seed-design 의
/// [SeedScheme](seed_tokens.dart, vendored)에서 가져오고, primary 계열만
/// 트윅 값으로 파생한다. `color-mix`는 [_mix]로 계산.
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
  ///
  /// 정적 색은 seed-design [SeedScheme]에서 가져오고(앱/웹 단일 소스),
  /// primary/primaryHover/primarySubtle 만 트윅 primary 로 파생한다.
  factory DkTokens.build(TweakSettings t) {
    final SeedScheme s = t.dark ? SeedScheme.dark : SeedScheme.light;
    final Color p = Color(t.primary);
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);

    return DkTokens(
      primary: p,
      primaryHover: _mix(p, black, 88),
      // 라이트=흰색 11% 혼합, 다크=다크 배경 26% 혼합(프로토타입과 동일).
      primarySubtle: t.dark ? _mix(p, s.bg, 26) : _mix(p, white, 11),
      radius: t.radius,
      radiusLg: t.radius + 8,
      bg: s.bg,
      bgSubtle: s.bgSubtle,
      bgPress: s.bgPress,
      page: s.page,
      fgStrong: s.fgStrong,
      fg: s.fg,
      fgMuted: s.fgMuted,
      fgSubtle: s.fgSubtle,
      fgDisabled: s.fgDisabled,
      border: s.border,
      borderSubtle: s.borderSubtle,
      borderStrong: s.borderStrong,
      overlay: s.overlay,
      success: s.success,
      successSubtle: s.successSubtle,
      successFg: s.successFg,
      warning: s.warning,
      warningSubtle: s.warningSubtle,
      warningFg: s.warningFg,
      danger: s.danger,
      dangerSubtle: s.dangerSubtle,
      info: s.info,
      infoSubtle: s.infoSubtle,
      infoFg: s.infoFg,
      violetSubtle: s.violetSubtle,
      violetFg: s.violetFg,
      ink: s.ink,
      onInk: s.onInk,
      onInkMuted: s.onInkMuted,
      shadows: t.dark ? DkShadows.dark : DkShadows.light,
      fontScale: t.fontScale,
      isDark: t.dark,
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
