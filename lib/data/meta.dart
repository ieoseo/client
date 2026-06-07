import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../widgets/dk_badge.dart';
import 'models.dart';

/// 카테고리·상태·출처의 표시 메타데이터. 프로토타입 `CATEGORY_META`/`TASK_STATE`/
/// `DEBT_STATE`/`SOURCE_META`를 Dart로 이식한다.

/// 카테고리명 → 카테고리 hue. 미상은 [DkHue.cool].
DkHue categoryHue(String category) => DkHue.byName(kCategoryHue[category]);

/// 상태 chrome 한 건(톤 + 라벨).
@immutable
class DkStateMeta {
  const DkStateMeta(this.tone, this.label);
  final DkTone tone;
  final String label;
}

/// 태스크 상태 → 톤·라벨. 프로토타입 `TASK_STATE`.
DkStateMeta taskStateMeta(DkTaskState state) => switch (state) {
  DkTaskState.done => const DkStateMeta(DkTone.success, '완료'),
  DkTaskState.today => const DkStateMeta(DkTone.primary, '오늘'),
  DkTaskState.carried => const DkStateMeta(DkTone.info, '옮김'),
  DkTaskState.overdue => const DkStateMeta(DkTone.danger, '밀림'),
  DkTaskState.missed => const DkStateMeta(DkTone.danger, '미완료'),
  DkTaskState.abandoned => const DkStateMeta(DkTone.neutral, '내려놓음'),
  DkTaskState.pending => const DkStateMeta(DkTone.neutral, '예정'),
};

/// 미룬 시간(부채) 상태 → 톤·라벨. 프로토타입 `DEBT_STATE`.
DkStateMeta debtStateMeta(DkDebtStatus status) => switch (status) {
  DkDebtStatus.pending => const DkStateMeta(DkTone.neutral, '대기'),
  DkDebtStatus.assigned => const DkStateMeta(DkTone.info, '배정됨'),
  DkDebtStatus.overdue => const DkStateMeta(DkTone.danger, '계속 밀림'),
  DkDebtStatus.resolved => const DkStateMeta(DkTone.success, '해소'),
  DkDebtStatus.abandoned => const DkStateMeta(DkTone.neutral, '내려놓음'),
};

/// 외부 출처 메타(라벨 + 점 색). 프로토타입 `SOURCE_META`.
@immutable
class DkSourceMeta {
  const DkSourceMeta(this.label, this.color);
  final String label;
  final Color color;
}

/// 출처 → 메타. `app`은 토큰 primary를 쓰므로 호출부에서 색을 덮어쓴다.
DkSourceMeta sourceMeta(DkSource source) => switch (source) {
  DkSource.app => const DkSourceMeta('이어서', Color(0xFF0066FF)),
  DkSource.google => const DkSourceMeta('Google', Color(0xFF34A853)),
  DkSource.apple => const DkSourceMeta('Apple', Color(0xFF111111)),
  DkSource.notion => const DkSourceMeta('Notion', Color(0xFF7B61FF)),
};

/// 모든 출처(범례용, app→notion 순).
const List<DkSource> kSourceOrder = <DkSource>[
  DkSource.app,
  DkSource.google,
  DkSource.apple,
  DkSource.notion,
];

/// 주간 리뷰의 요일별 실행 한 건.
@immutable
class DkReviewDay {
  const DkReviewDay(this.day, this.planned, this.done, this.allDone);
  final String day;
  final double planned;
  final double done;
  final bool allDone;
}

/// 주간 리뷰의 카테고리 분포 한 건.
@immutable
class DkReviewCategory {
  const DkReviewCategory(this.cat, this.mins, this.color);
  final String cat;
  final int mins;

  /// hue 이름.
  final String color;
}

/// 주간 리뷰(지난주 회고). 프로토타입 `WEEK_REVIEW`.
@immutable
class DkWeekReview {
  const DkWeekReview({
    required this.range,
    required this.planned,
    required this.done,
    required this.carried,
    required this.byDay,
    required this.byCategory,
    required this.insight,
  });

  final String range;
  final int planned;
  final int done;
  final int carried;
  final List<DkReviewDay> byDay;
  final List<DkReviewCategory> byCategory;
  final String insight;
}

/// 주간 리뷰 목 데이터. 프로토타입 `WEEK_REVIEW` 값 그대로.
const DkWeekReview kWeekReview = DkWeekReview(
  range: '5월 25일 – 5월 31일',
  planned: 21,
  done: 16,
  carried: 5,
  byDay: <DkReviewDay>[
    DkReviewDay('월', 3.5, 3.0, false),
    DkReviewDay('화', 4.0, 4.0, true),
    DkReviewDay('수', 3.0, 1.5, false),
    DkReviewDay('목', 3.5, 2.0, false),
    DkReviewDay('금', 2.0, 1.5, false),
    DkReviewDay('토', 3.0, 3.0, true),
    DkReviewDay('일', 2.0, 2.0, true),
  ],
  byCategory: <DkReviewCategory>[
    DkReviewCategory('자격증', 360, 'violet'),
    DkReviewCategory('어학', 240, 'blue'),
    DkReviewCategory('건강', 210, 'green'),
    DkReviewCategory('취업', 150, 'orange'),
    DkReviewCategory('기타', 60, 'cool'),
  ],
  insight: '화·토·일은 계획을 모두 지켰어요. 수요일이 가장 빠듯했네요 — 이번 주엔 수요일 계획을 조금 가볍게 잡아볼까요?',
);
