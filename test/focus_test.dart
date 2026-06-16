import 'package:ieoseo/data/api/settings_dto.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/focus/focus_screen.dart';
import 'package:ieoseo/screens/focus/skins.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

FocusScreen _screen({
  DkTask? linked,
  DkSettings settings = const DkSettings(),
}) {
  return FocusScreen(
    focusStats: const DkFocusStats(todaySessions: 3, todayMinutes: 75, goal: 6),
    settings: settings,
    onSaveSettings: (_) {},
    linkedTask: linked,
    onClearTask: () {},
    onBell: () {},
    onCompleteTask: (_) {},
    onToast: (_, _, _) {},
  );
}

Future<void> _pumpTall(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(440, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapForTest(child));
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('모드/스킨 세그먼트와 타이머·통계를 렌더한다', (WidgetTester tester) async {
    await _pumpTall(tester, _screen());

    expect(find.text('스킨'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget); // 기본 링 스킨 시간
    expect(find.text('오늘 집중'), findsOneWidget);
    expect(find.byType(SkinRing), findsOneWidget);
  });

  testWidgets('헤더 톱니 → 뽀모도로 설정 시트(프로필에서 이동, #55)', (WidgetTester tester) async {
    await _pumpTall(tester, _screen());

    expect(
      find.byKey(const ValueKey<String>('focus-settings')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('focus-settings')));
    await tester.pumpAndSettle();

    expect(find.text('뽀모도로 설정'), findsOneWidget);
    expect(find.text('집중 시간'), findsOneWidget);
    expect(find.text('완료음'), findsOneWidget);
  });

  testWidgets('설정의 집중 시간이 타이머에 반영된다(#55)', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      _screen(settings: const DkSettings(pomodoroFocus: 50)),
    );

    // 기본 25:00 이 아니라 설정값 50:00 으로 시작한다.
    expect(find.text('50:00'), findsOneWidget);
    expect(find.text('25:00'), findsNothing);
  });

  testWidgets('스킨을 미니멀로 전환하면 SkinMinimal로 바뀐다', (WidgetTester tester) async {
    await _pumpTall(tester, _screen());

    await tester.tap(find.text('미니멀'));
    await tester.pumpAndSettle();

    expect(find.byType(SkinMinimal), findsOneWidget);
    expect(find.byType(SkinRing), findsNothing);
  });

  testWidgets('짧은 휴식으로 전환하면 05:00이 된다', (WidgetTester tester) async {
    await _pumpTall(tester, _screen());

    await tester.tap(find.text('짧은 휴식'));
    await tester.pumpAndSettle();

    expect(find.text('05:00'), findsOneWidget);
  });

  testWidgets('연결 태스크가 있으면 칩과 제목을 보인다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      _screen(
        linked: const DkTask(
          id: 't',
          title: '정처기 기출',
          mins: 60,
          date: '2026-06-01',
          state: DkTaskState.today,
          category: '자격증',
        ),
      ),
    );

    expect(find.text('정처기 기출'), findsOneWidget);
  });
}
