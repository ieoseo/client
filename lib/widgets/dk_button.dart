import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// 버튼 크기. 프로토타입 `Btn` size 스케일.
enum DkButtonSize { sm, md, lg }

/// 버튼 변형. 프로토타입 `Btn` variant.
enum DkButtonVariant { primary, neutral, outline, subtle, ghost, danger }

class _SizeSpec {
  const _SizeSpec(
    this.height,
    this.padH,
    this.padV,
    this.fontSize,
    this.radius,
    this.gap,
  );
  final double height;
  final double padH;
  final double padV;
  final double fontSize;
  final double radius;
  final double gap;
}

const Map<DkButtonSize, _SizeSpec> _sizes = <DkButtonSize, _SizeSpec>{
  DkButtonSize.sm: _SizeSpec(40, 14, 8, 13, 10, 6),
  DkButtonSize.md: _SizeSpec(50, 18, 13, 15, 14, 7),
  DkButtonSize.lg: _SizeSpec(56, 22, 16, 16, 16, 8),
};

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

  ({Color bg, Color fg, Color border}) _colors(DkTokens t) {
    switch (widget.variant) {
      case DkButtonVariant.primary:
        return (
          bg: t.primary,
          fg: const Color(0xFFFFFFFF),
          border: const Color(0x00000000),
        );
      case DkButtonVariant.neutral:
        return (bg: t.fg, fg: t.bg, border: const Color(0x00000000));
      case DkButtonVariant.outline:
        return (bg: const Color(0x00000000), fg: t.fg, border: t.border);
      case DkButtonVariant.subtle:
        return (
          bg: t.primarySubtle,
          fg: t.primary,
          border: const Color(0x00000000),
        );
      case DkButtonVariant.ghost:
        return (
          bg: const Color(0x00000000),
          fg: t.fgMuted,
          border: const Color(0x00000000),
        );
      case DkButtonVariant.danger:
        return (
          bg: t.dangerSubtle,
          fg: t.danger,
          border: const Color(0x00000000),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final _SizeSpec s = _sizes[widget.size]!;
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
            fontWeight: FontWeight.w600,
            fontSize: s.fontSize,
            letterSpacing: s.fontSize * 0.0096,
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
          : EdgeInsets.symmetric(horizontal: s.padH, vertical: s.padV),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(s.radius),
        border: Border.all(color: border, width: 1.5),
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
        transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
        child: content,
      ),
    );
  }
}
