import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/auth_api.dart';
import 'package:ieoseo/data/auth/auth_controller.dart';
import 'package:ieoseo/data/auth/social_auth.dart';
import 'package:ieoseo/screens/login.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'support/fake_supabase_gateway.dart';
import 'support/harness.dart';

/// 로그인은 소셜 전용(ADR-0023) — 카카오·Google·Apple 3개 버튼 노출(DayKit 핸드오프 반영).

Map<String, dynamic> meEnvelope() => <String, dynamic>{
  'success': true,
  'data': <String, dynamic>{
    'id': 'u-1',
    'email': 'a@b.com',
    'nickname': 'a',
    'provider': 'GOOGLE',
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

Finder _social(SocialProvider p) =>
    find.byKey(ValueKey<String>('social-${p.wireName}'));

void main() {
  testWidgets('카카오·Google·Apple 소셜 버튼이 모두 노출된다', (WidgetTester tester) async {
    final auth = buildAuth();

    await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));

    expect(_social(SocialProvider.kakao), findsOneWidget);
    expect(_social(SocialProvider.google), findsOneWidget);
    expect(_social(SocialProvider.apple), findsOneWidget);
  });

  testWidgets('히어로 카피와 법적 고지를 렌더한다', (WidgetTester tester) async {
    final auth = buildAuth();

    await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));

    expect(find.text('오늘을 이어서,\n매일을 끝까지'), findsOneWidget);
    expect(find.textContaining('이용약관'), findsOneWidget);
  });

  testWidgets('이메일/비밀번호 입력은 더 이상 없다(소셜 전용)', (WidgetTester tester) async {
    final auth = buildAuth();

    await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));

    expect(find.byType(EditableText), findsNothing);
    expect(find.text('가입하기'), findsNothing);
  });

  testWidgets('소셜 버튼 탭 → oauthSignIn 호출 → authenticated', (
    WidgetTester tester,
  ) async {
    final auth = buildAuth();
    auth.adapter.onGet('/auth/me', (server) => server.reply(200, meEnvelope()));

    await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));
    await tester.tap(_social(SocialProvider.kakao));
    await tester.pump();

    expect(auth.gateway.oauthCalls, contains(SocialProvider.kakao));

    await tester.pumpAndSettle();
    expect(auth.controller.status, AuthStatus.authenticated);
  });

  testWidgets('복귀 provisioning 실패 시 로그인 화면에 안내 배너가 뜬다(#156)', (
    WidgetTester tester,
  ) async {
    final auth = buildAuth();
    // 세션은 생기지만 /auth/me 가 실패 → out-of-band provisioning 실패.
    auth.adapter.onGet(
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

    await tester.pumpWidget(wrapForTest(LoginScreen(auth: auth.controller)));
    await tester.tap(_social(SocialProvider.apple));
    await tester.pumpAndSettle();

    // 무음 복귀가 아니라 실패 안내가 노출되어야 한다.
    expect(auth.controller.status, isNot(AuthStatus.authenticated));
    expect(find.textContaining('계정 확인에 실패'), findsOneWidget);
  });
}
