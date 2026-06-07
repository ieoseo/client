import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// 세그먼트 항목.
class DkSegment<T> {
  const DkSegment(this.value, this.label);
  final T value;
  final String label;
}

/// 세그먼트 컨트롤. 프로토타입 `Segmented`.
///
/// 배경 bg-press, radius 12, padding 3. [full]이면 흰 슬라이딩 thumb이
/// 260ms 표준 이징으로 이동한다. 항목 14/600.
class DkSegmented<T> extends StatelessWidget {
  const DkSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.full = false,
  });

  final List<DkSegment<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    int idx = options.indexWhere((DkSegment<T> o) => o.value == value);
    if (idx < 0) idx = 0;

    final Widget tabs = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double thumbWidth = full && constraints.hasBoundedWidth
            ? (constraints.maxWidth - 6) / options.length
            : 0;
        return Stack(
          children: <Widget>[
            if (full)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: const Cubic(0.4, 0, 0.2, 1),
                top: 0,
                bottom: 0,
                left: idx * thumbWidth,
                width: thumbWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.bg,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: t.shadows.s1,
                  ),
                ),
              ),
            Row(
              mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
              children: <Widget>[
                for (final DkSegment<T> o in options)
                  _buildTab(context, t, o, full),
              ],
            ),
          ],
        );
      },
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.bgPress,
        borderRadius: BorderRadius.circular(12),
      ),
      child: tabs,
    );
  }

  Widget _buildTab(
    BuildContext context,
    DkTokens t,
    DkSegment<T> o,
    bool full,
  ) {
    final bool active = o.value == value;
    final Widget tab = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(o.value),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: !full && active
            ? BoxDecoration(
                color: t.bg,
                borderRadius: BorderRadius.circular(9),
                boxShadow: t.shadows.s1,
              )
            : null,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: active ? t.fg : t.fgSubtle,
          ),
          child: Text(o.label),
        ),
      ),
    );
    return full ? Expanded(child: tab) : tab;
  }
}
