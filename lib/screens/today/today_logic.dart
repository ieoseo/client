import 'package:flutter/foundation.dart';

import '../../data/format.dart';
import '../../data/models.dart';

/// 오늘 탭의 파생 통계(불변). 프로토타입 `TodayScreen`의 계산부를 추출한다.
@immutable
class TodayStats {
  const TodayStats({
    required this.total,
    required this.doneCount,
    required this.donePct,
    required this.remainMins,
    required this.next,
    required this.allDone,
    required this.agenda,
  });

  /// 오늘 할 일 총 개수.
  final int total;

  /// 완료 개수.
  final int doneCount;

  /// 완료율(%).
  final int donePct;

  /// 남은 예상 소요(분).
  final int remainMins;

  /// 다음 미완료 할 일(없으면 null).
  final DkTask? next;

  /// 모두 완료 여부(할 일이 1개 이상이고 미완료가 0).
  final bool allDone;

  /// 아젠다 순서: 미완료(다음 먼저) → 완료.
  final List<DkTask> agenda;
}

/// D-Day 정렬키: 가장 가까운 미래 시점(목표일·시작·마감)까지 남은 일수.
/// 미래 일정이 작은 값으로 먼저 오고, 모두 지난 일정은 큰 값으로 뒤로 보낸다.
int _ddayKey(DkEvent ev, DateTime today) {
  final List<int> marks = <int>[
    if (ev.date != null) daysBetween(today, ev.date!),
    if (ev.start != null) daysBetween(today, ev.start!),
    if (ev.end != null) daysBetween(today, ev.end!),
  ];
  if (marks.isEmpty) return 1 << 30;
  final List<int> future = marks.where((int d) => d >= 0).toList()..sort();
  if (future.isNotEmpty) return future.first; // 가장 임박한 미래
  // 전부 과거면 뒤로 — 가장 최근 과거가 그나마 앞.
  marks.sort();
  return (1 << 29) - marks.last;
}

/// 이벤트를 정렬한다: **핀 고정 먼저**(#162), 그 안에서 D-Day 임박순(가장 임박한 순).
/// 원본은 변형하지 않고 새 리스트 반환.
List<DkEvent> ddayOrdered(List<DkEvent> events, {DateTime? today}) {
  final DateTime t = today ?? kToday;
  final List<DkEvent> ordered = <DkEvent>[...events];
  ordered.sort((DkEvent a, DkEvent b) {
    // 핀 고정이 항상 상단(pinned=true 먼저).
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return _ddayKey(a, t).compareTo(_ddayKey(b, t));
  });
  return ordered;
}

/// [tasks] 중 [today] 날짜의 할 일로 통계를 계산한다.
TodayStats todayStats(List<DkTask> tasks, String today) {
  final List<DkTask> todayTasks = tasks
      .where((DkTask t) => t.date == today)
      .toList();
  final List<DkTask> pending = todayTasks
      .where((DkTask t) => t.state != DkTaskState.done)
      .toList();
  final List<DkTask> done = todayTasks
      .where((DkTask t) => t.state == DkTaskState.done)
      .toList();

  final int total = todayTasks.length;
  final int doneCount = total - pending.length;
  final int donePct = total == 0 ? 0 : (doneCount / total * 100).round();
  final int remainMins = pending.fold(0, (int s, DkTask t) => s + t.mins);
  final DkTask? next = pending.isNotEmpty ? pending.first : null;
  final bool allDone = total > 0 && pending.isEmpty;

  return TodayStats(
    total: total,
    doneCount: doneCount,
    donePct: donePct,
    remainMins: remainMins,
    next: next,
    allDone: allDone,
    agenda: <DkTask>[...pending, ...done],
  );
}
