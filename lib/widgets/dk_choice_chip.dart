import 'package:flutter/widgets.dart';

import '../theme/seed_components.dart';
import '../theme/tokens.dart';

/// 선택 칩(on/off). seed [SeedChip] 스펙 단일 소스.
///
/// on = primary-subtle 배경 + primary 글자/테두리, off = bg + border.
/// task_sheet 의 분(分)·요일 선택 칩을 통합한다.
/// [expand]이면 부모 폭을 채우고 중앙 정렬(요일 사각 칩처럼 AspectRatio 안에서 사용).
class DkChoiceChip extends StatelessWidget {
  const DkChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.fontSize,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// 글자 크기 override(기본 [SeedChip.fontSize]).
  final double? fontSize;

  /// true면 padding 없이 부모를 채우고 중앙 정렬.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final SeedButtonVariant v = selected ? SeedChip.on : SeedChip.off;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: expand ? Alignment.center : null,
        padding: expand
            ? null
            : const EdgeInsets.symmetric(
                horizontal: SeedChip.padX,
                vertical: SeedChip.padY,
              ),
        decoration: BoxDecoration(
          color: t.byKey(v.bg),
          borderRadius: BorderRadius.circular(SeedChip.radius),
          border: Border.all(
            color: t.byKey(v.border),
            width: SeedChip.borderWidth,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: fontSize ?? SeedChip.fontSize,
            fontWeight: FontWeight.values[(SeedChip.weight ~/ 100) - 1],
            color: t.byKey(v.fg),
          ),
        ),
      ),
    );
  }
}
