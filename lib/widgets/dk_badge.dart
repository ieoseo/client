import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// 뱃지/상태 색조. 프로토타입 `TONE`.
enum DkTone { neutral, primary, success, warning, danger, info, violet }

/// 톤 → (배경, 글자). 프로토타입 `TONE` 매핑.
({Color bg, Color fg}) dkToneColors(DkTokens t, DkTone tone) {
  switch (tone) {
    case DkTone.neutral:
      return (bg: t.bgPress, fg: t.fgMuted);
    case DkTone.primary:
      return (bg: t.primarySubtle, fg: t.primary);
    case DkTone.success:
      return (bg: t.successSubtle, fg: t.successFg);
    case DkTone.warning:
      return (bg: t.warningSubtle, fg: t.warningFg);
    case DkTone.danger:
      return (bg: t.dangerSubtle, fg: t.danger);
    case DkTone.info:
      return (bg: t.infoSubtle, fg: t.infoFg);
    case DkTone.violet:
      return (bg: t.violetSubtle, fg: t.violetFg);
  }
}

/// 디자인 시스템 뱃지. 프로토타입 `Badge`: padding 3×9, radius 8, 12/600.
/// [solid]이면 fg 배경 + 흰 글자.
class DkBadge extends StatelessWidget {
  const DkBadge(
    this.label, {
    super.key,
    this.tone = DkTone.neutral,
    this.leading,
    this.solid = false,
  });

  final String label;
  final DkTone tone;
  final Widget? leading;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final colors = dkToneColors(t, tone);
    final Color bg = solid ? colors.fg : colors.bg;
    final Color fg = solid ? const Color(0xFFFFFFFF) : colors.fg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leading != null) ...<Widget>[leading!, const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.12,
              height: 1.5,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
