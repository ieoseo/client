import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/api_exception.dart';
import 'package:ieoseo/data/api/auth_api.dart';
import 'package:ieoseo/data/auth/auth_controller.dart';
import 'package:ieoseo/data/auth/social_auth.dart';
import 'package:ieoseo/data/auth/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'support/fake_secure_storage.dart';
import 'support/fake_social_token_provider.dart';

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

Map<String, dynamic> meEnvelope() => <String, dynamic>{
  'success': true,
  'data': <String, dynamic>{
    'id': 'u-1',
    'email': 'jiwoo@daykit.app',
    'nickname': '지우',
    'provider': 'LOCAL',
  },
  'error': null,
  'meta': null,
};

/// fake storage + DioAdapter로 실제 ApiClient/AuthApi를 구동하는 컨트롤러 구성.
({AuthController controller, DioAdapter adapter, FakeSecureStorage fake})
buildController({SocialTokenProvider? social}) {
  final FakeSecureStorage fake = FakeSecureStorage();
  final TokenStorage storage = TokenStorage(storage: fake);
  final Dio dio = Dio(
    BaseOptions(baseUrl: apiBaseUrl, validateStatus: (int? _) => true),
  );
  final DioAdapter adapter = DioAdapter(dio: dio);
  final ApiClient client = ApiClient(
    dio: dio,
    accessTokenReader: storage.readAccess,
    tokenRefresher: () async => storage.readRefresh(),
  );
  final AuthController controller = AuthController(
    storage: storage,
    api: AuthApi(client),
    client: client,
    social: social,
  );
  return (controller: controller, adapter: adapter, fake: fake);
}

