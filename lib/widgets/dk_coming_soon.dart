import 'package:flutter/widgets.dart';

import '../data/meta.dart';
import 'dk_badge.dart';

/// 준비 중(미구현) 컨트롤의 자식에 적용하는 불투명도. 활성 컨트롤(1.0)과 분명히
/// 구분되도록 낮추되, 내용이 식별 가능한 수준으로 남긴다.
const double kComingSoonOpacity = 0.45;

/// 준비 중 기능 진입점을 감싸는 재사용 트리트먼트.
///
/// 자식을 회색/뮤트(낮은 [kComingSoonOpacity])로 보여 활성 항목과 위계를 분명히
/// 하되, 여전히 탭 가능하다([onTap]). 우상단에 작은 '준비 중' 뱃지([kComingSoonBadgeLabel])를
/// 얹어 탭 전에 미구현임을 알린다([badge]로 끌 수 있음).
///
/// 탭 안내 문구는 호출부([onTap])에서 공통 [kComingSoonMessage] 토스트로 처리한다.
class DkComingSoon extends StatelessWidget {
  const DkComingSoon({
    super.key,
    required this.child,
    this.onTap,
    this.badge = true,
  });

  /// 뮤트 처리할 원본 컨트롤.
  final Widget child;

  /// 탭 콜백. 보통 공통 준비 중 토스트를 띄운다.
  final VoidCallback? onTap;

  /// 우상단 '준비 중' 뱃지 노출 여부. 라벨/뱃지를 이미 가진 행에서는 끈다.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final Widget muted = Opacity(opacity: kComingSoonOpacity, child: child);

    final Widget content = badge
        ? Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              muted,
              const Positioned(
                top: -6,
                right: -6,
                child: DkBadge(kComingSoonBadgeLabel),
              ),
            ],
          )
        : muted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
