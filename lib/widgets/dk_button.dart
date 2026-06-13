import 'package:flutter/widgets.dart';

import '../theme/seed_components.dart';
import '../theme/tokens.dart';

/// 버튼 크기. 프로토타입 `Btn` size 스케일.
enum DkButtonSize { sm, md, lg }

/// 버튼 변형. 프로토타입 `Btn` variant.
enum DkButtonVariant { primary, neutral, outline, subtle, ghost, danger }

/// 디자인 시스템 버튼. 프로토타입 `Btn`을 이식.
///
/// weight 600, letter-spacing .0096em, press 시 1px 내려감. [child]가 없으면
/// 아이콘 전용(정사각형).
class DkButton extends StatefulWidget {
  const DkButton({
    super.key,
    this.child,
    this.onPressed,
    this.size = DkButtonSize.md,
    this.variant = DkButtonVariant.primary,
    this.leading,
    this.trailing,
    this.full = false,
    this.disabled = false,
  });

  final Widget? child;
  final VoidCallback? onPressed;
  final DkButtonSize size;
  final DkButtonVariant variant;
  final Widget? leading;
  final Widget? trailing;
  final bool full;
  final bool disabled;

  @override
  State<DkButton> createState() => _DkButtonState();
}

class _DkButtonState extends State<DkButton> {
  bool _pressed = false;

  /// seed [SeedButton.variants] 의 색 키(scheme 키 / '#hex' / 'transparent')를
  /// 현재 테마 [DkTokens] 색으로 해석한다. 변형 정의의 단일 소스는 seed.
  Color _token(String key, DkTokens t) {
    switch (key) {
      case 'transparent':
        return const Color(0x00000000);
      case 'primary':
        return t.primary;
      case 'primarySubtle':
        return t.primarySubtle;
      case 'fg':
        return t.fg;
      case 'bg':
        return t.bg;
      case 'fgMuted':
        return t.fgMuted;
      case 'border':
        return t.border;
      case 'danger':
        return t.danger;
      case 'dangerSubtle':
        return t.dangerSubtle;
      default:
        if (key.startsWith('#')) {
          final String s = key.substring(1);
          final String argb = s.length == 6 ? 'FF$s' : s;
          return Color(int.parse(argb, radix: 16));
        }
        return t.fg;
    }
  }

  ({Color bg, Color fg, Color border}) _colors(DkTokens t) {
    final SeedButtonVariant v = SeedButton.variants[widget.variant.name]!;
    return (
      bg: _token(v.bg, t),
      fg: _token(v.fg, t),
      border: _token(v.border, t),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final SeedButtonSize s = SeedButton.sizes[widget.size.name]!;
    final bool iconOnly = widget.child == null;
    final c = _colors(t);

    final Color bg = widget.disabled ? t.bgPress : c.bg;
    final Color fg = widget.disabled ? t.fgDisabled : c.fg;
    final Color border = widget.disabled ? const Color(0x00000000) : c.border;

    final List<Widget> row = <Widget>[
      if (widget.leading != null) widget.leading!,
      if (widget.child != null)
        DefaultTextStyle.merge(
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.values[(SeedButton.weight ~/ 100) - 1],
            fontSize: s.fontSize,
            letterSpacing: s.fontSize * SeedButton.letterSpacingEm,
            color: fg,
            height: 1.0,
          ),
          child: widget.child!,
        ),
      if (widget.trailing != null) widget.trailing!,
    ];

    final Widget content = Container(
      height: s.height,
      width: widget.full
          ? double.infinity
          : iconOnly
          ? s.height
          : null,
      padding: iconOnly
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: s.padX, vertical: s.padY),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(s.radius),
        border: Border.all(color: border, width: SeedButton.borderWidth),
      ),
      child: Row(
        mainAxisSize: widget.full ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < row.length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: s.gap),
            row[i],
          ],
        ],
      ),
    );

    return GestureDetector(
      onTapDown: widget.disabled
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.disabled
          ? null
          : () => setState(() => _pressed = false),
      onTap: widget.disabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          _pressed ? SeedButton.pressTranslateY : 0,
          0,
        ),
        child: content,
      ),
    );
  }
}
