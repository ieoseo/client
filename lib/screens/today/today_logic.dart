import 'package:flutter/foundation.dart';

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
