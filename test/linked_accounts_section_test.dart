import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/auth/social_auth.dart';
import 'package:ieoseo/screens/me/linked_accounts_section.dart';

import 'support/harness.dart';

/// LinkedAccountsSection 위젯 테스트(이슈 #10).
void main() {
  testWidgets('연동 목록과 Google·카카오 행을 보여준다', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(
        LinkedAccountsSection(
          linkedProviders: const <String>{'google', 'kakao'},
          onLink: (_) async {},
          onUnlink: (_) async {},
        ),
      ),
    );

    expect(find.text('연동 계정'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('카카오'), findsOneWidget);
    // 이메일 로그인 제거(ADR-0023) → 이메일 행 없음.
    expect(find.text('이메일'), findsNothing);
  });

  testWidgets('미연동 provider 는 "연결" 버튼을 누르면 onLink 호출', (
    WidgetTester tester,
  ) async {
    final List<SocialProvider> linked = <SocialProvider>[];
    await tester.pumpWidget(
      wrapForTest(
        LinkedAccountsSection(
          linkedProviders: const <String>{'email', 'kakao'},
          onLink: (SocialProvider p) async => linked.add(p),
          onUnlink: (_) async {},
        ),
      ),
    );

    await tester.tap(find.text('연결')); // google(미연동) 행의 연결 버튼
    await tester.pump();

    expect(linked, <SocialProvider>[SocialProvider.google]);
  });

  testWidgets('연동된 provider 는 "연결 해제"를 누르면 onUnlink 호출', (
    WidgetTester tester,
  ) async {
    final List<SocialProvider> unlinked = <SocialProvider>[];
    await tester.pumpWidget(
      wrapForTest(
        LinkedAccountsSection(
          linkedProviders: const <String>{'email', 'kakao'},
          onLink: (_) async {},
          onUnlink: (SocialProvider p) async => unlinked.add(p),
        ),
      ),
    );

    await tester.tap(find.text('연결 해제')); // kakao(연동) 행
    await tester.pump();

    expect(unlinked, <SocialProvider>[SocialProvider.kakao]);
  });

  testWidgets('identity 가 하나뿐이면 해제 버튼을 숨긴다', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(
        LinkedAccountsSection(
          linkedProviders: const <String>{'kakao'}, // 단일 identity
          onLink: (_) async {},
          onUnlink: (_) async {},
        ),
      ),
    );

    expect(find.text('연결 해제'), findsNothing);
    expect(find.text('연결됨'), findsWidgets); // kakao 는 연결됨 칩으로만 표시
  });
}
