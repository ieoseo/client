import 'format.dart';
import 'models.dart';

/// D-Day 임박도. 프로토타입 `urgencyOf`.
enum DkUrgency { past, high, mid, low }

/// 남은 일수 → 임박도. high(≤3) / mid(≤7) / low / past(음수).
DkUrgency urgencyOf(int diff) {
  if (diff < 0) return DkUrgency.past;
  if (diff <= 3) return DkUrgency.high;
  if (diff <= 7) return DkUrgency.mid;
  return DkUrgency.low;
}

/// `ddayInfo`의 계산 결과(불변). 타입별로 채워지는 필드가 다르다.
class DkDdayInfo {
  const DkDdayInfo({
    required this.type,
    this.diff = 0,
    this.label = '',
    this.urgency = DkUrgency.low,
    this.pct = 0,
    this.status = '',
    this.total = 0,
    this.past = 0,
    this.toStart = 0,
    this.toEnd = 0,
  });

  final DkEventType type;

  /// T1: 남은 일수.
  final int diff;

  /// 표시 라벨(예: "D-12", "마감 D-3").
  final String label;
  final DkUrgency urgency;

  /// T2: 진행률(%).
  final int pct;

  /// 상태 텍스트(예정/진행중/완료/종료).
  final String status;

  /// T2: 전체 기간(일).
  final int total;

  /// T2: 경과 일수.
  final int past;

  /// T3: 시작까지 일수.
  final int toStart;

  /// T3: 종료까지 일수.
  final int toEnd;
}

/// 이벤트의 D-Day 정보를 계산한다. 프로토타입 `ddayInfo(ev, today)`.
DkDdayInfo ddayInfo(DkEvent ev, [DateTime? today]) {
  final DateTime t = today ?? kToday;

  switch (ev.type) {
    case DkEventType.single:
      final int diff = daysBetween(t, ev.date!);
      final String label = diff > 0
          ? 'D-$diff'
          : (diff == 0 ? 'D-DAY' : 'D+${-diff}');
      return DkDdayInfo(
        type: DkEventType.single,
        diff: diff,
        label: label,
        urgency: urgencyOf(diff),
      );

    case DkEventType.progress:
      final int total = daysBetween(ev.start!, ev.end!);
      final int past = daysBetween(ev.start!, t);
      final int pct = total == 0
          ? 0
          : (past / total * 100).round().clamp(0, 100);
      final String status = past < 0 ? '예정' : (past >= total ? '완료' : '진행중');
      return DkDdayInfo(
        type: DkEventType.progress,
        pct: pct,
        status: status,
        total: total,
        past: past < 0 ? 0 : past,
      );

    case DkEventType.period:
      final int toStart = daysBetween(t, ev.start!);
      final int toEnd = daysBetween(t, ev.end!);
      final String status = toStart > 0 ? '예정' : (toEnd >= 0 ? '진행중' : '종료');
      final String label = toStart > 0
          ? '시작 D-$toStart'
          : (toEnd > 0 ? '마감 D-$toEnd' : (toEnd == 0 ? '마감 D-DAY' : '종료'));
      return DkDdayInfo(
        type: DkEventType.period,
        toStart: toStart,
        toEnd: toEnd,
        status: status,
        label: label,
        urgency: urgencyOf(toEnd),
      );
  }
}
