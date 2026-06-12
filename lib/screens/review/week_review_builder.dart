import '../../data/format.dart';
import '../../data/meta.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';

/// 집중 목표 기본값(하루 세션 수). server/설정에 집중 목표가 생기기 전까지의 기본.
const int kDefaultFocusGoal = 8;

/// 실제 로드된 [tasks]/[debts] 에서 [DkWeekReview](지난주 회고)를 파생한다.
///
/// server 에 주간 리뷰 엔드포인트가 없어, 기존 목 상수([kWeekReview])의 조작된
/// 수치 대신 로드된 실데이터로 정직하게 계산한다. 실제 출처가 없는 필드는
/// 0/빈 값/중립 문구로 둔다(절대 지어내지 않는다).
///
/// - 주 범위: [reference](기본 [kToday])가 속한 월~일 7일.
/// - planned/done: 그 주 task 의 전체/완료 건수.
/// - carried: 미해소 미룬 시간([debts]) 합계(시간 단위, 분→시 반올림).
/// - byDay: 요일(월~일)별 계획/완료 건수 막대(allDone = 계획>0 이고 전부 완료).
/// - byCategory: task 카테고리별 예상 소요(분) 분포. 카테고리가 없으면 빈 목록.
/// - insight: 데이터에서 도출한 중립 문구(가장 빠듯했던 요일 안내). 데이터 없으면 격려 문구.
DkWeekReview buildWeekReview({
  required List<DkTask> tasks,
  required List<DkDebt> debts,
  DateTime? reference,
}) {
  final DateTime today = reference ?? kToday;
  // 월요일(주 시작)로 정규화. Dart weekday: 월=1 … 일=7.
  final DateTime weekStart = addDays(today, 1 - today.weekday);
  final List<DateTime> weekDates = <DateTime>[
    for (int i = 0; i < 7; i++) addDays(weekStart, i),
  ];
  final Set<String> weekKeys = weekDates.map(ymd).toSet();

  final List<DkTask> weekTasks = tasks
      .where((DkTask t) => weekKeys.contains(t.date))
      .toList(growable: false);

  final int planned = weekTasks.length;
  final int done = weekTasks
      .where((DkTask t) => t.state == DkTaskState.done)
      .length;

  // 미해소(대기/배정/계속밀림) 미룬 시간 합계 → 시간 단위(반올림).
  final int carriedMins = debts
      .where(
        (DkDebt d) =>
            d.status == DkDebtStatus.pending ||
            d.status == DkDebtStatus.assigned ||
            d.status == DkDebtStatus.overdue,
      )
      .fold(0, (int s, DkDebt d) => s + d.mins);
  final int carried = (carriedMins / 60).round();

  // 요일별(월~일) 계획/완료 건수.
  const List<String> dayLabels = <String>['월', '화', '수', '목', '금', '토', '일'];
  final List<DkReviewDay> byDay = <DkReviewDay>[];
  for (int i = 0; i < 7; i++) {
    final String key = ymd(weekDates[i]);
    final Iterable<DkTask> dayTasks = weekTasks.where(
      (DkTask t) => t.date == key,
    );
    final double dPlanned = dayTasks.length.toDouble();
    final double dDone = dayTasks
        .where((DkTask t) => t.state == DkTaskState.done)
        .length
        .toDouble();
    byDay.add(
      DkReviewDay(
        dayLabels[i],
        dPlanned,
        dDone,
        dPlanned > 0 && dDone >= dPlanned,
      ),
    );
  }

  // 카테고리별 예상 소요(분). 카테고리가 비어 있으면 분포는 빈 목록(지어내지 않음).
  final Map<String, int> catMins = <String, int>{};
  for (final DkTask t in weekTasks) {
    final String cat = t.category.trim();
    if (cat.isEmpty) continue;
    catMins[cat] = (catMins[cat] ?? 0) + t.mins;
  }
  final List<MapEntry<String, int>> sortedCats = catMins.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
      final int byMins = b.value.compareTo(a.value);
      return byMins != 0 ? byMins : a.key.compareTo(b.key);
    });
  final List<DkReviewCategory> byCategory = <DkReviewCategory>[
    for (final MapEntry<String, int> e in sortedCats)
      DkReviewCategory(e.key, e.value, kCategoryHue[e.key] ?? 'cool'),
  ];

  return DkWeekReview(
    range: _weekRangeLabel(weekDates.first, weekDates.last),
    planned: planned,
    done: done,
    carried: carried,
    byDay: byDay,
    byCategory: byCategory,
    insight: _insightFor(planned: planned, done: done, byDay: byDay),
  );
}

/// "M월 D일 - M월 D일" 라벨.
String _weekRangeLabel(DateTime start, DateTime end) =>
    '${start.month}월 ${start.day}일 - ${end.month}월 ${end.day}일';

/// 데이터에서 도출한 중립 인사이트(지어낸 칭찬/수치 없음).
String _insightFor({
  required int planned,
  required int done,
  required List<DkReviewDay> byDay,
}) {
  if (planned == 0) {
    return '이번 주엔 계획한 일이 없었어요. 다음 주에 작은 일부터 하나씩 담아볼까요?';
  }
  // 계획이 있으나 완료가 가장 부족했던(미완료율 최대) 요일을 안내.
  DkReviewDay? tightest;
  double worstGap = 0;
  for (final DkReviewDay d in byDay) {
    if (d.planned <= 0) continue;
    final double gap = (d.planned - d.done) / d.planned;
    if (gap > worstGap) {
      worstGap = gap;
      tightest = d;
    }
  }
  if (tightest == null || worstGap <= 0) {
    return '계획한 일을 모두 끝냈어요. 이 페이스를 다음 주에도 이어가 볼까요?';
  }
  return '${tightest.day}요일이 가장 빠듯했어요. 다음 주엔 ${tightest.day}요일 계획을 조금 가볍게 잡아볼까요?';
}
