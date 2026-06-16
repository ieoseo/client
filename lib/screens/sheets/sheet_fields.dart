import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/dk_icon.dart';

/// 폼 필드(라벨 + 콘텐츠 + 힌트). 프로토타입 `Field`.
class DkField extends StatelessWidget {
  const DkField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.fgMuted,
            ),
          ),
          const SizedBox(height: 7),
          child,
          if (hint != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                color: t.fgSubtle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 텍스트 입력. 프로토타입 `TextInput`: border 1.5 radius 12, focus 시 primary 링.
class DkTextInput extends StatefulWidget {
  const DkTextInput({
    super.key,
    this.controller,
    this.placeholder,
    this.minHeight,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final double? minHeight;

  @override
  State<DkTextInput> createState() => _DkTextInputState();
}

class _DkTextInputState extends State<DkTextInput> {
  final FocusNode _node = FocusNode();
  late final TextEditingController _fallback = TextEditingController();

  @override
  void initState() {
    super.initState();
    _node.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _node.dispose();
    _fallback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final bool focused = _node.hasFocus;
    final TextEditingController controller = widget.controller ?? _fallback;
    return Container(
      constraints: BoxConstraints(minHeight: widget.minHeight ?? 0),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: focused ? t.primary : t.border, width: 1.5),
        boxShadow: focused
            ? <BoxShadow>[
                BoxShadow(
                  color: t.primarySubtle,
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      // raw EditableText 대신 TextField 사용: 탭→키보드 재표시, 커서 이동,
      // 선택·붙여넣기를 표준 처리한다. InputDecoration.collapsed 로 Material
      // 장식을 없애 기존 커스텀 박스(테두리·포커스 링) 외형을 그대로 유지한다.
      child: TextField(
        controller: controller,
        focusNode: _node,
        maxLines: widget.minHeight != null ? null : 1,
        cursorColor: t.primary,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: t.fg,
        ),
        decoration: InputDecoration.collapsed(
          hintText: widget.placeholder ?? '',
          hintStyle: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: t.fgSubtle,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

/// 카테고리 선택 pills. 프로토타입 `CategoryPills`.
class DkCategoryPills extends StatelessWidget {
  const DkCategoryPills({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: <Widget>[
        for (final MapEntry<String, String> e in kCategoryHue.entries)
          _pill(t, e.key, DkHue.byName(e.value)),
      ],
    );
  }

  Widget _pill(DkTokens t, String cat, DkHue h) {
    final bool on = cat == value;
    return GestureDetector(
      onTap: () => onChanged(cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: on ? h.subtle : t.bg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: on ? h.color : t.border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DkIcon(
              kCategoryIcon[cat] ?? 'more',
              size: 15,
              color: on ? h.color : t.fgMuted,
              strokeWidth: 2,
            ),
            const SizedBox(width: 5),
            Text(
              cat,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: on ? h.color : t.fgMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
