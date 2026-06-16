import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/screens/sheets/task_sheet.dart';

import 'support/harness.dart';

Future<void> _pumpTall(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(440, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapForTest(child));
  await tester.pump();
}

void main() {
  testWidgets('예정일 필드 탭 → 달력 → 선택이 필드에 반영된다(#57)', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      TaskSheetBody(
        isNew: true,
        onClose: () {},
        onSubmit: (_) {},
        onToast: (_, _, _) {},
      ),
    );

    // 기본 예정일(2026-06-01)이 표시된다.
    expect(find.text('2026. 06. 01'), findsOneWidget);

    // 필드 탭 → 달력 시트.
    await tester.tap(find.byKey(const ValueKey<String>('task-date-field')));
    await tester.pumpAndSettle();
    expect(find.text('날짜 선택'), findsOneWidget);

    // 15일 선택 후 확정.
    await tester.tap(find.text('15'));
    await tester.pump();
    await tester.tap(find.text('2026. 06. 15 선택'));
    await tester.pumpAndSettle();

    // 필드에 반영된다.
    expect(find.text('2026. 06. 15'), findsOneWidget);
  });
}
