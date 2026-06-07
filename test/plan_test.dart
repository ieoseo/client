import 'package:ieoseo/data/mock_data.dart';
import 'package:ieoseo/screens/plan/calendar_screen.dart';
import 'package:ieoseo/screens/plan/plan_screen.dart';
import 'package:ieoseo/screens/plan/task_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

PlanScreen _screen() => PlanScreen(
  tasks: kTasks,
  events: kEvents,
  externals: kExternal,
  summary: kWeekSummary,
  debtTotal: 240,
  debtOverdue: 1,
  onToggle: (_) {},
  onOpenTask: (_) {},
  onOpenEvent: (_) {},
  onAddTask: () {},
  onAddEvent: () {},
  onOpenDebt: () {},
  onBell: () {},
);

Future<void> _pumpTall(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(440, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapForTest(child));
  await tester.pump();
}

void main() {
  testWidgets('기본은 캘린더 뷰: 동기화 줄과 MonthGrid', (WidgetTester tester) async {
    await _pumpTall(tester, _screen());

    expect(find.text('플랜'), findsOneWidget);
    expect(find.byType(CalendarScreen), findsOneWidget);
    expect(find.textContaining('연동됨'), findsOneWidget);
  });

  testWidgets('할 일 세그먼트로 전환하면 TaskScreen이 보인다', (WidgetTester tester) async {
    await _pumpTall(tester, _screen());

    await tester.tap(find.text('할 일'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskScreen), findsOneWidget);
    expect(find.byType(CalendarScreen), findsNothing);
    // MetricBar 안내문.
    expect(find.textContaining('밀린 일은 주말로 옮겨드릴게요'), findsOneWidget);
  });
}
