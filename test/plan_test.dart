import 'package:ieoseo/data/format.dart';
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
  testWidgets('기본은 캘린더 뷰: MonthGrid', (WidgetTester tester) async {
    await _pumpTall(tester, _screen());

    expect(find.text('플랜'), findsOneWidget);
    expect(find.byType(CalendarScreen), findsOneWidget);
    // 가짜 '연동됨·방금 동기화' 문구는 제거됨(실제 연동 상태 미반영이라).
    expect(find.textContaining('연동됨'), findsNothing);
  });

  testWidgets('월 이동: 다음/이전 달 화살표로 표시 월이 바뀐다', (WidgetTester tester) async {
    await _pumpTall(tester, _screen());

    final DateTime now = DateTime.now();
    String label(int y, int m) => '$y년 ${kMonthsKo[m - 1]}';
    // 처음엔 이번 달이 보인다.
    expect(find.text(label(now.year, now.month)), findsOneWidget);

    // 다음 달로 이동.
    await tester.tap(find.byKey(const ValueKey<String>('cal-next')));
    await tester.pump();
    final DateTime next = DateTime(now.year, now.month + 1);
    expect(find.text(label(next.year, next.month)), findsOneWidget);

    // 이전 달로 두 번 → 지난달.
    await tester.tap(find.byKey(const ValueKey<String>('cal-prev')));
    await tester.tap(find.byKey(const ValueKey<String>('cal-prev')));
    await tester.pump();
    final DateTime prev = DateTime(now.year, now.month - 1);
    expect(find.text(label(prev.year, prev.month)), findsOneWidget);
  });

  testWidgets('일간 뷰: 오늘 칩 + 날짜 네비로 하루 이동', (WidgetTester tester) async {
    await _pumpTall(tester, _screen());

    await tester.tap(find.text('일간'));
    await tester.pump();
    // 오늘 칩과 날짜 네비 화살표가 보인다(섹션헤드의 옛 오늘 버튼은 제거).
    expect(find.text('오늘'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('calnav-next')), findsOneWidget);

    // 다음 날 화살표 → 선택일이 내일로 이동(섹션헤드 날짜 갱신).
    final DateTime tomorrow = addDays(kToday, 1);
    await tester.tap(find.byKey(const ValueKey<String>('calnav-next')));
    await tester.pump();
    expect(
      find.textContaining('${tomorrow.month}월 ${tomorrow.day}일'),
      findsWidgets,
    );
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
