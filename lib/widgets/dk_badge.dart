import 'package:flutter/widgets.dart';

import '../theme/seed_components.dart';
import '../theme/tokens.dart';

/// 뱃지/상태 색조. 프로토타입 `TONE`. seed [SeedBadge.tones] 와 키 1:1.
enum DkTone { neutral, primary, success, warning, danger, info, violet }

/// 톤 → (배경, 글자). 톤 매핑은 seed [SeedBadge.tones], 색 해석은 [DkTokens.byKey].
({Color bg, Color fg}) dkToneColors(DkTokens t, DkTone tone) {
  final SeedTone st = SeedBadge.tones[tone.name]!;
  return (bg: t.byKey(st.bg), fg: t.byKey(st.fg));
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
      padding: const EdgeInsets.symmetric(
        horizontal: SeedBadge.padX,
        vertical: SeedBadge.padY,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SeedBadge.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: SeedBadge.gap),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: SeedBadge.fontSize,
              fontWeight: FontWeight.values[(SeedBadge.weight ~/ 100) - 1],
              letterSpacing: SeedBadge.letterSpacing,
              height: SeedBadge.lineHeight,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
