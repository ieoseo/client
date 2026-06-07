import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/api_exception.dart';
import 'package:ieoseo/data/api/notif_api.dart';
import 'package:ieoseo/data/api/notif_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// NotifApi 테스트(이슈 #46). DioAdapter 가짜 HTTP 로 목록/읽음/전체읽음 검증.
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

({Dio dio, DioAdapter adapter, NotifApi api}) harness() {
  final Dio dio = Dio(
    BaseOptions(baseUrl: apiBaseUrl, validateStatus: (int? _) => true),
  );
  final DioAdapter adapter = DioAdapter(dio: dio);
  final NotifApi api = NotifApi(ApiClient(dio: dio));
  return (dio: dio, adapter: adapter, api: api);
}

Map<String, dynamic> notifJson(
  String id, {
  String type = 'DDAY',
  bool read = false,
}) => <String, dynamic>{
  'id': id,
  'type': type,
  'title': '토익 시험',
  'body': '토익 시험이 3일 남았어요',
  'refId': null,
  'read': read,
  'createdAt': '2026-06-04T09:00:00Z',
};

void main() {
  group('list', () {
    test('items 배열과 unreadCount 를 파싱한다', () async {
      final h = harness();
      h.adapter.onGet(
        '/notifications',
        (s) => s.reply(
          200,
          ok(<String, dynamic>{
            'items': <dynamic>[
              notifJson('n-1'),
              notifJson('n-2', type: 'STREAK', read: true),
            ],
            'unreadCount': 1,
          }),
        ),
      );

      final NotifListResult result = await h.api.list();

      expect(result.items, hasLength(2));
      expect(result.items.first.id, 'n-1');
      expect(result.items.first.type, DkNotifType.dday);
      expect(result.items.first.read, isFalse);
      expect(result.items[1].type, DkNotifType.streak);
      expect(result.unreadCount, 1);
    });

    test('알 수 없는 type 은 안전 기본값으로 떨어진다', () async {
      final h = harness();
      h.adapter.onGet(
        '/notifications',
        (s) => s.reply(
          200,
          ok(<String, dynamic>{
            'items': <dynamic>[notifJson('n-9', type: 'WHATEVER')],
            'unreadCount': 0,
          }),
        ),
      );

      final NotifListResult result = await h.api.list();

      expect(result.items.single.type, DkNotifType.dday);
    });

    test('401 → ApiException(401)', () async {
      final h = harness();
      h.adapter.onGet(
        '/notifications',
        (s) => s.reply(401, fail('UNAUTHORIZED', '로그인이 필요해요.')),
      );

      await expectLater(
        h.api.list(),
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

  group('markRead', () {
    test('PATCH 로 단건 읽음 처리하고 read=true 를 파싱한다', () async {
      final h = harness();
      h.adapter.onPatch(
        '/notifications/n-1/read',
        (s) => s.reply(200, ok(notifJson('n-1', read: true))),
        data: Matchers.any,
      );

      final DkNotif updated = await h.api.markRead('n-1');

      expect(updated.read, isTrue);
    });
  });

  group('markAllRead', () {
    test('POST read-all 의 updated 건수를 반환한다', () async {
      final h = harness();
      h.adapter.onPost(
        '/notifications/read-all',
        (s) => s.reply(200, ok(<String, dynamic>{'updated': 3})),
        data: Matchers.any,
      );

      final int updated = await h.api.markAllRead();

      expect(updated, 3);
    });
  });
}
