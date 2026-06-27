// 진입 플로우 + 인증 게이트 위젯 테스트.
// 스플래시 → 온보딩 → 인증 화면, 그리고 Supabase 세션 유무에 따른 main/login 분기.
import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/auth_api.dart';
import 'package:ieoseo/data/api/notif_api.dart';
import 'package:ieoseo/data/api/notif_dto.dart';
import 'package:ieoseo/data/auth/auth_controller.dart';
import 'package:ieoseo/data/data_controller.dart';
import 'package:ieoseo/data/notif_controller.dart';
import 'package:ieoseo/data/repository.dart';
import 'package:ieoseo/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_supabase_gateway.dart';

/// 알림 없는 인메모리 소스(인증 게이트 위젯 테스트용).
class _EmptyNotifSource implements NotifSource {
  @override
  Future<NotifListResult> list() async =>
      const NotifListResult(items: <DkNotif>[], unreadCount: 0);

  @override
  Future<DkNotif> markRead(String id) => throw UnimplementedError();

  @override
  Future<int> markAllRead() async => 0;
}

Map<String, dynamic> meEnvelope() => <String, dynamic>{
  'success': true,
  'data': <String, dynamic>{
    'id': 'u-1',
    'email': 'jiwoo@daykit.app',
    'nickname': '지우',
    'provider': 'GOOGLE',
  },
  'error': null,
  'meta': null,
};

/// 인증 컨트롤러를 가짜 Supabase 게이트웨이 + DioAdapter 로 구성한다.
({AuthController controller, DioAdapter adapter, FakeSupabaseGateway gateway})
buildAuth({String? sessionToken}) {
  final FakeSupabaseGateway gateway = FakeSupabaseGateway(
    accessToken: sessionToken,
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
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('세션 없으면 스플래시 → 온보딩 → 인증 화면', (WidgetTester tester) async {
    final auth = buildAuth();
    await tester.pumpWidget(IeoseoApp(auth: auth.controller));

    // 스플래시 카피.
    expect(find.text('D-Day · 할 일 · 집중을 하나로'), findsOneWidget);

    // 스플래시 타이머(3s) 경과 후 온보딩 첫 단계.
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pumpAndSettle();
    expect(find.text('목표까지 며칠?'), findsOneWidget);

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    // 미인증 → 로그인(소셜) 화면.
    expect(find.text('오늘을 이어서,\n매일을 끝까지'), findsOneWidget);
  });

  testWidgets('세션이 유효하면 곧장 main으로 진입한다', (WidgetTester tester) async {
    final auth = buildAuth(sessionToken: 'acc-1');
    auth.adapter.onGet('/auth/me', (server) => server.reply(200, meEnvelope()));

    // 데이터는 목 컨트롤러를 주입(이 테스트는 인증 게이트만 검증).
    await tester.pumpWidget(
      IeoseoApp(
        auth: auth.controller,
        data: DataController(MockRepository()),
        notif: NotifController(_EmptyNotifSource()),
      ),
    );
    // tryRestore(me) 완료까지 진행.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    // main 탭바(홈 탭)가 보이고 인증 화면은 없다.
    expect(find.text('오늘을 이어서,\n매일을 끝까지'), findsNothing);
    expect(find.text('홈'), findsWidgets);
  });
}
