import 'package:ieoseo/data/mock_data.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/today/today_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

TodayScreen _screen({
  List<DkEvent>? events,
  ValueChanged<DkEvent>? onOpenEvent,
  VoidCallback? onOpenDebt,
}) {
  return TodayScreen(
    events: events ?? kEvents,
    debts: kDebts,
    onOpenEvent: onOpenEvent ?? (_) {},
    onBell: () {},
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
  testWidgets('헤더(오늘 날짜)·다가오는 일정·미룬시간 넛지를 렌더한다', (WidgetTester tester) async {
    await _pumpTall(tester, _screen());

    // 상단 좌측에 오늘 날짜를 제목으로 노출한다(ink 인사 카드는 제거됨).
    final DateTime now = DateTime.now();
    const List<String> weekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
    final String dateLabel =
        '${now.month}월 ${now.day}일 ${weekdays[now.weekday - 1]}요일';
    expect(find.text(dateLabel), findsOneWidget);
    expect(find.text('다가오는 일정'), findsOneWidget);
    expect(find.text('미룬 시간'), findsOneWidget);
    // 옛 인사 카드·오늘 할 일 콕핏은 제거됨.
    expect(find.textContaining('안녕하세요'), findsNothing);
    expect(find.text('오늘의 흐름'), findsNothing);
  });

  testWidgets('일정이 없으면 빈 상태를 보인다', (WidgetTester tester) async {
    await _pumpTall(tester, _screen(events: <DkEvent>[]));

    expect(find.text('다가오는 일정이 없어요'), findsOneWidget);
  });

  testWidgets('다가오는 일정 행 탭은 onOpenEvent를 호출한다', (WidgetTester tester) async {
    DkEvent? opened;
    await _pumpTall(tester, _screen(onOpenEvent: (DkEvent e) => opened = e));

    // 첫 일정 카드(제목)를 탭한다.
    await tester.tap(find.text(kEvents.first.title).first);
    expect(opened, isNotNull);
  });

  testWidgets('미룬 시간 넛지 탭은 onOpenDebt를 호출한다', (WidgetTester tester) async {
    bool opened = false;
    await _pumpTall(tester, _screen(onOpenDebt: () => opened = true));

    await tester.tap(find.text('미룬 시간'));
    expect(opened, true);
  });
}
