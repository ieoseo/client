import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../widgets/dk_icon.dart';

/// 화면 상단 헤더(인사 + 알림 벨). 프로토타입 `AppHeader`.
///
/// padding 58×20×12. 좌측 subtitle(13/600 fg-subtle) + title(26/800).
/// 우측 [right] + 벨 버튼 44 radius 14(bg-press). [unread]>0면 빨간 점.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.unread = 0,
    this.onBell,
    this.right,
  });

  final String title;
  final String? subtitle;
  final int unread;
  final VoidCallback? onBell;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 58, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (subtitle != null) ...<Widget>[
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.fgSubtle,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.78,
                    color: t.fgStrong,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (right != null) ...<Widget>[
                  right!,
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: onBell,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.bgPress,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        DkIcon('bell', size: 21, color: t.fgMuted),
                        if (unread > 0)
                          Positioned(
                            top: -2,
                            right: -1,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: t.danger,
                                shape: BoxShape.circle,
                                border: Border.all(color: t.bgPress, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
