import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/api_exception.dart';
import 'package:ieoseo/data/api/api_repository.dart';
import 'package:ieoseo/data/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// ApiRepository 테스트(이슈 #35). DioAdapter 가짜 HTTP 로 각 메서드 검증.
Map<String, dynamic> ok(Object? data, {Object? meta}) => <String, dynamic>{
  'success': true,
  'data': data,
  'error': null,
  'meta': meta,
};

Map<String, dynamic> fail(String code, String message) => <String, dynamic>{
  'success': false,
  'data': null,
  'error': <String, dynamic>{'code': code, 'message': message},
  'meta': null,
};

({Dio dio, DioAdapter adapter, ApiRepository repo}) harness() {
  final Dio dio = Dio(
    BaseOptions(baseUrl: apiBaseUrl, validateStatus: (int? _) => true),
  );
  final DioAdapter adapter = DioAdapter(dio: dio);
  final ApiRepository repo = ApiRepository(ApiClient(dio: dio));
  return (dio: dio, adapter: adapter, repo: repo);
}

Map<String, dynamic> eventJson(String id) => <String, dynamic>{
  'id': id,
  'type': 'T1_DDAY',
  'title': '정처기',
  'category': '자격증',
  'date': '2026-08-02',
  'startDate': null,
  'endDate': null,
  'pinned': true,
  'memo': 'm',
  'color': '#fff',
  'createdAt': '2026-06-04T09:00:00Z',
  'updatedAt': '2026-06-04T09:00:00Z',
};

Map<String, dynamic> taskJson(String id, {String state = 'TODAY'}) =>
    <String, dynamic>{
      'id': id,
      'title': '할 일',
      'estimatedMinutes': 60,
      'date': '2026-06-04',
      'state': state,
      'category': '공부',
      'eventId': null,
      'fromDate': null,
      'actualMinutes': null,
    };

