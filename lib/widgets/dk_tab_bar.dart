import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'dk_icon.dart';

/// 하단 탭. 프로토타입 `TABS`.
enum DkTab { today, plan, focus, me }

class _TabSpec {
  const _TabSpec(this.tab, this.label, this.icon);
  final DkTab tab;
  final String label;
  final String icon;
}

const List<_TabSpec> _tabs = <_TabSpec>[
  _TabSpec(DkTab.today, '오늘', 'home'),
  _TabSpec(DkTab.plan, '플랜', 'calendar'),
  _TabSpec(DkTab.focus, '집중', 'focus'),
  _TabSpec(DkTab.me, '프로필', 'user'),
];

/// 하단 탭바. 프로토타입 `TabBar`.
///
/// 배경 bg, 상단 border, paddingTop 8 / paddingBottom 22. 4개 균등. active는
/// primary + primary-subtle fill 아이콘, 라벨 700/primary. active 아이콘은
/// 살짝 위로 + 확대(스프링).
class DkTabBar extends StatelessWidget {
  const DkTabBar({super.key, required this.active, required this.onChanged});

  final DkTab active;
  final ValueChanged<DkTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    // edge-to-edge(Android 15+ 강제)에서 시스템 내비게이션 바와 겹치지 않도록
    // 하단 패딩에 시스템 inset 을 반영한다. 시스템 바가 없으면 디자인값 22 유지.
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(top: BorderSide(color: t.border)),
      ),
      padding: EdgeInsets.only(top: 8, bottom: math.max(22, safeBottom + 8)),
      child: Row(
        children: <Widget>[
          for (final _TabSpec spec in _tabs)
            Expanded(child: _buildTab(context, t, spec)),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, DkTokens t, _TabSpec spec) {
    final bool on = spec.tab == active;
    final Color color = on ? t.primary : t.fgDisabled;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(spec.tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedScale(
              scale: on ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: const Cubic(0.34, 1.3, 0.64, 1),
              child: Transform.translate(
                offset: Offset(0, on ? -1 : 0),
                child: DkIcon(
                  spec.icon,
                  size: 24,
                  color: color,
                  strokeWidth: on ? 2.3 : 1.9,
                  fill: on ? t.primarySubtle : null,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              spec.label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
