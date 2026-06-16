import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/models.dart';
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
    // 결정적 테스트를 위해 예정일을 고정한 태스크를 준다(신규 시트 기본은 '오늘'이라 시간 의존).
    await _pumpTall(
      tester,
      TaskSheetBody(
        task: const DkTask(
          id: 't',
          title: '고정',
          mins: 30,
          date: '2026-06-01',
          state: DkTaskState.pending,
          category: '공부',
        ),
        isNew: true,
        onClose: () {},
        onSubmit: (_) {},
        onToast: (_, _, _) {},
      ),
    );

    // 주어진 예정일(2026-06-01)이 표시된다.
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
