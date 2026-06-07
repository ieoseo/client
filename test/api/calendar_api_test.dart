import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/api_exception.dart';
import 'package:ieoseo/data/api/calendar_api.dart';
import 'package:ieoseo/data/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// CalendarApi 테스트(이슈 #59). DioAdapter 가짜 HTTP 로 server /calendar/* 매핑을 검증한다.
/// 외부 호출 없이 envelope·provider/상태 매핑·읽기전용 외부 일정·토큰 비노출을 확인한다.
Map<String, dynamic> ok(Object? data) => <String, dynamic>{
  'success': true,
  'data': data,
  'error': null,
  'meta': null,
};

Map<String, dynamic> fail(String code, String message) => <String, dynamic>{
  'success': false,
  'data': null,
  'error': <String, dynamic>{'code': code, 'message': message},
  'meta': null,
};

({DioAdapter adapter, CalendarApi api}) harness() {
  final Dio dio = Dio(
    BaseOptions(baseUrl: apiBaseUrl, validateStatus: (int? _) => true),
  );
  final DioAdapter adapter = DioAdapter(dio: dio);
  final CalendarApi api = CalendarApi(ApiClient(dio: dio));
  return (adapter: adapter, api: api);
}

void main() {
  group('CalendarApi', () {
    test('connections: provider/상태를 매핑하고 토큰은 다루지 않는다', () async {
      final h = harness();
      h.adapter.onGet(
        '/calendar/connections',
        (s) => s.reply(
          200,
          ok(<dynamic>[
            <String, dynamic>{
              'provider': 'GOOGLE',
              'status': 'CONNECTED',
              'lastSyncedAt': '2026-06-04T09:00:00Z',
            },
            <String, dynamic>{
              'provider': 'NOTION',
              'status': 'SYNC_FAILED',
              'lastSyncedAt': null,
            },
          ]),
        ),
      );

      final List<DkCalendarConnection> conns = await h.api.connections();

      expect(conns, hasLength(2));
      expect(conns[0].source, DkSource.google);
      expect(conns[0].status, DkConnectionStatus.connected);
      expect(conns[0].lastSyncedAt, '2026-06-04T09:00:00Z');
      expect(conns[1].source, DkSource.notion);
      expect(conns[1].status, DkConnectionStatus.syncFailed);
    });

    test('connect: provider 경로(소문자)로 POST 하고 결과를 매핑한다', () async {
      final h = harness();
      h.adapter.onPost(
        '/calendar/connections/google',
        (s) => s.reply(
          200,
          ok(<String, dynamic>{
            'provider': 'GOOGLE',
            'status': 'CONNECTED',
            'lastSyncedAt': null,
          }),
        ),
        data: Matchers.any,
      );

      final DkCalendarConnection conn = await h.api.connect(
        DkSource.google,
        accessToken: 'token-placeholder',
      );

      expect(conn.source, DkSource.google);
      expect(conn.status, DkConnectionStatus.connected);
    });

    test('disconnect: 204를 정상 처리한다', () async {
      final h = harness();
      h.adapter.onDelete(
        '/calendar/connections/notion',
        (s) => s.reply(204, null),
      );

      await expectLater(h.api.disconnect(DkSource.notion), completes);
    });

    test('sync: 결과의 syncedAt 을 연결 모델로 환원한다', () async {
      final h = harness();
      h.adapter.onPost(
        '/calendar/sync',
        (s) => s.reply(
          200,
          ok(<dynamic>[
            <String, dynamic>{
              'provider': 'GOOGLE',
              'imported': 3,
              'status': 'CONNECTED',
              'syncedAt': '2026-06-05T10:00:00Z',
            },
          ]),
        ),
        data: Matchers.any,
      );

      final List<DkCalendarConnection> conns = await h.api.sync();

      expect(conns.single.source, DkSource.google);
      expect(conns.single.lastSyncedAt, '2026-06-05T10:00:00Z');
    });

    test('external: from/to 쿼리로 읽기전용 외부 일정을 매핑한다', () async {
      final h = harness();
      h.adapter.onGet(
        '/calendar/external',
        (s) => s.reply(
          200,
          ok(<dynamic>[
            <String, dynamic>{
              'id': 'x1',
              'provider': 'GOOGLE',
              'externalId': 'g1',
              'title': '회의',
              'date': '2026-06-04',
              'time': '14:30',
              'readOnly': true,
            },
            <String, dynamic>{
              'id': 'x2',
              'provider': 'NOTION',
              'externalId': 'n1',
              'title': '종일 일정',
              'date': '2026-06-05',
              'time': null,
              'readOnly': true,
            },
          ]),
        ),
        queryParameters: <String, dynamic>{
          'from': '2026-06-01',
          'to': '2026-06-30',
        },
      );

      final List<DkExternal> events = await h.api.external(
        from: '2026-06-01',
        to: '2026-06-30',
      );

      expect(events, hasLength(2));
      expect(events[0].source, DkSource.google);
      expect(events[0].time, '14:30');
      expect(events[1].source, DkSource.notion);
      expect(events[1].time, ''); // 종일 → 빈 문자열(DkExternal.time 비널)
    });

    test('connections 401 → ApiException(401)', () async {
      final h = harness();
      h.adapter.onGet(
        '/calendar/connections',
        (s) => s.reply(401, fail('UNAUTHORIZED', '로그인이 필요해요.')),
      );

      await expectLater(
        h.api.connections(),
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
}
