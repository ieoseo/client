import 'package:ieoseo/data/mock_data.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/parts/task_row.dart';
import 'package:ieoseo/screens/today/today_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

TodayScreen _screen({
  List<DkTask>? tasks,
  ValueChanged<DkTask>? onToggle,
  ValueChanged<DkTask>? onFocus,
  VoidCallback? onOpenDebt,
}) {
  return TodayScreen(
    userName: '지우',
    tasks: tasks ?? kTasks,
    events: kEvents,
    debts: kDebts,
    onToggle: onToggle ?? (_) {},
    onOpenTask: (_) {},
    onOpenEvent: (_) {},
    onAddTask: () {},
    onBell: () {},
    onOpenCalc: () {},
    onFocus: onFocus ?? (_) {},
    onOpenDebt: onOpenDebt ?? () {},
  );
}

/// 긴 화면이 한 번에 레이아웃되도록 큰 뷰포트를 쓴다.
Future<void> _pumpTall(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(440, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapForTest(child));
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  testWidgets('콕핏·D-Day 레일·아젠다·미룬시간 넛지를 렌더한다', (WidgetTester tester) async {
    await _pumpTall(tester, _screen());

    expect(find.text('안녕하세요, 지우님'), findsOneWidget);
    expect(find.text('마감 D-DAY'), findsOneWidget);
    expect(find.text('오늘의 흐름'), findsOneWidget);
    expect(find.text('미룬 시간'), findsOneWidget);
    // 콕핏 다음 할 일은 첫 미완료(정처기 실기 기출 1회 t3).
    expect(find.text('정처기 실기 기출 1회'), findsWidgets);
  });

  testWidgets('아젠다 체크박스 탭은 onToggle을 호출한다', (WidgetTester tester) async {
    DkTask? toggled;
    await _pumpTall(tester, _screen(onToggle: (DkTask t) => toggled = t));

    await tester.tap(find.byType(DkCheckbox).first);
    expect(toggled, isNotNull);
  });

  testWidgets('미룬 시간 넛지 탭은 onOpenDebt를 호출한다', (WidgetTester tester) async {
    bool opened = false;
    await _pumpTall(tester, _screen(onOpenDebt: () => opened = true));

    await tester.tap(find.text('미룬 시간'));
    expect(opened, true);
  });
}
