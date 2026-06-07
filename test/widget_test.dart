// 진입 플로우 + 인증 게이트 위젯 테스트.
// 스플래시 → 온보딩 → 인증 화면, 그리고 저장 토큰 유무에 따른 main/login 분기.
import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/auth_api.dart';
import 'package:ieoseo/data/api/notif_api.dart';
import 'package:ieoseo/data/api/notif_dto.dart';
import 'package:ieoseo/data/auth/auth_controller.dart';
import 'package:ieoseo/data/auth/token_storage.dart';
import 'package:ieoseo/data/data_controller.dart';
import 'package:ieoseo/data/notif_controller.dart';
import 'package:ieoseo/data/repository.dart';
import 'package:ieoseo/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_secure_storage.dart';

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
    'provider': 'LOCAL',
  },
  'error': null,
  'meta': null,
};

/// 인증 컨트롤러를 가짜 저장소 + DioAdapter로 구성한다.
({AuthController controller, DioAdapter adapter, FakeSecureStorage fake})
buildAuth() {
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
  );
  return (controller: controller, adapter: adapter, fake: fake);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('저장 토큰 없으면 스플래시 → 온보딩 → 인증 화면', (WidgetTester tester) async {
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

    // 미인증 → 회원가입 화면.
    expect(find.text('이어서 시작하기'), findsOneWidget);
  });

  testWidgets('저장 토큰이 유효하면 곧장 main으로 진입한다', (WidgetTester tester) async {
    final auth = buildAuth();
    await auth.fake.write(key: kAccessTokenKey, value: 'acc-1');
    await auth.fake.write(key: kRefreshTokenKey, value: 'ref-1');
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

    // main 탭바(오늘 탭)가 보이고 인증 화면은 없다.
    expect(find.text('이어서 시작하기'), findsNothing);
    expect(find.text('오늘'), findsWidgets);
  });
}
