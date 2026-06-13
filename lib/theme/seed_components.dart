// GENERATED — do not edit. Source: tokens/tokens.json components (run `npm run build`).
import 'package:flutter/widgets.dart';

/// 버튼 사이즈 수치(플랫폼 중립). client DkButton 의 `_SizeSpec` 출처.
@immutable
class SeedButtonSize {
  const SeedButtonSize(
    this.height,
    this.padX,
    this.padY,
    this.fontSize,
    this.radius,
    this.gap,
  );
  final double height;
  final double padX;
  final double padY;
  final double fontSize;
  final double radius;
  final double gap;
}

/// 변형별 색 키. scheme 키('primary'·'fg'…) / '#RRGGBB' 리터럴 / 'transparent'.
@immutable
class SeedButtonVariant {
  const SeedButtonVariant(this.bg, this.fg, this.border);
  final String bg;
  final String fg;
  final String border;
}

/// 버튼 컴포넌트 스펙(단일 소스). 앱·웹이 같은 수치/변형을 공유한다.
abstract final class SeedButton {
  static const int weight = 600;
  static const double letterSpacingEm = 0.0096;
  static const double pressTranslateY = 1;
  static const double borderWidth = 1.5;

  static const Map<String, SeedButtonSize> sizes = {
    'sm': SeedButtonSize(40, 14, 8, 13, 10, 6),
    'md': SeedButtonSize(50, 18, 13, 15, 14, 7),
    'lg': SeedButtonSize(56, 22, 16, 16, 16, 8),
  };

  static const Map<String, SeedButtonVariant> variants = {
    'primary': SeedButtonVariant('primary', '#FFFFFF', 'transparent'),
    'neutral': SeedButtonVariant('fg', 'bg', 'transparent'),
    'outline': SeedButtonVariant('transparent', 'fg', 'border'),
    'subtle': SeedButtonVariant('primarySubtle', 'primary', 'transparent'),
    'ghost': SeedButtonVariant('transparent', 'fgMuted', 'transparent'),
    'danger': SeedButtonVariant('dangerSubtle', 'danger', 'transparent'),
  };
}
