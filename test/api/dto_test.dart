import 'package:ieoseo/data/api/dtos.dart';
import 'package:ieoseo/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// DTO 매핑 테스트(이슈 #35). 서버 응답 `data` 구조 ↔ DkEvent/DkTask/DkDebt.
/// 계약: docs/05-API/events-tasks-debts.md, server web/dto/*.
void main() {
  group('DkEventDto', () {
    test('T1 단건 응답을 파싱한다(date·enum 코드·pinned)', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 'e-1',
        'type': 'T1_DDAY',
        'title': '정처기 실기',
        'category': '자격증',
        'date': '2026-08-02',
        'startDate': null,
        'endDate': null,
        'pinned': true,
        'memo': '실기 D-Day',
        'color': '#4F46E5',
        'createdAt': '2026-06-04T09:00:00Z',
        'updatedAt': '2026-06-04T09:00:00Z',
      };

      final DkEvent ev = DkEventDto.fromJson(json);

      expect(ev.id, 'e-1');
      expect(ev.type, DkEventType.single);
      expect(ev.title, '정처기 실기');
      expect(ev.category, '자격증');
      expect(ev.date, '2026-08-02');
      expect(ev.start, isNull);
      expect(ev.end, isNull);
      expect(ev.pinned, isTrue);
      expect(ev.memo, '실기 D-Day');
      expect(ev.color, '#4F46E5');
    });

    test('T3 기간 응답을 파싱한다(startDate/endDate → start/end)', () {
      final DkEvent ev = DkEventDto.fromJson(<String, dynamic>{
        'id': 'e-3',
        'type': 'T3_PERIOD_DDAY',
        'title': '접수',
        'category': null,
        'date': null,
        'startDate': '2026-06-08',
        'endDate': '2026-06-12',
        'pinned': false,
        'memo': null,
        'color': null,
      });

      expect(ev.type, DkEventType.period);
      expect(ev.start, '2026-06-08');
      expect(ev.end, '2026-06-12');
      expect(ev.category, '');
      expect(ev.memo, '');
    });

    test('생성 본문(toCreateJson)은 enum 코드·날짜를 계약대로 만든다', () {
      const DkEvent ev = DkEvent(
        id: '',
        type: DkEventType.progress,
        title: '챌린지',
        category: '건강',
        start: '2026-04-01',
        end: '2026-07-09',
        pinned: false,
        memo: '주 4회',
        color: 'green',
      );

      final Map<String, dynamic> body = DkEventDto.toCreateJson(ev);

      expect(body['type'], 'T2_PROGRESS');
      expect(body['title'], '챌린지');
      expect(body['startDate'], '2026-04-01');
      expect(body['endDate'], '2026-07-09');
      expect(body['date'], isNull);
      expect(body['color'], 'green');
      expect(body.containsKey('id'), isFalse);
    });

    test('round-trip: 응답 파싱 후 생성 본문이 핵심 필드를 보존한다', () {
      final DkEvent ev = DkEventDto.fromJson(<String, dynamic>{
        'id': 'e-9',
        'type': 'T1_DDAY',
        'title': 'X',
        'category': '자격증',
        'date': '2026-08-02',
        'pinned': true,
        'memo': 'm',
        'color': '#fff',
      });
      final Map<String, dynamic> body = DkEventDto.toCreateJson(ev);
      expect(body['type'], 'T1_DDAY');
      expect(body['date'], '2026-08-02');
      expect(body['pinned'], true);
    });
  });

  group('DkTaskDto', () {
    test('단건 응답을 파싱한다(estimatedMinutes→mins·state·fromDate)', () {
      final DkTask task = DkTaskDto.fromJson(<String, dynamic>{
        'id': 't-1',
        'title': '알고리즘 2문제',
        'estimatedMinutes': 60,
        'date': '2026-06-04',
        'state': 'TODAY',
        'category': '공부',
        'eventId': 'e-1',
        'fromDate': null,
        'actualMinutes': null,
        'createdAt': '2026-06-04T09:00:00Z',
        'updatedAt': '2026-06-04T09:00:00Z',
      });

      expect(task.id, 't-1');
      expect(task.title, '알고리즘 2문제');
      expect(task.mins, 60);
      expect(task.date, '2026-06-04');
      expect(task.state, DkTaskState.today);
      expect(task.category, '공부');
      expect(task.eventId, 'e-1');
      expect(task.fromDate, isNull);
      expect(task.actualMins, isNull);
    });

    test('CARRIED 상태·actualMinutes·fromDate를 파싱한다', () {
      final DkTask task = DkTaskDto.fromJson(<String, dynamic>{
        'id': 't-5',
        'title': '이력서',
        'estimatedMinutes': 45,
        'date': '2026-06-04',
        'state': 'CARRIED',
        'category': '취업',
        'eventId': null,
        'fromDate': '2026-05-29',
        'actualMinutes': 50,
      });

      expect(task.state, DkTaskState.carried);
      expect(task.fromDate, '2026-05-29');
      expect(task.actualMins, 50);
    });

    test('생성 본문(toCreateJson)은 계약 필드만 담는다', () {
      const DkTask task = DkTask(
        id: '',
        title: '단어 30개',
        mins: 30,
        date: '2026-06-04',
        state: DkTaskState.pending,
        category: '어학',
        eventId: 'e-2',
      );

      final Map<String, dynamic> body = DkTaskDto.toCreateJson(task);

      expect(body['title'], '단어 30개');
      expect(body['estimatedMinutes'], 30);
      expect(body['date'], '2026-06-04');
      expect(body['category'], '어학');
      expect(body['eventId'], 'e-2');
      expect(body.containsKey('state'), isFalse);
      expect(body.containsKey('id'), isFalse);
    });

    test('범위 태스크 startDate 를 파싱하고 생성 본문에 담는다(#50)', () {
      final DkTask task = DkTaskDto.fromJson(<String, dynamic>{
        'id': 't-r',
        'title': '여행 준비',
        'estimatedMinutes': 120,
        'date': '2026-06-07',
        'startDate': '2026-06-04',
        'state': 'TODAY',
        'category': '개인',
      });

      expect(task.startDate, '2026-06-04');
      expect(task.date, '2026-06-07');
      expect(task.isRange, isTrue);
      expect(DkTaskDto.toCreateJson(task)['startDate'], '2026-06-04');
    });

    test('단일 태스크는 startDate 가 null 이고 생성 본문에서 생략된다(#50)', () {
      final DkTask task = DkTaskDto.fromJson(<String, dynamic>{
        'id': 't-s',
        'title': '단어 30개',
        'estimatedMinutes': 30,
        'date': '2026-06-04',
        'state': 'TODAY',
      });

      expect(task.startDate, isNull);
      expect(task.isRange, isFalse);
      expect(DkTaskDto.toCreateJson(task).containsKey('startDate'), isFalse);
    });
  });

  group('DkDebtDto', () {
    test(
      '단건 응답을 파싱한다(minutes→mins·originDate→fromDate·carriedToDate→assignedTo·title·fromLabel)',
      () {
        final DkDebt debt = DkDebtDto.fromJson(<String, dynamic>{
          'id': 'd-1',
          'taskId': 't-5',
          'title': '알고리즘 2문제 풀기',
          'fromLabel': '월요일',
          'minutes': 60,
          'originDate': '2026-06-01',
          'status': 'CARRIED',
          'carriedToDate': '2026-06-07',
          'createdAt': '2026-06-02T00:00:00Z',
          'updatedAt': '2026-06-02T00:00:00Z',
        });

        expect(debt.id, 'd-1');
        expect(debt.title, '알고리즘 2문제 풀기');
        expect(debt.fromLabel, '월요일');
        expect(debt.mins, 60);
        expect(debt.fromDate, '2026-06-01');
        expect(debt.status, DkDebtStatus.assigned);
        expect(debt.assignedTo, '2026-06-07');
      },
    );

    test('PENDING·carriedToDate 없음을 파싱한다', () {
      final DkDebt debt = DkDebtDto.fromJson(<String, dynamic>{
        'id': 'd-4',
        'taskId': 't-9',
        'minutes': 75,
        'originDate': '2026-05-30',
        'status': 'PENDING',
        'carriedToDate': null,
      });

      expect(debt.status, DkDebtStatus.pending);
      expect(debt.assignedTo, isNull);
    });

    test('title·fromLabel 누락 시 보수적 기본값으로 매핑한다', () {
      final DkDebt debt = DkDebtDto.fromJson(<String, dynamic>{
        'id': 'd-7',
        'taskId': 't-2',
        'minutes': 30,
        'originDate': '2026-05-29',
        'status': 'OVERDUE',
        'carriedToDate': null,
      });

      expect(debt.title, '');
      expect(debt.fromLabel, isNull);
    });
  });
}
