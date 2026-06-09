import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/auth_api.dart';
import 'package:ieoseo/data/auth/auth_controller.dart';
import 'package:ieoseo/data/auth/social_auth.dart';
import 'package:ieoseo/screens/login.dart';
import 'package:ieoseo/widgets/dk_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'support/fake_supabase_gateway.dart';
import 'support/harness.dart';

/// 로그인은 이메일 우선(ADR-0014). 소셜 버튼은 숨김(kVisibleSocialProviders 비어 있음).

Map<String, dynamic> meEnvelope() => <String, dynamic>{
  'success': true,
  'data': <String, dynamic>{
    'id': 'u-1',
    'email': 'a@b.com',
    'nickname': 'a',
    'provider': 'EMAIL',
  },
  'error': null,
  'meta': null,
};

({AuthController controller, DioAdapter adapter, FakeSupabaseGateway gateway})
buildAuth() {
  final FakeSupabaseGateway gateway = FakeSupabaseGateway();
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

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey<String>(key)),
  matching: find.byType(EditableText),
);

void main() {
  testWidgets('이메일 회원가입 → emailSignUp 호출 → authenticated + justSignedUp', (
    WidgetTester tester,
  ) async {
    final auth = buildAuth();
    auth.adapter.onGet('/auth/me', (server) => server.reply(200, meEnvelope()));

    await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));
    await tester.enterText(_field('login-email'), 'a@b.com');
    await tester.enterText(_field('login-password'), 'pw1234');
    await tester.tap(find.text('가입하기'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(auth.gateway.emailCalls, contains('signup:a@b.com'));
    expect(auth.controller.status, AuthStatus.authenticated);
    expect(auth.controller.justSignedUp, isTrue);
  });

  testWidgets('로그인 모드 전환 후 이메일 로그인 → emailSignIn', (WidgetTester tester) async {
    final auth = buildAuth();
    auth.adapter.onGet('/auth/me', (server) => server.reply(200, meEnvelope()));

    await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));
    await tester.tap(find.text('로그인')); // 모드 전환 링크(가입 모드의 "로그인")
    await tester.pumpAndSettle();

    await tester.enterText(_field('login-email'), 'a@b.com');
    await tester.enterText(_field('login-password'), 'pw1234');
    await tester.tap(find.widgetWithText(DkButton, '로그인'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(auth.gateway.emailCalls, contains('login:a@b.com'));
    expect(auth.controller.status, AuthStatus.authenticated);
    expect(auth.controller.justSignedUp, isFalse);
  });

  testWidgets('짧은 비밀번호는 서버 호출 없이 오류 표시', (WidgetTester tester) async {
    final auth = buildAuth();

    await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));
    await tester.enterText(_field('login-email'), 'a@b.com');
    await tester.enterText(_field('login-password'), 'pw1');
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('비밀번호는'), findsOneWidget);
    expect(auth.gateway.emailCalls, isEmpty);
    expect(auth.controller.status, isNot(AuthStatus.authenticated));
  });

  testWidgets('Google·Kakao 소셜 버튼이 노출된다', (WidgetTester tester) async {
    final auth = buildAuth();

    await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));

    expect(
      find.byKey(ValueKey<String>('social-${SocialProvider.google.wireName}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('social-${SocialProvider.kakao.wireName}')),
      findsOneWidget,
    );
    // Apple 은 후속(미노출).
    expect(
      find.byKey(ValueKey<String>('social-${SocialProvider.apple.wireName}')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey<String>('login-email')), findsOneWidget);
  });
}
