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

/// 뱃지 톤 = 의미색 쌍(배경/글자 scheme 키).
@immutable
class SeedTone {
  const SeedTone(this.bg, this.fg);
  final String bg;
  final String fg;
}

/// 뱃지 컴포넌트 스펙(단일 소스). client DkBadge 가 소비.
abstract final class SeedBadge {
  static const double padX = 9;
  static const double padY = 3;
  static const double radius = 8;
  static const double fontSize = 12;
  static const int weight = 600;
  static const double letterSpacing = 0.12;
  static const double lineHeight = 1.5;
  static const double gap = 4;

  static const Map<String, SeedTone> tones = {
    'neutral': SeedTone('bgPress', 'fgMuted'),
    'primary': SeedTone('primarySubtle', 'primary'),
    'success': SeedTone('successSubtle', 'successFg'),
    'warning': SeedTone('warningSubtle', 'warningFg'),
    'danger': SeedTone('dangerSubtle', 'danger'),
    'info': SeedTone('infoSubtle', 'infoFg'),
    'violet': SeedTone('violetSubtle', 'violetFg'),
  };
}

/// 카드 컴포넌트 스펙(단일 소스). radius·shadow·border 는 토큰. client DkCard 가 소비.
abstract final class SeedCard {
  static const double padding = 18;
  static const double pressScale = 0.985;
  static const int pressDurationMs = 120;
}

/// 세그먼트 컨트롤 스펙(단일 소스). client DkSegmented 가 소비.
abstract final class SeedSegmented {
  static const double pad = 3;
  static const double radius = 12;
  static const double thumbRadius = 9;
  static const double tabPadX = 14;
  static const double tabPadY = 8;
  static const double fontSize = 14;
  static const int weight = 600;
  static const int thumbDurationMs = 260;
  static const int textDurationMs = 200;
}

/// 선택 칩 스펙(단일 소스). on/off 색은 [SeedButtonVariant] 재사용. client DkChoiceChip 소비.
abstract final class SeedChip {
  static const double padX = 14;
  static const double padY = 9;
  static const double radius = 10;
  static const double fontSize = 14;
  static const int weight = 600;
  static const double borderWidth = 1.5;
  static const double gap = 6;
  static const SeedButtonVariant on = SeedButtonVariant(
    'primarySubtle',
    'primary',
    'primary',
  );
  static const SeedButtonVariant off = SeedButtonVariant(
    'bg',
    'fgMuted',
    'border',
  );
}
