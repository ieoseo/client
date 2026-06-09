import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/auth_api.dart';
import 'package:ieoseo/data/auth/auth_controller.dart';
import 'package:ieoseo/screens/nickname_setup.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'support/fake_supabase_gateway.dart';
import 'support/harness.dart';

Map<String, dynamic> meEnvelope({String nickname = 'a'}) => <String, dynamic>{
  'success': true,
  'data': <String, dynamic>{
    'id': 'u-1',
    'email': 'a@b.com',
    'nickname': nickname,
    'provider': 'EMAIL',
  },
  'error': null,
  'meta': null,
};

/// 가입 직후(justSignedUp=true) 상태의 컨트롤러를 만든다.
Future<({AuthController controller, DioAdapter adapter})>
signedUpController() async {
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
  adapter.onGet('/auth/me', (server) => server.reply(200, meEnvelope()));
  await controller.emailSignUp(email: 'a@b.com', password: 'pw1234');
  return (controller: controller, adapter: adapter);
}

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey<String>(key)),
  matching: find.byType(EditableText),
);

void main() {
  testWidgets('닉네임 입력 후 시작하기 → updateProfile → justSignedUp 해제', (
    WidgetTester tester,
  ) async {
    late ({AuthController controller, DioAdapter adapter}) c;
    await tester.runAsync(() async {
      c = await signedUpController();
    });
    expect(c.controller.justSignedUp, isTrue);

    c.adapter.onPatch(
      '/auth/me',
      (server) => server.reply(200, meEnvelope(nickname: '지우')),
      data: <String, dynamic>{'nickname': '지우'},
    );

    await tester.pumpWidget(
      wrapForTest(NicknameSetupScreen(auth: c.controller)),
    );
    await tester.enterText(_field('nickname-input'), '지우');
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(c.controller.user?.nickname, '지우');
    expect(c.controller.justSignedUp, isFalse);
  });

  testWidgets('빈 닉네임 → 오류 표시, justSignedUp 유지', (WidgetTester tester) async {
    late ({AuthController controller, DioAdapter adapter}) c;
    await tester.runAsync(() async {
      c = await signedUpController();
    });

    await tester.pumpWidget(
      wrapForTest(NicknameSetupScreen(auth: c.controller)),
    );
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('닉네임을 입력해 주세요.'), findsOneWidget);
    expect(c.controller.justSignedUp, isTrue);
  });
}