void main() {
  group('events', () {
    test('list: 배열 data를 DkEvent 목록으로 파싱한다', () async {
      final h = harness();
      h.adapter.onGet(
        '/events',
        (s) => s.reply(200, ok(<dynamic>[eventJson('e-1')])),
      );

      final List<DkEvent> events = await h.repo.events();

      expect(events, hasLength(1));
      expect(events.single.id, 'e-1');
      expect(events.single.type, DkEventType.single);
    });

    test('createEvent: 생성 본문을 보내고 201 응답을 파싱한다', () async {
      final h = harness();
      h.adapter.onPost(
        '/events',
        (s) => s.reply(201, ok(eventJson('e-new'))),
        data: Matchers.any,
      );

      final DkEvent created = await h.repo.createEvent(
        const DkEvent(
          id: '',
          type: DkEventType.single,
          title: '정처기',
          category: '자격증',
          date: '2026-08-02',
        ),
      );

      expect(created.id, 'e-new');
    });

    test('deleteEvent: 204를 정상 처리한다', () async {
      final h = harness();
      h.adapter.onDelete('/events/e-1', (s) => s.reply(204, null));

      await expectLater(h.repo.deleteEvent('e-1'), completes);
    });
  });

  group('tasks', () {
    test('list: date 필터를 쿼리로 전달한다', () async {
      final h = harness();
      h.adapter.onGet(
        '/tasks',
        (s) => s.reply(200, ok(<dynamic>[taskJson('t-1')])),
        queryParameters: <String, dynamic>{'date': '2026-06-04'},
      );

      final List<DkTask> tasks = await h.repo.tasks(date: '2026-06-04');

      expect(tasks.single.id, 't-1');
    });

    test('completeTask: complete 응답의 DONE 상태를 파싱한다', () async {
      final h = harness();
      h.adapter.onPost(
        '/tasks/t-1/complete',
        (s) => s.reply(200, ok(taskJson('t-1', state: 'DONE'))),
        data: Matchers.any,
      );

      final DkTask done = await h.repo.completeTask('t-1', actualMinutes: 75);

      expect(done.state, DkTaskState.done);
    });

    test('reopenTask: reopen 응답의 TODAY 상태를 파싱한다(완료 취소)', () async {
      final h = harness();
      h.adapter.onPost(
        '/tasks/t-1/reopen',
        (s) => s.reply(200, ok(taskJson('t-1', state: 'TODAY'))),
        data: Matchers.any,
      );

      final DkTask reopened = await h.repo.reopenTask('t-1');

      expect(reopened.state, DkTaskState.today);
    });

    test('carryTask: carry 응답의 CARRIED 상태를 파싱한다', () async {
      final h = harness();
      h.adapter.onPost(
        '/tasks/t-1/carry',
        (s) => s.reply(200, ok(taskJson('t-1', state: 'CARRIED'))),
        data: Matchers.any,
      );

      final DkTask carried = await h.repo.carryTask(
        't-1',
        toDate: '2026-06-07',
      );

      expect(carried.state, DkTaskState.carried);
    });

    test('createTask 401 → ApiException(401)', () async {
      final h = harness();
      h.adapter.onPost(
        '/tasks',
        (s) => s.reply(401, fail('UNAUTHORIZED', '로그인이 필요해요.')),
        data: Matchers.any,
      );

      await expectLater(
        h.repo.createTask(
          const DkTask(
            id: '',
            title: 'x',
            mins: 30,
            date: '2026-06-04',
            state: DkTaskState.pending,
            category: '공부',
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.statusCode,
            'status',
            401,
          ),
        ),
      );
    });
  });

  group('debts', () {
    test('list: status 필터를 server 코드로 전달한다(assigned→CARRIED)', () async {
      final h = harness();
      h.adapter.onGet(
        '/debts',
        (s) => s.reply(
          200,
          ok(<dynamic>[
            <String, dynamic>{
              'id': 'd-1',
              'taskId': 't-5',
              'minutes': 60,
              'originDate': '2026-06-01',
              'status': 'CARRIED',
              'carriedToDate': '2026-06-07',
            },
          ]),
        ),
        queryParameters: <String, dynamic>{'status': 'CARRIED'},
      );

      final List<DkDebt> debts = await h.repo.debts(
        status: DkDebtStatus.assigned,
      );

      expect(debts.single.status, DkDebtStatus.assigned);
      expect(debts.single.assignedTo, '2026-06-07');
    });

    test('list: 제목과 출처 라벨을 매핑한다', () async {
      final h = harness();
      h.adapter.onGet(
        '/debts',
        (s) => s.reply(
          200,
          ok(<dynamic>[
            <String, dynamic>{
              'id': 'd-9',
              'taskId': 't-5',
              'title': '알고리즘 2문제 풀기',
              'fromLabel': '월요일',
              'minutes': 60,
              'originDate': '2026-06-01',
              'status': 'PENDING',
              'carriedToDate': null,
            },
          ]),
        ),
      );

      final List<DkDebt> debts = await h.repo.debts();

      expect(debts.single.title, '알고리즘 2문제 풀기');
      expect(debts.single.fromLabel, '월요일');
    });

    test('autoCarryDebt: 자동 이월 CARRIED 응답을 파싱한다', () async {
      final h = harness();
      h.adapter.onPost(
        '/debts/d-1/auto-carry',
        (s) => s.reply(
          200,
          ok(<String, dynamic>{
            'id': 'd-1',
            'taskId': 't-5',
            'title': '알고리즘 2문제 풀기',
            'fromLabel': '월요일',
            'minutes': 60,
            'originDate': '2026-06-01',
            'status': 'CARRIED',
            'carriedToDate': '2026-06-04',
          }),
        ),
        data: Matchers.any,
      );

      final DkDebt debt = await h.repo.autoCarryDebt('d-1');

      expect(debt.status, DkDebtStatus.assigned);
      expect(debt.assignedTo, '2026-06-04');
      expect(debt.title, '알고리즘 2문제 풀기');
    });

    test('abandonDebt: ABANDONED 응답을 파싱한다', () async {
      final h = harness();
      h.adapter.onPost(
        '/debts/d-1/abandon',
        (s) => s.reply(
          200,
          ok(<String, dynamic>{
            'id': 'd-1',
            'taskId': 't-5',
            'minutes': 60,
            'originDate': '2026-06-01',
            'status': 'ABANDONED',
            'carriedToDate': null,
          }),
        ),
        data: Matchers.any,
      );

      final DkDebt debt = await h.repo.abandonDebt('d-1');

      expect(debt.status, DkDebtStatus.abandoned);
    });
  });

  group('운영 미지원 읽기는 목 상수 대신 차단된다(F12)', () {
    test('weekSummary/focusStats/pomodoro/streak 직접 호출은 UnsupportedError', () {
      final ({Dio dio, DioAdapter adapter, ApiRepository repo}) h = harness();

      // 운영 화면은 실데이터에서 파생하거나 0 으로 둔다 — 조작 상수 반환 금지.
      expect(() => h.repo.weekSummary(), throwsUnsupportedError);
      expect(() => h.repo.focusStats(), throwsUnsupportedError);
      expect(() => h.repo.pomodoro(), throwsUnsupportedError);
      expect(() => h.repo.streak(), throwsUnsupportedError);
    });
  });
}
