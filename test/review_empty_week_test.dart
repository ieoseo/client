import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/meta.dart';
import 'package:ieoseo/screens/review/review_screen.dart';

import 'support/harness.dart';

/// 그 주에 계획된 할 일이 0개라 7일 전부 planned/done == 0 인 빈 주.
const DkWeekReview _emptyWeek = DkWeekReview(
  range: '6월 8일 ~ 6월 14일',
  planned: 0,
  done: 0,
  carried: 0,
  byDay: <DkReviewDay>[
    DkReviewDay('월', 0, 0, false),
    DkReviewDay('화', 0, 0, false),
    DkReviewDay('수', 0, 0, false),
    DkReviewDay('목', 0, 0, false),
    DkReviewDay('금', 0, 0, false),
    DkReviewDay('토', 0, 0, false),
    DkReviewDay('일', 0, 0, false),
  ],
  byCategory: <DkReviewCategory>[],
  insight: '',
);

void main() {
  testWidgets('빈 주(계획 0개) 리뷰는 throw 없이 렌더된다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapForTest(ReviewScreen(review: _emptyWeek, streak: 0, onBack: () {})),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(tester.takeException(), isNull);
    expect(find.byType(ReviewScreen), findsOneWidget);
  });
}
