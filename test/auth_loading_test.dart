import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/screens/auth_loading.dart';
import 'package:ieoseo/widgets/dk_logo.dart';

import 'support/harness.dart';

void main() {
  testWidgets('로그인 로딩은 브랜드 로고와 안내 문구를 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(wrapForTest(const AuthLoadingView()));
    await tester.pump(); // 무한 펄스 애니메이션이라 pumpAndSettle 금지

    expect(find.byType(DkLogo), findsOneWidget);
    expect(find.text('로그인 중…'), findsOneWidget);
  });

  testWidgets('안내 문구는 message 로 바꿀 수 있다', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(const AuthLoadingView(message: '계정을 준비하고 있어요…')),
    );
    await tester.pump();

    expect(find.text('계정을 준비하고 있어요…'), findsOneWidget);
  });
}
