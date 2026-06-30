import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../widgets/dk_bell_button.dart';
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
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final int unread;
  final VoidCallback? onBell;
  final Widget? right;

  /// 지정하면 제목 앞에 뒤로가기 chevron 을 둔다(서브화면용). null 이면 표시 안 함.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 58, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.bgPress,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DkIcon('chevL', size: 22, color: t.fg),
              ),
            ),
            const SizedBox(width: 10),
          ],
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
                DkBellButton(unread: unread, onTap: onBell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
