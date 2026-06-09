import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/api_exception.dart';
import 'package:ieoseo/data/api/auth_api.dart';
import 'package:ieoseo/data/api/auth_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// 인증은 Supabase Auth(ADR-0014) — server 는 토큰 발급 엔드포인트가 없다.
/// AuthApi 는 인증된 me/updateProfile/withdraw(모두 Bearer)만 호출한다.

Map<String, dynamic> userEnvelope({String nickname = '지우'}) =>
    <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'id': 'u-1',
        'email': 'jiwoo@daykit.app',
        'nickname': nickname,
        'provider': 'GOOGLE',
      },
      'error': null,
      'meta': null,
    };

Map<String, dynamic> errEnvelope(String code, String message) =>
    <String, dynamic>{
      'success': false,
      'data': null,
      'error': <String, dynamic>{'code': code, 'message': message},
      'meta': null,
    };

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late AuthApi api;

  setUp(() {
    dio = Dio(
      BaseOptions(baseUrl: apiBaseUrl, validateStatus: (int? _) => true),
    );
    adapter = DioAdapter(dio: dio);
    api = AuthApi(ApiClient(dio: dio));
  });

  test('me 성공 → AuthUser', () async {
    adapter.onGet('/auth/me', (server) => server.reply(200, userEnvelope()));

    final AuthUser user = await api.me();

    expect(user.id, 'u-1');
    expect(user.email, 'jiwoo@daykit.app');
    expect(user.provider, 'GOOGLE');
  });

  test('me 401 → UNAUTHORIZED ApiException', () async {
    adapter.onGet(
      '/auth/me',
      (server) => server.reply(401, errEnvelope('UNAUTHORIZED', '인증이 필요합니다')),
    );

    expect(
      () => api.me(),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.code,
          'code',
          'UNAUTHORIZED',
        ),
      ),
    );
  });

  test('updateProfile 성공 → 갱신된 AuthUser', () async {
    adapter.onPatch(
      '/auth/me',
      (server) => server.reply(200, userEnvelope(nickname: '새이름')),
      data: <String, dynamic>{'nickname': '새이름'},
    );

    final AuthUser user = await api.updateProfile(nickname: '새이름');

    expect(user.nickname, '새이름');
  });

  test('withdraw 성공 → 204(예외 없음)', () async {
    adapter.onDelete(
      '/auth/me',
      (server) => server.reply(204, <String, dynamic>{
        'success': true,
        'data': null,
        'error': null,
        'meta': null,
      }),
    );

    await expectLater(api.withdraw(), completes);
  });

  test('네트워크 오류 → network ApiException', () async {
    adapter.onGet(
      '/auth/me',
      (server) => server.throws(
        -1,
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/auth/me'),
          reason: 'down',
        ),
      ),
    );

    expect(
      () => api.me(),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.kind,
          'kind',
          ApiErrorKind.network,
        ),
      ),
    );
  });
}
