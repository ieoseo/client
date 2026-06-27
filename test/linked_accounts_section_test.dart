import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/auth/social_auth.dart';
import 'package:ieoseo/screens/me/linked_accounts_section.dart';

import 'support/harness.dart';

/// LinkedAccountsSection 위젯 테스트(이슈 #10, Apple 추가 + 해제 확인).
void main() {
  testWidgets('연동 목록과 Google·카카오·Apple 행을 보여준다', (WidgetTester tester) async {
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
    expect(find.text('Apple'), findsOneWidget);
    // 이메일 로그인 제거(ADR-0023) → 이메일 행 없음.
    expect(find.text('이메일'), findsNothing);
  });

  testWidgets('미연동 Apple 은 "연결" 버튼을 누르면 onLink 호출', (
    WidgetTester tester,
  ) async {
    final List<SocialProvider> linked = <SocialProvider>[];
    await tester.pumpWidget(
      wrapForTest(
        LinkedAccountsSection(
          // google·kakao 연동(연결됨), apple 만 미연동 → '연결' 버튼은 apple 행 하나.
          linkedProviders: const <String>{'google', 'kakao'},
          onLink: (SocialProvider p) async => linked.add(p),
          onUnlink: (_) async {},
        ),
      ),
    );

    await tester.tap(find.text('연결'));
    await tester.pump();

    expect(linked, <SocialProvider>[SocialProvider.apple]);
  });

  testWidgets('"연결 해제" → 확인 Alert 에서 "확인"을 눌러야 onUnlink 호출', (
    WidgetTester tester,
  ) async {
    final List<SocialProvider> unlinked = <SocialProvider>[];
    await tester.pumpWidget(
      wrapForTest(
        LinkedAccountsSection(
          linkedProviders: const <String>{'google', 'kakao'},
          onLink: (_) async {},
          onUnlink: (SocialProvider p) async => unlinked.add(p),
        ),
      ),
    );

    // 행의 '연결 해제' 탭 → 확인 Alert 등장(아직 onUnlink 미호출).
    await tester.tap(find.text('연결 해제').first);
    await tester.pumpAndSettle();
    expect(unlinked, isEmpty);

    // Alert 의 '확인' 확정 → onUnlink 호출.
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(unlinked.length, 1);
  });

  testWidgets('"연결 해제" 후 "취소" 하면 onUnlink 미호출', (WidgetTester tester) async {
    final List<SocialProvider> unlinked = <SocialProvider>[];
    await tester.pumpWidget(
      wrapForTest(
        LinkedAccountsSection(
          linkedProviders: const <String>{'google', 'kakao'},
          onLink: (_) async {},
          onUnlink: (SocialProvider p) async => unlinked.add(p),
        ),
      ),
    );

    await tester.tap(find.text('연결 해제').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(unlinked, isEmpty);
  });

  testWidgets('identity 가 하나뿐이어도 "연결 해제" 버튼과 확인 팝업을 보여준다', (
    WidgetTester tester,
  ) async {
    final List<SocialProvider> unlinked = <SocialProvider>[];
    await tester.pumpWidget(
      wrapForTest(
        LinkedAccountsSection(
          linkedProviders: const <String>{'kakao'}, // 단일 identity
          onLink: (_) async {},
          onUnlink: (SocialProvider p) async => unlinked.add(p),
        ),
      ),
    );

    // 정적 '연결됨' 대신 실제 '연결 해제' 버튼이 보인다.
    expect(find.text('연결됨'), findsNothing);
    expect(find.text('연결 해제'), findsOneWidget);

    // 탭하면 확인 Alert 가 뜬다.
    await tester.tap(find.text('연결 해제'));
    await tester.pumpAndSettle();
    expect(find.text('확인'), findsOneWidget);

    // 확인해도 마지막 수단이라 onUnlink 는 호출되지 않고 안내가 뜬다(계정 잠금 방지).
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(unlinked, isEmpty);
    expect(find.textContaining('마지막'), findsOneWidget);
  });
}
