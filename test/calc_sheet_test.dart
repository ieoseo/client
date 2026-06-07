import 'package:ieoseo/screens/calc_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

/// 실제 시트(SingleChildScrollView)와 동일하게 스크롤 가능한 컨테이너로 감싼다.
Widget _scrollable() => wrapForTest(
  const SingleChildScrollView(padding: EdgeInsets.all(20), child: Calculator()),
);

void main() {
  testWidgets('숫자·연산자를 눌러 라이브 프리뷰를 보여준다', (WidgetTester tester) async {
    await tester.pumpWidget(_scrollable());

    await tester.tap(find.text('7'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('8'));
    await tester.pump();

    // 라이브 프리뷰 "= 15"
    expect(find.text('= 15'), findsOneWidget);
  });

  testWidgets('= 키는 결과로 식을 치환한다', (WidgetTester tester) async {
    await tester.pumpWidget(_scrollable());

    await tester.tap(find.text('6'));
    await tester.tap(find.text('×'));
    await tester.tap(find.text('7'));
    await tester.tap(find.text('='));
    await tester.pump();

    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('AC는 디스플레이를 0으로 비운다', (WidgetTester tester) async {
    await tester.pumpWidget(_scrollable());

    await tester.tap(find.text('9'));
    await tester.pump();
    expect(find.text('9'), findsNWidgets(2)); // 디스플레이 + 키패드

    await tester.tap(find.text('AC'));
    await tester.pump();
    // AC 후 디스플레이는 "0" → 키패드 "0"과 합쳐 2개.
    expect(find.text('0'), findsNWidgets(2));
    // 디스플레이의 "9"는 사라지고 키패드 "9"만 남는다.
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('공학 모드는 DEG 토글과 함수 키를 노출한다', (WidgetTester tester) async {
    await tester.pumpWidget(_scrollable());

    expect(find.text('sin'), findsNothing);

    await tester.tap(find.text('공학'));
    await tester.pumpAndSettle();

    expect(find.text('DEG'), findsOneWidget);
    expect(find.text('sin'), findsOneWidget);
  });
}
