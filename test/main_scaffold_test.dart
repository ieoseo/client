import 'package:ieoseo/data/api/auth_dto.dart';
import 'package:ieoseo/data/api/notif_api.dart';
import 'package:ieoseo/data/api/notif_dto.dart';
import 'package:ieoseo/data/api/settings_api.dart';
import 'package:ieoseo/data/api/settings_dto.dart';
import 'package:ieoseo/data/data_controller.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/data/notif_controller.dart';
import 'package:ieoseo/data/repository.dart';
import 'package:ieoseo/data/settings_controller.dart';
import 'package:ieoseo/screens/review/review_screen.dart';
import 'package:ieoseo/screens/main_scaffold.dart';
import 'package:ieoseo/screens/me/me_screen.dart';
import 'package:ieoseo/screens/plan/plan_screen.dart';
import 'package:ieoseo/screens/today/today_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

/// 알림 없는 인메모리 소스(메인 셸 위젯 테스트용).
class _EmptyNotifSource implements NotifSource {
  @override
  Future<NotifListResult> list() async =>
      const NotifListResult(items: <DkNotif>[], unreadCount: 0);

  @override
  Future<DkNotif> markRead(String id) => throw UnimplementedError();

  @override
  Future<int> markAllRead() async => 0;
}

/// 기본값을 돌려주는 인메모리 설정 소스(메인 셸 위젯 테스트용).
class _FakeSettingsSource implements SettingsSource {
  @override
  Future<DkSettings> get() async => const DkSettings();

  @override
  Future<DkSettings> put(DkSettings settings) async => settings;
}

NotifController _notifController() => NotifController(_EmptyNotifSource());

SettingsController _settingsController() =>
    SettingsController(_FakeSettingsSource());

const AuthUser _user = AuthUser(
  id: 'u-1',
  email: 'jiwoo@daykit.app',
  nickname: '지우',
  provider: 'LOCAL',
);

Widget _scaffold() => MainScaffold(
  controller: DataController(MockRepository()),
  notif: _notifController(),
  settings: _settingsController(),
  user: _user,
  dark: false,
  onToggleDark: (_) {},
  onLogout: () {},
  onUpdateProfile: (_) async {},
  onWithdraw: () async {},
);

Future<void> _pumpTall(WidgetTester tester) async {
  tester.view.physicalSize = const Size(440, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapForTest(_scaffold()));
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('기본 탭은 오늘이고 TodayScreen을 보인다', (WidgetTester tester) async {
    await _pumpTall(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('안녕하세요, 지우님'), findsOneWidget);
  });

  testWidgets('탭바로 플랜·통계·프로필로 전환된다', (WidgetTester tester) async {
    await _pumpTall(tester);

    await tester.tap(find.text('플랜'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PlanScreen), findsOneWidget);

    // 집중 탭은 프로필 도구(뽀모도로)로 이동했고, 그 자리에 통계(주간 돌아보기) 탭.
    await tester.tap(find.text('통계'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ReviewScreen), findsOneWidget);

    await tester.tap(find.text('프로필'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MeScreen), findsOneWidget);
  });

  testWidgets('미룬 시간 넛지 탭은 미룬 시간 상세 서브화면을 연다', (WidgetTester tester) async {
    await _pumpTall(tester);

    await tester.tap(find.text('미룬 시간'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('아직 못 한 일, 사라지지 않아요'), findsOneWidget);
  });

  testWidgets('컨트롤러 load 후 오늘 탭에 다가오는 일정을 렌더한다', (WidgetTester tester) async {
    final DataController controller = DataController(MockRepository());
    tester.view.physicalSize = const Size(440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapForTest(
        MainScaffold(
          controller: controller,
          notif: _notifController(),
          settings: _settingsController(),
          user: _user,
          dark: false,
          onToggleDark: (_) {},
          onLogout: () {},
          onUpdateProfile: (_) async {},
          onWithdraw: () async {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    // 오늘 탭은 D-Day 중심 — 시드 이벤트가 다가오는 일정으로 렌더된다.
    expect(find.text('다가오는 일정'), findsOneWidget);
    expect(find.text('정보처리기사 실기'), findsWidgets);
  });

  testWidgets('완료 토글이 컨트롤러 상태에 반영된다', (WidgetTester tester) async {
    final DataController controller = DataController(MockRepository());
    await controller.load();

    // 오늘 상태의 태스크 1건을 완료 토글.
    final DkTask target = controller.tasks.firstWhere(
      (DkTask t) => t.state == DkTaskState.today,
    );
    await controller.toggleComplete(target);

    expect(
      controller.tasks.firstWhere((DkTask t) => t.id == target.id).state,
      DkTaskState.done,
    );
  });
}
