import 'package:ieoseo/data/api/dtos.dart';
import 'package:ieoseo/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// 반복 태스크(FRD 5.4) 클라이언트 모델·DTO 매핑 단위 테스트.
///
/// - DkRecurrence 값(없음/주간 요일집합/월간 일자/연간 월일)과 isRecurring.
/// - DkTaskDto.fromJson 이 server recurrence 블록을 파싱.
/// - DkTaskDto.toCreateJson 이 반복 규칙을 계약(frequency·weeklyDays 코드 등)으로 보냄.
void main() {
  group('DkRecurrence 모델', () {
    test('none 은 비반복이고 weeklyDays 가 비어 있다', () {
      const DkRecurrence r = DkRecurrence.none;
      expect(r.frequency, DkRecurrenceFreq.none);
      expect(r.isRecurring, isFalse);
      expect(r.weeklyDays, isEmpty);
    });

    test('weekly 는 요일 집합을 갖고 반복이다', () {
      const DkRecurrence r = DkRecurrence(
        frequency: DkRecurrenceFreq.weekly,
        weeklyDays: <int>{1, 3, 5}, // 월·수·금 (DateTime.weekday 기준: 월=1)
      );
      expect(r.isRecurring, isTrue);
      expect(r.weeklyDays, <int>{1, 3, 5});
    });

    test('monthly·yearly 도 반복이다', () {
      expect(
        const DkRecurrence(
          frequency: DkRecurrenceFreq.monthly,
          monthDay: 15,
        ).isRecurring,
        isTrue,
      );
      expect(
        const DkRecurrence(
          frequency: DkRecurrenceFreq.yearly,
          yearMonth: 8,
          yearDay: 2,
        ).isRecurring,
        isTrue,
      );
    });
  });

  group('DkTaskDto recurrence 매핑', () {
    test('응답의 WEEKLY recurrence 를 요일 집합으로 파싱한다', () {
      final DkTask task = DkTaskDto.fromJson(<String, dynamic>{
        'id': 't-1',
        'title': '영어 단어',
        'estimatedMinutes': 30,
        'date': '2026-06-01',
        'state': 'TODAY',
        'category': '어학',
        'recurrence': <String, dynamic>{
          'frequency': 'WEEKLY',
          'weeklyDays': <String>['MON', 'WED', 'FRI'],
          'monthDay': null,
          'yearMonth': null,
          'yearDay': null,
        },
      });

      expect(task.recurrence.frequency, DkRecurrenceFreq.weekly);
      expect(task.recurrence.weeklyDays, <int>{1, 3, 5});
      expect(task.recurrence.isRecurring, isTrue);
    });

    test('recurrence 누락 시 none 으로 보수적 매핑한다', () {
      final DkTask task = DkTaskDto.fromJson(<String, dynamic>{
        'id': 't-2',
        'title': '단발',
        'estimatedMinutes': 30,
        'date': '2026-06-01',
        'state': 'TODAY',
        'category': '공부',
      });

      expect(task.recurrence.frequency, DkRecurrenceFreq.none);
      expect(task.recurrence.isRecurring, isFalse);
    });

    test('MONTHLY·YEARLY 응답을 파싱한다', () {
      final DkTask monthly = DkTaskDto.fromJson(<String, dynamic>{
        'id': 't-3',
        'title': '월세',
        'estimatedMinutes': 15,
        'date': '2026-06-15',
        'state': 'PENDING',
        'category': '생활',
        'recurrence': <String, dynamic>{'frequency': 'MONTHLY', 'monthDay': 15},
      });
      expect(monthly.recurrence.frequency, DkRecurrenceFreq.monthly);
      expect(monthly.recurrence.monthDay, 15);

      final DkTask yearly = DkTaskDto.fromJson(<String, dynamic>{
        'id': 't-4',
        'title': '검진',
        'estimatedMinutes': 120,
        'date': '2026-08-02',
        'state': 'PENDING',
        'category': '건강',
        'recurrence': <String, dynamic>{
          'frequency': 'YEARLY',
          'yearMonth': 8,
          'yearDay': 2,
        },
      });
      expect(yearly.recurrence.frequency, DkRecurrenceFreq.yearly);
      expect(yearly.recurrence.yearMonth, 8);
      expect(yearly.recurrence.yearDay, 2);
    });

    test('toCreateJson 은 WEEKLY 규칙을 요일 코드 집합으로 보낸다', () {
      const DkTask task = DkTask(
        id: '',
        title: '영어 단어',
        mins: 30,
        date: '2026-06-01',
        state: DkTaskState.pending,
        category: '어학',
        recurrence: DkRecurrence(
          frequency: DkRecurrenceFreq.weekly,
          weeklyDays: <int>{1, 3, 5},
        ),
      );

      final Map<String, dynamic> body = DkTaskDto.toCreateJson(task);
      final Map<String, dynamic> rec =
          body['recurrence'] as Map<String, dynamic>;

      expect(rec['frequency'], 'WEEKLY');
      expect((rec['weeklyDays'] as List<dynamic>).toSet(), <String>{
        'MON',
        'WED',
        'FRI',
      });
    });

    test('toCreateJson 은 none 규칙이면 recurrence 를 보내지 않는다', () {
      const DkTask task = DkTask(
        id: '',
        title: '단발',
        mins: 30,
        date: '2026-06-01',
        state: DkTaskState.pending,
        category: '공부',
      );

      final Map<String, dynamic> body = DkTaskDto.toCreateJson(task);

      expect(body.containsKey('recurrence'), isFalse);
    });

    test('toCreateJson 은 MONTHLY 규칙을 일자로 보낸다', () {
      const DkTask task = DkTask(
        id: '',
        title: '월세',
        mins: 15,
        date: '2026-06-15',
        state: DkTaskState.pending,
        category: '생활',
        recurrence: DkRecurrence(
          frequency: DkRecurrenceFreq.monthly,
          monthDay: 15,
        ),
      );

      final Map<String, dynamic> rec =
          DkTaskDto.toCreateJson(task)['recurrence'] as Map<String, dynamic>;

      expect(rec['frequency'], 'MONTHLY');
      expect(rec['monthDay'], 15);
    });
  });
}
