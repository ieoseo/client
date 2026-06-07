import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/auth_api.dart';
import 'package:ieoseo/data/auth/auth_controller.dart';
import 'package:ieoseo/data/auth/social_auth.dart';
import 'package:ieoseo/data/auth/token_storage.dart';
import 'package:ieoseo/screens/login.dart';
import 'package:ieoseo/widgets/dk_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'support/fake_secure_storage.dart';
import 'support/fake_social_token_provider.dart';
import 'support/harness.dart';

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

({AuthController controller, DioAdapter adapter, FakeSecureStorage fake})
buildAuth({SocialTokenProvider? social}) {
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

/// 키로 식별한 입력 필드(DkTextInput)의 EditableText에 텍스트 입력.
Finder _fieldByKey(String key) => find.descendant(
  of: find.byKey(ValueKey<String>(key)),
  matching: find.byType(EditableText),
);

Future<void> _typeSignup(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await tester.enterText(_fieldByKey('login-nickname'), '지우');
  await tester.enterText(_fieldByKey('login-email'), email);
  await tester.enterText(_fieldByKey('login-password'), password);
}

void main() {
  testWidgets('회원가입 제출 성공 → authenticated 전환', (WidgetTester tester) async {
    final auth = buildAuth();
    auth.adapter.onPost(
      '/auth/signup',
      (server) => server.reply(201, sessionEnvelope()),
      data: <String, dynamic>{
        'email': 'jiwoo@daykit.app',
        'password': 'pw123456',
        'nickname': '지우',
      },
    );

    await tester.pumpWidget(
      wrapForTest(LoginScreen(auth: auth.controller, onLogin: () {})),
    );
    await _typeSignup(tester, email: 'jiwoo@daykit.app', password: 'pw123456');

    await tester.tap(find.text('가입하기'));
    await tester.pump(); // 로딩 시작
    await tester.pumpAndSettle();

    expect(auth.controller.status, AuthStatus.authenticated);
    expect(auth.fake.snapshot[kAccessTokenKey], 'acc-1');
  });

  testWidgets('로그인 401 → 오류 메시지 표시, 미인증 유지', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = buildAuth();
    auth.adapter.onPost(
      '/auth/login',
      (server) => server.reply(401, <String, dynamic>{
        'success': false,
        'data': null,
        'error': <String, dynamic>{
          'code': 'INVALID_CREDENTIALS',
          'message': '이메일 또는 비밀번호가 올바르지 않아요.',
        },
        'meta': null,
      }),
      data: <String, dynamic>{
        'email': 'jiwoo@daykit.app',
        'password': 'wrongpass',
      },
    );

    await tester.pumpWidget(
      wrapForTest(LoginScreen(auth: auth.controller, onLogin: () {})),
    );

    // 로그인 모드로 전환.
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    await tester.enterText(_fieldByKey('login-email'), 'jiwoo@daykit.app');
    await tester.enterText(_fieldByKey('login-password'), 'wrongpass');
    await tester.pump();

    // 로그인 버튼(모드 전환 링크는 이제 "회원가입").
    await tester.tap(find.widgetWithText(DkButton, '로그인'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('이메일 또는 비밀번호가 올바르지 않아요.'), findsOneWidget);
    expect(auth.controller.status, isNot(AuthStatus.authenticated));
  });

  testWidgets('형식 오류(짧은 비번)는 서버 호출 없이 메시지를 띄운다', (WidgetTester tester) async {
    final auth = buildAuth();

    await tester.pumpWidget(
      wrapForTest(LoginScreen(auth: auth.controller, onLogin: () {})),
    );
    await _typeSignup(tester, email: 'jiwoo@daykit.app', password: 'short');

    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('비밀번호는'), findsOneWidget);
    expect(auth.controller.status, AuthStatus.unknown);
  });

  group('소셜 로그인 (이슈 #38)', () {
    Finder socialButton(SocialProvider p) =>
        find.byKey(ValueKey<String>('social-${p.wireName}'));

    testWidgets('Google 버튼 탭 → oauth 성공 → authenticated', (
      WidgetTester tester,
    ) async {
      final fake = FakeSocialTokenProvider(token: 'g-id');
      final auth = buildAuth(social: fake);
      auth.adapter.onPost(
        '/auth/oauth/google',
        (server) => server.reply(200, sessionEnvelope()),
        data: <String, dynamic>{'idToken': 'g-id'},
      );

      await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));
      await tester.ensureVisible(socialButton(SocialProvider.google));
      await tester.tap(socialButton(SocialProvider.google));
      await tester.pump(); // 로딩 시작
      await tester.pumpAndSettle();

      expect(fake.calls, <SocialProvider>[SocialProvider.google]);
      expect(auth.controller.status, AuthStatus.authenticated);
      expect(auth.fake.snapshot[kAccessTokenKey], 'acc-1');
    });

    testWidgets('Kakao·Apple 버튼은 숨기고 Google만 노출한다 (이슈 #67)', (
      WidgetTester tester,
    ) async {
      final auth = buildAuth(social: FakeSocialTokenProvider(token: 'g-id'));

      await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));

      expect(socialButton(SocialProvider.google), findsOneWidget);
      expect(socialButton(SocialProvider.kakao), findsNothing);
      expect(socialButton(SocialProvider.apple), findsNothing);
    });

    testWidgets('Google 서버 401 → 오류 배너 표시, 미인증 유지', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fake = FakeSocialTokenProvider(token: 'g-id');
      final auth = buildAuth(social: fake);
      auth.adapter.onPost(
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

      await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));
      await tester.tap(socialButton(SocialProvider.google));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('소셜 로그인에 실패했어요.'), findsOneWidget);
      expect(auth.controller.status, isNot(AuthStatus.authenticated));
    });
  });
}
