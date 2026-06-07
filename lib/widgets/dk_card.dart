import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// 기본 카드. 프로토타입 `Card`.
///
/// 배경 bg, radius `--dk-radius`, padding 18(기본), shadow-1, 1px border-subtle.
/// [onTap]이 있으면 press 시 살짝 축소(scale .985).
class DkCard extends StatefulWidget {
  const DkCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = 18,
    this.radius,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double padding;

  /// 직접 지정 시 토큰 radius를 무시.
  final double? radius;

  /// 직접 지정 시 토큰 bg를 무시(예: ink 표면).
  final Color? color;

  @override
  State<DkCard> createState() => _DkCardState();
}

class _DkCardState extends State<DkCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final bool tappable = widget.onTap != null;

    final Widget card = AnimatedScale(
      scale: _pressed && tappable ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: const Cubic(0.4, 0, 0.2, 1),
      child: Container(
        padding: EdgeInsets.all(widget.padding),
        decoration: BoxDecoration(
          color: widget.color ?? t.bg,
          borderRadius: BorderRadius.circular(widget.radius ?? t.radius),
          boxShadow: t.shadows.s1,
          border: Border.all(color: t.borderSubtle),
        ),
        child: widget.child,
      ),
    );

    if (!tappable) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}
