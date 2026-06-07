import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'dk_icon.dart';

/// 섹션 헤더. 프로토타입 `SectionHead`: 제목 17/700 + 우측 action(13/600 + chevR).
class DkSectionHead extends StatelessWidget {
  const DkSectionHead({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.34,
                color: t.fg,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    action!,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.fgSubtle,
                    ),
                  ),
                  const SizedBox(width: 2),
                  DkIcon(
                    'chevR',
                    size: 15,
                    color: t.fgSubtle,
                    strokeWidth: 2.2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 섹션 라벨(오늘 탭). 프로토타입 `SectionLabel`: 대문자 12/700, tracking .08em.
class DkSectionLabel extends StatelessWidget {
  const DkSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.96,
        color: t.fgSubtle,
      ),
    );
  }
}
