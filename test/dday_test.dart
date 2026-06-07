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

      final DkDdayInfo info = ddayInfo(ev, kToday);

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

      final DkDdayInfo info = ddayInfo(ev, kToday);

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

      final DkDdayInfo info = ddayInfo(ev, kToday);

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

      final DkDdayInfo info = ddayInfo(ev, kToday);

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

      final DkDdayInfo info = ddayInfo(ev, kToday);

      expect(info.toStart, 7);
      expect(info.label, '시작 D-7');
      expect(info.status, '예정');
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
