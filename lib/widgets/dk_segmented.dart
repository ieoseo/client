import 'package:flutter/widgets.dart';

import '../theme/seed_components.dart';
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
            ? (constraints.maxWidth - SeedSegmented.pad * 2) / options.length
            : 0;
        return Stack(
          children: <Widget>[
            if (full)
              AnimatedPositioned(
                duration: const Duration(
                  milliseconds: SeedSegmented.thumbDurationMs,
                ),
                curve: const Cubic(0.4, 0, 0.2, 1),
                top: 0,
                bottom: 0,
                left: idx * thumbWidth,
                width: thumbWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.bg,
                    borderRadius: BorderRadius.circular(
                      SeedSegmented.thumbRadius,
                    ),
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
      padding: const EdgeInsets.all(SeedSegmented.pad),
      decoration: BoxDecoration(
        color: t.bgPress,
        borderRadius: BorderRadius.circular(SeedSegmented.radius),
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
        padding: const EdgeInsets.symmetric(
          horizontal: SeedSegmented.tabPadX,
          vertical: SeedSegmented.tabPadY,
        ),
        decoration: !full && active
            ? BoxDecoration(
                color: t.bg,
                borderRadius: BorderRadius.circular(SeedSegmented.thumbRadius),
                boxShadow: t.shadows.s1,
              )
            : null,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: SeedSegmented.textDurationMs),
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.values[(SeedSegmented.weight ~/ 100) - 1],
            fontSize: SeedSegmented.fontSize,
            color: active ? t.fg : t.fgSubtle,
          ),
          child: Text(o.label),
        ),
      ),
    );
    return full ? Expanded(child: tab) : tab;
  }
}
