import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../widgets/dk_skeleton.dart';

/// 초기 데이터 로딩 화면(토스·당근 스타일 스켈레톤). 밋밋한 "불러오는 중…" 텍스트 대신
/// 최종 레이아웃(인사·제목 → 요약 카드 → 할 일 리스트)의 윤곽을 회색 플레이스홀더 + shimmer 로 보여준다.
class AppLoadingSkeleton extends StatelessWidget {
  const AppLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Container(
      color: t.page,
      child: SafeArea(
        child: DkSkeletonScope(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const DkSkeleton(width: 120, height: 14),
                const SizedBox(height: 10),
                const DkSkeleton(width: 184, height: 26, radius: 10),
                const SizedBox(height: 24),
                // 요약 카드(완료율/예약시간 등) 자리.
                const DkSkeleton(height: 104, radius: 18),
                const SizedBox(height: 26),
                const DkSkeleton(width: 96, height: 16),
                const SizedBox(height: 14),
                // 할 일 리스트 자리(4행).
                for (int i = 0; i < 4; i++) ...<Widget>[
                  const _RowSkeleton(),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 할 일 행 스켈레톤: 체크 원 + 제목/부제 두 줄(실제 TaskRow 레이아웃 근사).
class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        children: <Widget>[
          const DkSkeleton(width: 22, height: 22, radius: 11),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                DkSkeleton(width: 140, height: 13),
                SizedBox(height: 8),
                DkSkeleton(width: 90, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
