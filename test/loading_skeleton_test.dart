import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/screens/loading_skeleton.dart';
import 'package:ieoseo/widgets/dk_skeleton.dart';

import 'support/harness.dart';

void main() {
  testWidgets('로딩 스켈레톤은 플레이스홀더 블록들을 렌더한다(날것 텍스트 없음)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapForTest(const AppLoadingSkeleton()));
    await tester.pump(); // 무한 shimmer 라 pumpAndSettle 금지

    expect(find.byType(DkSkeleton), findsWidgets);
    expect(find.text('불러오는 중…'), findsNothing);
  });

  testWidgets('reduced-motion 에서도 예외 없이 정적으로 렌더된다', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppLoadingSkeleton(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DkSkeleton), findsWidgets);
  });
}
