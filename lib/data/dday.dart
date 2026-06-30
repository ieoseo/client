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
      // 단계 전이: 시작 전 → 시작당일 → 진행중 → 마감당일 → 종료.
      // 임박도(urgency)는 "지금 카운트다운 중인 경계" 기준으로 맞춘다 — 시작 전엔
      // 시작까지, 시작 후엔 마감까지. 종료(D+)는 past 로 강조를 해제한다.
      final String status;
      final String label;
      final DkUrgency urgency;
      if (toStart >= 0) {
        // 시작 전(toStart>0) 또는 시작 당일(toStart==0). 시작일까지 카운트다운.
        status = toStart == 0 ? '진행중' : '예정';
        label = toStart == 0 ? '시작 D-DAY' : '시작 D-$toStart';
        urgency = urgencyOf(toStart);
      } else if (toEnd >= 0) {
        // 진행 중. 마감일까지 카운트다운(마감 당일 = "마감 D-DAY").
        status = '진행중';
        label = toEnd == 0 ? '마감 D-DAY' : '마감 D-$toEnd';
        urgency = urgencyOf(toEnd);
      } else {
        // 종료: 마감일부터 경과(D+). 자동 삭제하지 않고 계속 노출(유저가 종료 처리).
        status = '종료';
        label = '마감 D+${-toEnd}';
        urgency = DkUrgency.past;
      }
      return DkDdayInfo(
        type: DkEventType.period,
        toStart: toStart,
        toEnd: toEnd,
        status: status,
        label: label,
        urgency: urgency,
      );
  }
}
