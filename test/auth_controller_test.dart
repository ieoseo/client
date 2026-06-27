import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/api_exception.dart';
import 'package:ieoseo/data/api/auth_api.dart';
import 'package:ieoseo/data/api/auth_dto.dart';
import 'package:ieoseo/data/auth/auth_controller.dart';
import 'package:ieoseo/data/auth/social_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'support/fake_supabase_gateway.dart';

/// 인증은 Supabase Auth(ADR-0014): 소셜 로그인 → Supabase 세션 → server /auth/me provisioning.

Map<String, dynamic> meEnvelope({String nickname = '지우'}) => <String, dynamic>{
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

/// fake gateway + DioAdapter 로 실제 ApiClient/AuthApi 를 구동하는 컨트롤러 구성.
({AuthController controller, DioAdapter adapter, FakeSupabaseGateway gateway})
buildController({String? sessionToken, Object? oauthError}) {
  final FakeSupabaseGateway gateway = FakeSupabaseGateway(
    accessToken: sessionToken,
    oauthError: oauthError,
  );
  final Dio dio = Dio(
    BaseOptions(baseUrl: apiBaseUrl, validateStatus: (int? _) => true),
  );
  final DioAdapter adapter = DioAdapter(dio: dio);
  final ApiClient client = ApiClient(
    dio: dio,
    accessTokenReader: () async => gateway.accessToken,
    tokenRefresher: gateway.refreshAccessToken,
  );
  final AuthController controller = AuthController(
    gateway: gateway,
    api: AuthApi(client),
    client: client,
  );
  return (controller: controller, adapter: adapter, gateway: gateway);
}

void main() {
  test('초기 상태는 unknown', () {
    final c = buildController();
    expect(c.controller.status, AuthStatus.unknown);
    expect(c.controller.user, isNull);
  });

  group('oauthSignIn (ADR-0014, 웹 흐름)', () {
    test(
      'google 성공 → signInWithOAuth → onSignedIn → me → authenticated',
      () async {
        final c = buildController();
        c.adapter.onGet(
          '/auth/me',
          (server) => server.reply(200, meEnvelope()),
        );

        int notifications = 0;
        c.controller.addListener(() => notifications += 1);

        await c.controller.oauthSignIn(SocialProvider.google);
        // 딥링크 복귀(onSignedIn) 후 provisioning 이 비동기로 진행됨.
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(c.gateway.oauthCalls, <SocialProvider>[SocialProvider.google]);
        expect(c.controller.status, AuthStatus.authenticated);
        expect(c.controller.user?.nickname, '지우');
        expect(notifications, greaterThanOrEqualTo(1));
      },
    );

    test(
      'provisioning 중 isAuthenticating=true → 완료 후 false (로그인 화면 깜빡임 방지)',
      () async {
        final c = buildController();
        c.adapter.onGet(
          '/auth/me',
          (server) => server.reply(200, meEnvelope()),
        );

        final List<bool> seen = <bool>[];
        c.controller.addListener(() => seen.add(c.controller.isAuthenticating));

        await c.controller.oauthSignIn(SocialProvider.google);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(seen, contains(true)); // provisioning 동안 게이트에 로딩 신호
        expect(c.controller.isAuthenticating, isFalse); // 완료 후 해제
        expect(c.controller.status, AuthStatus.authenticated);
      },
    );

    test(
      'kakao 성공 → signInWithOAuth → onSignedIn → me → authenticated',
      () async {
        final c = buildController();
        c.adapter.onGet(
          '/auth/me',
          (server) => server.reply(200, meEnvelope()),
        );

        await c.controller.oauthSignIn(SocialProvider.kakao);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(c.gateway.oauthCalls, <SocialProvider>[SocialProvider.kakao]);
        expect(c.controller.status, AuthStatus.authenticated);
      },
    );

    test('OAuth 시작 실패 → 예외 전파, 미인증 유지', () async {
      final c = buildController(oauthError: Exception('launch fail'));

      await expectLater(
        c.controller.oauthSignIn(SocialProvider.google),
        throwsA(isA<Exception>()),
      );
      expect(c.controller.status, isNot(AuthStatus.authenticated));
    });

    test(
      '복귀 후 provisioning 이 ApiException 이 아닌 예외로 실패해도 흡수(C1, 구독 유지)',
      () async {
        // /auth/me 가 ApiException 이 아닌 예외(파싱/네트워크 raw 등)를 던지는 상황.
        // 좁은 catch 면 onSignedIn 리스너 밖으로 전파돼 구독이 끊긴다 → 광범위 흡수해야 한다.
        final FakeSupabaseGateway gateway = FakeSupabaseGateway();
        final Dio dio = Dio(
          BaseOptions(baseUrl: apiBaseUrl, validateStatus: (int? _) => true),
        );
        final ApiClient client = ApiClient(
          dio: dio,
          accessTokenReader: () async => gateway.accessToken,
          tokenRefresher: gateway.refreshAccessToken,
        );
        final AuthController controller = AuthController(
          gateway: gateway,
          api: _ThrowingMeApi(client),
          client: client,
        );

        await controller.oauthSignIn(SocialProvider.google);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // 예외가 흡수되어 미인증 유지 + provisioning 해제(게이트가 멈추지 않음).
        expect(controller.status, isNot(AuthStatus.authenticated));
        expect(controller.isAuthenticating, isFalse);
      },
    );

    test('복귀 후 server me 401 → 미인증 유지(예외는 화면이 아닌 내부에서 흡수)', () async {
      final c = buildController();
      c.adapter.onGet(
        '/auth/me',
        (server) => server.reply(401, <String, dynamic>{
          'success': false,
          'data': null,
          'error': <String, dynamic>{
            'code': 'UNAUTHORIZED',
            'message': '인증이 필요합니다',
          },
          'meta': null,
        }),
      );

      await c.controller.oauthSignIn(SocialProvider.google);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(c.controller.status, isNot(AuthStatus.authenticated));
    });
  });

  group('tryRestore', () {
    test('세션 없으면 unauthenticated', () async {
      final c = buildController();

      await c.controller.tryRestore();

      expect(c.controller.status, AuthStatus.unauthenticated);
    });

    test('세션 있으면 me 조회 후 authenticated', () async {
      final c = buildController(sessionToken: 'existing');
      c.adapter.onGet('/auth/me', (server) => server.reply(200, meEnvelope()));

      await c.controller.tryRestore();

      expect(c.controller.status, AuthStatus.authenticated);
      expect(c.controller.user?.email, 'jiwoo@daykit.app');
    });

    test('세션 있으나 me 실패 → signOut + unauthenticated', () async {
      final c = buildController(sessionToken: 'stale');
      c.adapter.onGet(
        '/auth/me',
        (server) => server.reply(401, <String, dynamic>{
          'success': false,
          'data': null,
          'error': <String, dynamic>{
            'code': 'UNAUTHORIZED',
            'message': '인증이 필요합니다',
          },
          'meta': null,
        }),
      );

      await c.controller.tryRestore();

      expect(c.controller.status, AuthStatus.unauthenticated);
      expect(c.gateway.signedOut, isTrue);
    });
  });

  test('logout → Supabase signOut + unauthenticated', () async {
    final c = buildController(sessionToken: 'x');

    await c.controller.logout();

    expect(c.controller.status, AuthStatus.unauthenticated);
    expect(c.gateway.signedOut, isTrue);
  });

  group('updateProfile / withdraw (이슈 #56)', () {
    test('updateProfile 성공 → user 닉네임 갱신', () async {
      final c = buildController();
      c.adapter.onGet('/auth/me', (server) => server.reply(200, meEnvelope()));
      await c.controller.oauthSignIn(SocialProvider.google);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      c.adapter.onPatch(
        '/auth/me',
        (server) => server.reply(200, meEnvelope(nickname: '새이름')),
        data: <String, dynamic>{'nickname': '새이름'},
      );

      await c.controller.updateProfile(nickname: '새이름');

      expect(c.controller.user?.nickname, '새이름');
      expect(c.controller.status, AuthStatus.authenticated);
    });

    test('withdraw 성공 → signOut + unauthenticated', () async {
      final c = buildController(sessionToken: 'x');
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
      expect(c.gateway.signedOut, isTrue);
    });

    test('withdraw 서버 실패 → ApiException 전파, 세션 유지', () async {
      final c = buildController(sessionToken: 'x');
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
      expect(c.gateway.signedOut, isFalse);
    });
  });

  group('연동 계정 (link/unlink, 이슈 #10)', () {
    test('linkedProviders 는 게이트웨이 값을 노출한다', () {
      final FakeSupabaseGateway gateway = FakeSupabaseGateway(
        accessToken: 'x',
        linkedProviders: <String>{'email', 'kakao'},
      );
      final AuthController controller = AuthController(gateway: gateway);
      expect(controller.linkedProviders, <String>{'email', 'kakao'});
    });

    test('linkAccount → 게이트웨이 linkOAuth 위임', () async {
      final FakeSupabaseGateway gateway = FakeSupabaseGateway(
        accessToken: 'x',
        linkedProviders: <String>{'email'},
      );
      final AuthController controller = AuthController(gateway: gateway);

      await controller.linkAccount(SocialProvider.google);

      expect(gateway.linkCalls, <SocialProvider>[SocialProvider.google]);
    });

    test('unlinkAccount → unlinkOAuth 위임 + 목록 갱신 + 알림', () async {
      final FakeSupabaseGateway gateway = FakeSupabaseGateway(
        accessToken: 'x',
        linkedProviders: <String>{'email', 'kakao'},
      );
      final AuthController controller = AuthController(gateway: gateway);
      int notified = 0;
      controller.addListener(() => notified++);

      await controller.unlinkAccount(SocialProvider.kakao);

      expect(gateway.unlinkCalls, <SocialProvider>[SocialProvider.kakao]);
      expect(controller.linkedProviders, <String>{'email'});
      expect(notified, greaterThan(0));
    });

    test('연동 추가 완료(onUserUpdated) → reloadUser + 알림', () async {
      final FakeSupabaseGateway gateway = FakeSupabaseGateway(
        accessToken: 'x',
        linkedProviders: <String>{'email'},
      );
      final AuthController controller = AuthController(gateway: gateway);
      int notified = 0;
      controller.addListener(() => notified++);

      await controller.linkAccount(SocialProvider.google);
      await Future<void>.delayed(Duration.zero); // onUserUpdated 리스너 실행 대기

      expect(gateway.reloadCalled, isTrue);
      expect(notified, greaterThan(0));
    });

    test('연동 갱신 중 reloadUser 가 실패해도 구독 유지·알림(C3)', () async {
      // reloadUser 가 던지면 좁은 흡수론 onUserUpdated 리스너 밖으로 전파돼 구독이 끊긴다.
      // 컨트롤러가 흡수하고 그래도 notifyListeners 해야 한다(UI 갱신 보장).
      final FakeSupabaseGateway gateway = FakeSupabaseGateway(
        accessToken: 'x',
        linkedProviders: <String>{'email'},
        reloadError: Exception('network down'),
      );
      final AuthController controller = AuthController(gateway: gateway);
      int notified = 0;
      controller.addListener(() => notified++);

      await controller.linkAccount(SocialProvider.google);
      await Future<void>.delayed(Duration.zero); // onUserUpdated 리스너 실행 대기

      expect(gateway.reloadCalled, isTrue);
      expect(notified, greaterThan(0)); // reloadUser 실패해도 알림은 발생
    });
  });
}

/// C1 검증용: `me()` 가 ApiException 이 아닌 예외를 던지는 [AuthApi].
class _ThrowingMeApi extends AuthApi {
  _ThrowingMeApi(super.client);

  @override
  Future<AuthUser> me() async => throw StateError('non-ApiException boom');
}
