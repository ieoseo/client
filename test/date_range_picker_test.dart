import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/sheets/event_sheet.dart';

import 'support/harness.dart';

Future<void> _pumpTall(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(440, 2800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapForTest(child));
  await tester.pump();
}

void main() {
  testWidgets('기간 필드 탭 → 범위 달력에서 시작·종료 선택이 반영된다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      EventSheetBody(
        // 기간(period) 타입 이벤트 — 범위 필드가 보인다.
        event: const DkEvent(
          id: 'e',
          type: DkEventType.period,
          title: '챌린지',
          category: '건강',
          start: '2026-06-08',
          end: '2026-06-12',
          color: 'green',
        ),
        isNew: true,
        onClose: () {},
        onSubmit: (_) {},
      ),
    );

    // 초기 기간 표시.
    expect(find.textContaining('2026. 06. 08'), findsOneWidget);

    // 범위 필드 탭 → 범위 달력 시트.
    await tester.tap(find.byKey(const ValueKey<String>('event-range-field')));
    await tester.pumpAndSettle();
    expect(find.text('기간 선택'), findsOneWidget);

    // 시작 10일 → 종료 15일 선택.
    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.tap(find.text('15'));
    await tester.pump();

    // 확정.
    await tester.tap(find.text('2026. 06. 15 까지 선택'));
    await tester.pumpAndSettle();

    // 필드에 새 기간이 반영된다.
    expect(find.textContaining('2026. 06. 10'), findsOneWidget);
    expect(find.textContaining('2026. 06. 15'), findsOneWidget);
  });
}
