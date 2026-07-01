import 'package:ieoseo/data/dday.dart';
import 'package:ieoseo/data/format.dart';
import 'package:ieoseo/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ddayInfo (오늘 = 2026-06-01)', () {
    test('T1 미래 날짜는 D-N과 임박도를 계산한다', () {
      const DkEvent ev = DkEvent(
        id: 'e',
        type: DkEventType.single,
        title: '시험',
        category: '자격증',
        date: '2026-06-29',
      );

      final DkDdayInfo info = ddayInfo(ev, DateTime(2026, 6, 1));

      expect(info.diff, 28);
      expect(info.label, 'D-28');
      expect(info.urgency, DkUrgency.low);
    });

    test('T1 당일은 D-DAY · high', () {
      const DkEvent ev = DkEvent(
        id: 'e',
        type: DkEventType.single,
        title: '오늘 마감',
        category: '기타',
        date: '2026-06-01',
      );

      final DkDdayInfo info = ddayInfo(ev, DateTime(2026, 6, 1));

      expect(info.diff, 0);
      expect(info.label, 'D-DAY');
      expect(info.urgency, DkUrgency.high);
    });

    test('T1 지난 날짜는 D+N · past', () {
      const DkEvent ev = DkEvent(
        id: 'e',
        type: DkEventType.single,
        title: '지난 일',
        category: '기타',
        date: '2026-05-29',
      );

      final DkDdayInfo info = ddayInfo(ev, DateTime(2026, 6, 1));

      expect(info.diff, -3);
      expect(info.label, 'D+3');
      expect(info.urgency, DkUrgency.past);
    });

    test('T2 진행률은 0~100으로 클램프되고 상태를 매긴다', () {
      const DkEvent ev = DkEvent(
        id: 'e',
        type: DkEventType.progress,
        title: '챌린지',
        category: '건강',
        start: '2026-04-01',
        end: '2026-07-09',
      );

      final DkDdayInfo info = ddayInfo(ev, DateTime(2026, 6, 1));

      // 전체 99일 중 61일 경과 → 약 62%.
      expect(info.total, 99);
      expect(info.past, 61);
      expect(info.pct, 62);
      expect(info.status, '진행중');
    });

    test('T3 기간 시작 전은 "시작 D-N · 예정"', () {
      const DkEvent ev = DkEvent(
        id: 'e',
        type: DkEventType.period,
        title: '접수',
        category: '자격증',
        start: '2026-06-08',
        end: '2026-06-12',
      );

      final DkDdayInfo info = ddayInfo(ev, DateTime(2026, 6, 1));

      expect(info.toStart, 7);
      expect(info.label, '시작 D-7');
      expect(info.status, '예정');
    });
  });

  // 기간 D-Day 단계 전이(오늘 = 2026-06-10). 시작 전→시작당일→진행중→마감당일→종료.
  // 임박도(urgency)는 "지금 표시 중인 경계" 기준: 시작 전=시작거리, 진행 중=마감거리,
  // 종료=past(강조 해제).
  group('기간 D-Day 단계 (오늘 = 2026-06-10)', () {
    DkEvent period(String start, String end) => DkEvent(
      id: 'e',
      type: DkEventType.period,
      title: '기간',
      category: '자격증',
      start: start,
      end: end,
    );

    final DateTime today = DateTime(2026, 6, 10);

    test('시작 전 임박은 시작거리로 urgency 를 계산한다', () {
      // 시작 D-2(임박), 마감은 멀다 → high 는 시작 기준이어야 한다.
      final DkDdayInfo info = ddayInfo(
        period('2026-06-12', '2026-06-30'),
        today,
      );
      expect(info.label, '시작 D-2');
      expect(info.status, '예정');
      expect(info.urgency, DkUrgency.high);
    });

    test('시작 당일은 "시작 D-DAY · high"', () {
      final DkDdayInfo info = ddayInfo(
        period('2026-06-10', '2026-06-20'),
        today,
      );
      expect(info.label, '시작 D-DAY');
      expect(info.status, '진행중');
      expect(info.urgency, DkUrgency.high);
    });

    test('진행 중은 "마감 D-N", 임박도는 마감거리 기준', () {
      final DkDdayInfo info = ddayInfo(
        period('2026-06-05', '2026-06-14'),
        today,
      );
      expect(info.label, '마감 D-4');
      expect(info.status, '진행중');
      expect(info.urgency, DkUrgency.mid);
    });

    test('마감 당일은 "마감 D-DAY · high"', () {
      final DkDdayInfo info = ddayInfo(
        period('2026-06-01', '2026-06-10'),
        today,
      );
      expect(info.label, '마감 D-DAY');
      expect(info.status, '진행중');
      expect(info.urgency, DkUrgency.high);
    });

    test('마감 다음 날부터 "마감 D+N · 종료 · past"(자동 삭제 아님)', () {
      final DkDdayInfo info = ddayInfo(
        period('2026-06-01', '2026-06-08'),
        today,
      );
      expect(info.label, '마감 D+2');
      expect(info.status, '종료');
      expect(info.urgency, DkUrgency.past);
    });
  });

  // 진행률(%) 뷰도 기간 D-Day 와 같은 start+end 데이터의 다른 표현이므로, 마감이 지나면
  // 100% 에 멈추지 않고 '마감 D+N'(past)로 수렴한다 — 종료 정책(안 사라지고 계속 노출)과 일치.
  group('기간 진행률 마감 후 (오늘 = 2026-06-10)', () {
    DkEvent prog(String start, String end) => DkEvent(
      id: 'e',
      type: DkEventType.progress,
      title: '기간',
      category: '건강',
      start: start,
      end: end,
    );

    final DateTime today = DateTime(2026, 6, 10);

    test('진행 중은 진행률%와 진행중 상태(강조 해제 아님)', () {
      // 전체 10일 중 9일 경과 → 90%.
      final DkDdayInfo info = ddayInfo(prog('2026-06-01', '2026-06-11'), today);
      expect(info.pct, 90);
      expect(info.status, '진행중');
      expect(info.urgency, isNot(DkUrgency.past));
    });

    test('마감 당일은 100% · 완료(아직 D+ 아님)', () {
      // 전체 9일 중 9일 경과 → 100%, 초과 없음.
      final DkDdayInfo info = ddayInfo(prog('2026-06-01', '2026-06-10'), today);
      expect(info.pct, 100);
      expect(info.status, '완료');
      expect(info.urgency, isNot(DkUrgency.past));
    });

    test('마감 후는 100% 고정 + "마감 D+N · 종료 · past"', () {
      // 전체 7일, 9일 경과 → 2일 초과.
      final DkDdayInfo info = ddayInfo(prog('2026-06-01', '2026-06-08'), today);
      expect(info.pct, 100);
      expect(info.label, '마감 D+2');
      expect(info.status, '종료');
      expect(info.urgency, DkUrgency.past);
    });
  });

  group('urgencyOf', () {
    test('경계값 분류', () {
      expect(urgencyOf(-1), DkUrgency.past);
      expect(urgencyOf(0), DkUrgency.high);
      expect(urgencyOf(3), DkUrgency.high);
      expect(urgencyOf(4), DkUrgency.mid);
      expect(urgencyOf(7), DkUrgency.mid);
      expect(urgencyOf(8), DkUrgency.low);
    });
  });

  group('fmtMins', () {
    test('분/시간 라벨', () {
      expect(fmtMins(30), '30분');
      expect(fmtMins(60), '1시간');
      expect(fmtMins(90), '1시간 30분');
    });
  });
}
