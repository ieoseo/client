import 'package:flutter/foundation.dart';

/// 프로토타입 `TWEAK_DEFAULTS` + `useTweaks`에 대응하는 불변 설정 모델.
///
/// 브랜드 컬러 · 글자 배율 · 카드 둥글기 · 다크 모드를 한 곳에서 관리한다.
/// 값을 바꿀 때는 [copyWith]로 새 인스턴스를 만들어 [DkTokens.build]에 넘긴다.
@immutable
class TweakSettings {
  const TweakSettings({
    this.primary = kDefaultPrimary,
    this.fontScale = 1.0,
    this.radius = 24.0,
    this.dark = false,
  });

  /// 프로토타입 기본 포인트 컬러(`#0066FF`).
  static const int kDefaultPrimary = 0xFF0066FF;

  /// 트윅 패널이 제공하는 포인트 컬러 선택지(daykit-app.jsx TweakColor).
  static const List<int> primaryOptions = <int>[
    0xFF0066FF, // blue
    0xFF6541F2, // violet
    0xFF00BF40, // green
    0xFFFF6F3C, // orange
  ];

  /// 브랜드/포인트 컬러(ARGB int).
  final int primary;

  /// 기본 UI 폰트 크기(15px) 배율. 0.9~1.15.
  final double fontScale;

  /// 카드 기본 라운드(px). 14~32.
  final double radius;

  /// 다크 모드 여부.
  final bool dark;

  TweakSettings copyWith({
    int? primary,
    double? fontScale,
    double? radius,
    bool? dark,
  }) {
    return TweakSettings(
      primary: primary ?? this.primary,
      fontScale: fontScale ?? this.fontScale,
      radius: radius ?? this.radius,
      dark: dark ?? this.dark,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TweakSettings &&
        other.primary == primary &&
        other.fontScale == fontScale &&
        other.radius == radius &&
        other.dark == dark;
  }

  @override
  int get hashCode => Object.hash(primary, fontScale, radius, dark);
}
