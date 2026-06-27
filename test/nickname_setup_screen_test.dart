import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/auth/nickname_suggester.dart';
import 'package:ieoseo/screens/nickname_setup_screen.dart';

import 'support/harness.dart';

/// 신규 가입 닉네임 설정 화면 테스트.
void main() {
  testWidgets('랜덤 추천 닉네임이 미리 채워지고 변경 안내를 보여준다', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(NicknameSetupScreen(onSubmit: (_) async {})),
    );

    final EditableText field = tester.widget<EditableText>(
      find.byType(EditableText),
    );
    final String text = field.controller.text;
    // 초깃값이 사전 단어 조합(형용사+동물)으로 채워져 있다.
    expect(kNicknameAdjectives.any(text.startsWith), isTrue);
    expect(kNicknameAnimals.any(text.endsWith), isTrue);

    expect(find.text('닉네임을 정해주세요'), findsOneWidget);
    expect(find.textContaining('나중에'), findsOneWidget); // 변경 가능 안내
  });

  testWidgets('"시작하기" 탭 → 입력한 닉네임으로 onSubmit 호출', (WidgetTester tester) async {
    String? submitted;
    await tester.pumpWidget(
      wrapForTest(
        NicknameSetupScreen(onSubmit: (String n) async => submitted = n),
      ),
    );

    await tester.enterText(find.byType(EditableText), '말랑이');
    await tester.pump();
    await tester.tap(find.text('시작하기'));
    await tester.pump();

    expect(submitted, '말랑이');
  });

  testWidgets('빈 닉네임이면 시작하기로 onSubmit 되지 않는다', (WidgetTester tester) async {
    bool called = false;
    await tester.pumpWidget(
      wrapForTest(NicknameSetupScreen(onSubmit: (_) async => called = true)),
    );

    await tester.enterText(find.byType(EditableText), '   ');
    await tester.pump();
    await tester.tap(find.text('시작하기'));
    await tester.pump();

    expect(called, isFalse);
  });
}