void main() {
  test('초기 상태는 unknown', () {
    final c = buildController();
    expect(c.controller.status, AuthStatus.unknown);
    expect(c.controller.user, isNull);
  });

  test('login 성공 → 토큰 저장 + authenticated 전환', () async {
    final c = buildController();
    c.adapter.onPost(
      '/auth/login',
      (server) => server.reply(200, sessionEnvelope()),
      data: <String, dynamic>{
        'email': 'jiwoo@daykit.app',
        'password': 'pw123456',
      },
    );

    int notifications = 0;
    c.controller.addListener(() => notifications += 1);

    await c.controller.login(email: 'jiwoo@daykit.app', password: 'pw123456');

    expect(c.controller.status, AuthStatus.authenticated);
    expect(c.controller.user?.nickname, '지우');
    expect(c.fake.snapshot[kAccessTokenKey], 'acc-1');
    expect(c.fake.snapshot[kRefreshTokenKey], 'ref-1');
    expect(notifications, greaterThanOrEqualTo(1));
  });

  test('signup 성공 → 토큰 저장 + authenticated 전환', () async {
    final c = buildController();
    c.adapter.onPost(
      '/auth/signup',
      (server) => server.reply(201, sessionEnvelope()),
      data: <String, dynamic>{
        'email': 'jiwoo@daykit.app',
        'password': 'pw123456',
        'nickname': '지우',
      },
    );

    await c.controller.signup(
      email: 'jiwoo@daykit.app',
      password: 'pw123456',
      nickname: '지우',
    );

    expect(c.controller.isAuthenticated, isTrue);
    expect(c.fake.snapshot[kAccessTokenKey], 'acc-1');
  });

  test('logout → 토큰 삭제 + unauthenticated 전환', () async {
    final c = buildController();
    await c.fake.write(key: kAccessTokenKey, value: 'acc-1');
    await c.fake.write(key: kRefreshTokenKey, value: 'ref-1');
    c.adapter.onPost(
      '/auth/logout',
      (server) => server.reply(204, <String, dynamic>{
        'success': true,
        'data': null,
        'error': null,
        'meta': null,
      }),
      data: <String, dynamic>{'refreshToken': 'ref-1'},
    );

    await c.controller.logout();

    expect(c.controller.status, AuthStatus.unauthenticated);
    expect(c.fake.snapshot.containsKey(kAccessTokenKey), isFalse);
    expect(c.fake.snapshot.containsKey(kRefreshTokenKey), isFalse);
  });

  test('tryRestore: 저장 토큰 없으면 unauthenticated', () async {
    final c = buildController();

    await c.controller.tryRestore();

    expect(c.controller.status, AuthStatus.unauthenticated);
  });

  test('tryRestore: 유효 토큰이면 me 조회 후 authenticated', () async {
    final c = buildController();
    await c.fake.write(key: kAccessTokenKey, value: 'acc-1');
    await c.fake.write(key: kRefreshTokenKey, value: 'ref-1');
    c.adapter.onGet('/auth/me', (server) => server.reply(200, meEnvelope()));

    await c.controller.tryRestore();

    expect(c.controller.status, AuthStatus.authenticated);
    expect(c.controller.user?.email, 'jiwoo@daykit.app');
  });

  group('updateProfile / withdraw (이슈 #56)', () {
    test('updateProfile 성공 → user 닉네임 갱신', () async {
      final c = buildController();
      // 인증 상태로 만든 뒤 프로필 수정.
      c.adapter.onPost(
        '/auth/login',
        (server) => server.reply(200, sessionEnvelope()),
        data: <String, dynamic>{
          'email': 'jiwoo@daykit.app',
          'password': 'pw123456',
        },
      );
      await c.controller.login(email: 'jiwoo@daykit.app', password: 'pw123456');

      c.adapter.onPatch(
        '/auth/me',
        (server) => server.reply(200, <String, dynamic>{
          'success': true,
          'data': <String, dynamic>{
            'id': 'u-1',
            'email': 'jiwoo@daykit.app',
            'nickname': '새이름',
            'provider': 'LOCAL',
          },
          'error': null,
          'meta': null,
        }),
        data: <String, dynamic>{'nickname': '새이름'},
      );

      await c.controller.updateProfile(nickname: '새이름');

      expect(c.controller.user?.nickname, '새이름');
      expect(c.controller.status, AuthStatus.authenticated);
    });

    test('withdraw 성공 → 토큰 삭제 + unauthenticated 전환', () async {
      final c = buildController();
      await c.fake.write(key: kAccessTokenKey, value: 'acc-1');
      await c.fake.write(key: kRefreshTokenKey, value: 'ref-1');
      c.adapter.onDelete(
        '/auth/me',
        (server) => server.reply(204, <String, dynamic>{
          'success': true,
          'data': null,
          'error': null,
          'meta': null,
        }),
      );

      await c.controller.withdraw();

      expect(c.controller.status, AuthStatus.unauthenticated);
      expect(c.fake.snapshot.containsKey(kAccessTokenKey), isFalse);
      expect(c.fake.snapshot.containsKey(kRefreshTokenKey), isFalse);
    });

    test('withdraw 서버 실패 → ApiException 전파, 세션 유지', () async {
      final c = buildController();
      await c.fake.write(key: kAccessTokenKey, value: 'acc-1');
      await c.fake.write(key: kRefreshTokenKey, value: 'ref-1');
      c.adapter.onDelete(
        '/auth/me',
        (server) => server.reply(500, <String, dynamic>{
          'success': false,
          'data': null,
          'error': <String, dynamic>{
            'code': 'INTERNAL_ERROR',
            'message': '서버 오류',
          },
          'meta': null,
        }),
      );

      await expectLater(c.controller.withdraw(), throwsA(isA<ApiException>()));
      // 실패 시 로컬 토큰은 남아 재시도 가능.
      expect(c.fake.snapshot[kAccessTokenKey], 'acc-1');
    });
  });

  group('oauthSignIn (이슈 #38)', () {
    test('google 성공 → idToken 교환 → 세션 저장 + authenticated', () async {
      final fake = FakeSocialTokenProvider(token: 'g-id');
      final c = buildController(social: fake);
      c.adapter.onPost(
        '/auth/oauth/google',
        (server) => server.reply(200, sessionEnvelope()),
        data: <String, dynamic>{'idToken': 'g-id'},
      );

      await c.controller.oauthSignIn(SocialProvider.google);

      expect(fake.calls, <SocialProvider>[SocialProvider.google]);
      expect(c.controller.status, AuthStatus.authenticated);
      expect(c.fake.snapshot[kAccessTokenKey], 'acc-1');
      expect(c.fake.snapshot[kRefreshTokenKey], 'ref-1');
    });

    test('kakao 성공 → accessToken 으로 교환', () async {
      final fake = FakeSocialTokenProvider(token: 'k-acc');
      final c = buildController(social: fake);
      c.adapter.onPost(
        '/auth/oauth/kakao',
        (server) => server.reply(200, sessionEnvelope()),
        data: <String, dynamic>{'accessToken': 'k-acc'},
      );

      await c.controller.oauthSignIn(SocialProvider.kakao);

      expect(c.controller.isAuthenticated, isTrue);
    });

    test('사용자 취소 → SocialSignInCancelled 전파, 미인증 유지', () async {
      final fake = FakeSocialTokenProvider(cancel: true);
      final c = buildController(social: fake);

      await expectLater(
        c.controller.oauthSignIn(SocialProvider.google),
        throwsA(isA<SocialSignInCancelled>()),
      );
      expect(c.controller.status, isNot(AuthStatus.authenticated));
    });

    test('서버 401 OAUTH_INVALID → ApiException 전파, 미인증 유지', () async {
      final fake = FakeSocialTokenProvider(token: 'g-id');
      final c = buildController(social: fake);
      c.adapter.onPost(
        '/auth/oauth/google',
        (server) => server.reply(401, <String, dynamic>{
          'success': false,
          'data': null,
          'error': <String, dynamic>{
            'code': 'OAUTH_INVALID',
            'message': '소셜 로그인에 실패했어요.',
          },
          'meta': null,
        }),
        data: <String, dynamic>{'idToken': 'g-id'},
      );

      await expectLater(
        c.controller.oauthSignIn(SocialProvider.google),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'OAUTH_INVALID'),
        ),
      );
      expect(c.controller.status, isNot(AuthStatus.authenticated));
    });

    test('social 미주입 → StateError', () async {
      final c = buildController();

      await expectLater(
        c.controller.oauthSignIn(SocialProvider.google),
        throwsA(isA<StateError>()),
      );
    });
  });
}
