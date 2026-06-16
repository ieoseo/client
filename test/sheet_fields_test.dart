import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/screens/sheets/sheet_fields.dart';

import 'support/harness.dart';

void main() {
  // DkTextInput 회귀: raw EditableText 대신 TextField 를 써서 탭→키보드 표시,
  // 키보드 내린 뒤 재탭 시 재표시가 정상 동작해야 한다(이슈 #46).
  Widget input() => wrapForTest(
    const Align(
      alignment: Alignment.topCenter,
      child: DkTextInput(placeholder: '예) 제목'),
    ),
  );

  testWidgets('DkTextInput 은 TextField 로 렌더된다', (WidgetTester tester) async {
    await tester.pumpWidget(input());
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('탭하면 키보드가 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(input());

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('키보드를 내린 뒤 재탭하면 다시 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(input());

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    // 사용자가 키보드를 내린 상태(포커스는 유지)를 모사한다.
    tester.testTextInput.hide();
    expect(tester.testTextInput.isVisible, isFalse);

    // 같은 필드를 다시 탭하면 키보드가 재표시되어야 한다.
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
  });
}
