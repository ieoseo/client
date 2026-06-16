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
}
