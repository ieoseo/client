import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/focus/focus_screen.dart';
import 'package:ieoseo/screens/focus/skins.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

FocusScreen _screen({DkTask? linked}) {
  return FocusScreen(
    pomodoro: const DkPomodoro(),
    focusStats: const DkFocusStats(todaySessions: 3, todayMinutes: 75, goal: 6),
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
