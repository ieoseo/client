import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/models.dart';

void main() {
  group('DkTask.copyWith 센티넬', () {
    const DkTask base = DkTask(
      id: 't',
      title: '할 일',
      mins: 30,
      date: '2026-06-16',
      state: DkTaskState.done,
      category: '공부',
      actualMins: 25,
      eventId: 'e1',
    );

    test('인자를 생략하면 기존 nullable 값을 유지한다', () {
      final DkTask next = base.copyWith(state: DkTaskState.today);
      expect(next.state, DkTaskState.today);
      expect(next.actualMins, 25); // 유지
      expect(next.eventId, 'e1'); // 유지
    });

    test('null 을 명시하면 nullable 필드를 비운다(reopen 등)', () {
      final DkTask next = base.copyWith(
        state: DkTaskState.today,
        actualMins: null,
      );
      expect(next.state, DkTaskState.today);
      expect(next.actualMins, isNull); // 비워짐
      expect(next.eventId, 'e1'); // 미지정이라 유지
    });
  });

  group('DkEvent.copyWith 센티넬', () {
    const DkEvent base = DkEvent(
      id: 'e',
      type: DkEventType.period,
      title: '여행',
      category: '개인',
      start: '2026-07-01',
      end: '2026-07-05',
    );

    test('인자를 생략하면 기존 nullable 날짜를 유지한다', () {
      final DkEvent next = base.copyWith(title: '제주 여행');
      expect(next.title, '제주 여행');
      expect(next.start, '2026-07-01'); // 유지
      expect(next.end, '2026-07-05'); // 유지
    });

    test('null 을 명시하면 nullable 날짜를 비운다(기간→단일 전환 등)', () {
      final DkEvent next = base.copyWith(
        type: DkEventType.single,
        date: '2026-07-01',
        start: null,
        end: null,
      );
      expect(next.date, '2026-07-01');
      expect(next.start, isNull); // 비워짐
      expect(next.end, isNull); // 비워짐
    });
  });

  group('DkDebt.copyWith 센티넬', () {
    const DkDebt base = DkDebt(
      id: 'd',
      title: '이력서 수정',
      mins: 45,
      fromDate: '2026-06-12',
      status: DkDebtStatus.assigned,
      assignedTo: '2026-06-15',
      fromLabel: '지난주 금요일',
    );

    test('인자를 생략하면 기존 nullable 값을 유지한다', () {
      final DkDebt next = base.copyWith(mins: 60);
      expect(next.mins, 60);
      expect(next.assignedTo, '2026-06-15'); // 유지
      expect(next.fromLabel, '지난주 금요일'); // 유지
    });

    test('null 을 명시하면 nullable 필드를 비운다(배정 해제 등)', () {
      final DkDebt next = base.copyWith(
        status: DkDebtStatus.pending,
        assignedTo: null,
      );
      expect(next.status, DkDebtStatus.pending);
      expect(next.assignedTo, isNull); // 비워짐
      expect(next.fromLabel, '지난주 금요일'); // 미지정이라 유지
    });
  });
}
