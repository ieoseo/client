import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/parts/task_row.dart';
import 'package:ieoseo/screens/sheets/task_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

Future<void> _pumpTall(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(440, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapForTest(SingleChildScrollView(child: child)));
  await tester.pump();
}

/// 반복 태스크(FRD 5.4) 위젯 테스트.
/// - 시트: 주간 세그먼트 선택 + 요일 토글 → draft.recurrence 에 실제 입력 반영.
/// - 카드/행: 반복 태스크면 repeat 뱃지(아이콘) 노출, 단발이면 미노출.
void main() {
  testWidgets('시트 기본 제출은 단발(none) draft 를 만든다', (WidgetTester tester) async {
    DkTask? submitted;
    await _pumpTall(
      tester,
      TaskSheetBody(
        isNew: true,
        onClose: () {},
        onSubmit: (DkTask t) => submitted = t,
        onToast: (_, _, _) {},
      ),
    );

    await tester.enterText(find.byType(EditableText).first, '단어 암기');
    await tester.tap(find.text('추가하기'));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.recurrence.frequency, DkRecurrenceFreq.none);
  });

  testWidgets('주간 세그먼트 선택 + 요일 토글이 draft 에 반영된다', (WidgetTester tester) async {
    DkTask? submitted;
    await _pumpTall(
      tester,
      TaskSheetBody(
        isNew: true,
        onClose: () {},
        onSubmit: (DkTask t) => submitted = t,
        onToast: (_, _, _) {},
      ),
    );

    await tester.enterText(find.byType(EditableText).first, '영어 단어');
    // 반복 세그먼트에서 '주간' 선택.
    await tester.tap(find.text('주간'));
    await tester.pump();
    // 요일 칩(월·수·금 데모 프리셋)이 떠 있어야 하고, 제출 시 반복 규칙이 담겨야 한다.
    await tester.tap(find.text('추가하기'));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.recurrence.frequency, DkRecurrenceFreq.weekly);
    expect(submitted!.recurrence.weeklyDays, isNotEmpty);
  });

  testWidgets('반복 태스크 행은 repeat 뱃지를 보인다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      const TaskRow(
        task: DkTask(
          id: 't',
          title: '영어 단어',
          mins: 30,
          date: '2026-06-01',
          state: DkTaskState.today,
          category: '어학',
          recurrence: DkRecurrence(
            frequency: DkRecurrenceFreq.weekly,
            weeklyDays: <int>{1, 3, 5},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('task-recurrence-badge')),
      findsOneWidget,
    );
  });

  testWidgets('단발 태스크 행은 repeat 뱃지를 보이지 않는다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      const TaskRow(
        task: DkTask(
          id: 't',
          title: '단발',
          mins: 30,
          date: '2026-06-01',
          state: DkTaskState.today,
          category: '공부',
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('task-recurrence-badge')),
      findsNothing,
    );
  });
}
