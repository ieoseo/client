import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'dk_icon.dart';

/// 우상단 알림 벨 버튼(모든 탭 공통). 프로토타입 `AppHeader` 의 벨을 단일 위젯으로 통일.
///
/// 44×44 radius 14 bg-press, 벨 21 fg-muted. [unread]>0면 우상단 빨간 점(8, 2px 테두리).
/// 홈·플랜·통계·프로필이 모두 같은 위치/스타일을 쓰도록 여기로 일원화한다(중복 제거).
class DkBellButton extends StatelessWidget {
  const DkBellButton({super.key, this.unread = 0, this.onTap});

  /// 안 읽은 알림 수. 0 보다 크면 빨간 점을 표시한다.
  final int unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}
