import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/api_exception.dart';
import 'package:ieoseo/data/api/auth_api.dart';
import 'package:ieoseo/data/api/auth_dto.dart';
import 'package:ieoseo/data/auth/social_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

Map<String, dynamic> sessionEnvelope() => <String, dynamic>{
  'success': true,
  'data': <String, dynamic>{
    'user': <String, dynamic>{
      'id': 'u-1',
      'email': 'jiwoo@daykit.app',
      'nickname': '지우',
      'provider': 'LOCAL',
    },
    'tokens': <String, dynamic>{
      'accessToken': 'acc-1',
      'refreshToken': 'ref-1',
      'tokenType': 'Bearer',
      'expiresIn': 1800,
    },
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

  test('signup 성공 → AuthSession 파싱', () async {
    adapter.onPost(
      '/auth/signup',
      (server) => server.reply(201, sessionEnvelope()),
      data: <String, dynamic>{
        'email': 'jiwoo@daykit.app',
        'password': 'pw123456',
        'nickname': '지우',
      },
    );

    final AuthSession session = await api.signup(
      email: 'jiwoo@daykit.app',
      password: 'pw123456',
      nickname: '지우',
    );

    expect(session.user.email, 'jiwoo@daykit.app');
    expect(session.user.nickname, '지우');
    expect(session.tokens.accessToken, 'acc-1');
    expect(session.tokens.refreshToken, 'ref-1');
    expect(session.tokens.expiresIn, 1800);
  });

  test('signup 409 → EMAIL_TAKEN ApiException', () async {
    adapter.onPost(
      '/auth/signup',
      (server) =>
          server.reply(409, errEnvelope('EMAIL_TAKEN', '이미 가입된 이메일이에요.')),
      data: <String, dynamic>{
        'email': 'dup@daykit.app',
        'password': 'pw123456',
        'nickname': '중복',
      },
    );

    expect(
      () => api.signup(
        email: 'dup@daykit.app',
        password: 'pw123456',
        nickname: '중복',
      ),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.code,
          'code',
          'EMAIL_TAKEN',
        ),
      ),
    );
  });

  test('login 성공 → AuthSession 파싱', () async {
    adapter.onPost(
      '/auth/login',
      (server) => server.reply(200, sessionEnvelope()),
      data: <String, dynamic>{
        'email': 'jiwoo@daykit.app',
        'password': 'pw123456',
      },
    );

    final AuthSession session = await api.login(
      email: 'jiwoo@daykit.app',
      password: 'pw123456',
    );

    expect(session.user.id, 'u-1');
    expect(session.tokens.accessToken, 'acc-1');
  });

  test('login 401 → INVALID_CREDENTIALS ApiException', () async {
    adapter.onPost(
      '/auth/login',
      (server) => server.reply(
        401,
        errEnvelope('INVALID_CREDENTIALS', '이메일 또는 비밀번호가 올바르지 않아요.'),
      ),
      data: <String, dynamic>{'email': 'jiwoo@daykit.app', 'password': 'wrong'},
    );

    expect(
      () => api.login(email: 'jiwoo@daykit.app', password: 'wrong'),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.code,
          'code',
          'INVALID_CREDENTIALS',
        ),
      ),
    );
  });

  test('refresh 성공 → 새 AuthTokens', () async {
    adapter.onPost(
      '/auth/refresh',
      (server) => server.reply(200, <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'accessToken': 'acc-2',
          'refreshToken': 'ref-2',
          'tokenType': 'Bearer',
          'expiresIn': 1800,
        },
        'error': null,
        'meta': null,
      }),
      data: <String, dynamic>{'refreshToken': 'ref-1'},
    );

    final AuthTokens tokens = await api.refresh('ref-1');

    expect(tokens.accessToken, 'acc-2');
    expect(tokens.refreshToken, 'ref-2');
  });

  test('me 성공 → AuthUser', () async {
    adapter.onGet(
      '/auth/me',
      (server) => server.reply(200, <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'id': 'u-1',
          'email': 'jiwoo@daykit.app',
          'nickname': '지우',
          'provider': 'LOCAL',
        },
        'error': null,
        'meta': null,
      }),
    );

    final AuthUser user = await api.me();

    expect(user.id, 'u-1');
    expect(user.email, 'jiwoo@daykit.app');
  });

  test('oauth google 성공 → idToken 본문 + AuthSession', () async {
    adapter.onPost(
      '/auth/oauth/google',
      (server) => server.reply(200, sessionEnvelope()),
      data: <String, dynamic>{'idToken': 'g-id'},
    );

    final AuthSession session = await api.oauth(
      provider: 'google',
      token: const SocialToken(provider: SocialProvider.google, value: 'g-id'),
    );

    expect(session.user.email, 'jiwoo@daykit.app');
    expect(session.tokens.accessToken, 'acc-1');
  });

  test('oauth kakao 성공 → accessToken 본문', () async {
    adapter.onPost(
      '/auth/oauth/kakao',
      (server) => server.reply(200, sessionEnvelope()),
      data: <String, dynamic>{'accessToken': 'k-acc'},
    );

    final AuthSession session = await api.oauth(
      provider: 'kakao',
      token: const SocialToken(provider: SocialProvider.kakao, value: 'k-acc'),
    );

    expect(session.tokens.refreshToken, 'ref-1');
  });

  test('oauth 401 → OAUTH_INVALID ApiException', () async {
    adapter.onPost(
      '/auth/oauth/google',
      (server) =>
          server.reply(401, errEnvelope('OAUTH_INVALID', '소셜 로그인에 실패했어요.')),
      data: <String, dynamic>{'idToken': 'bad'},
    );

    expect(
      () => api.oauth(
        provider: 'google',
        token: const SocialToken(provider: SocialProvider.google, value: 'bad'),
      ),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.code,
          'code',
          'OAUTH_INVALID',
        ),
      ),
    );
  });

  test('네트워크 오류 → network ApiException', () async {
    adapter.onPost(
      '/auth/login',
      (server) => server.throws(
        -1,

        DioException.connectionError(
          requestOptions: RequestOptions(path: '/auth/login'),
          reason: 'down',
        ),
      ),
      data: <String, dynamic>{'email': 'a@b.com', 'password': 'pw123456'},
    );

    expect(
      () => api.login(email: 'a@b.com', password: 'pw123456'),
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
