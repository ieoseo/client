import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/meta.dart';
import 'package:ieoseo/screens/review/review_screen.dart';

import 'support/harness.dart';

/// 계획 7건·완료 3건·밀린 시간 2시간인 주. planned/done 은 건수, carried 만 시간.
const DkWeekReview _review = DkWeekReview(
  range: '6월 8일 ~ 6월 14일',
  planned: 7,
  done: 3,
  carried: 2,
  byDay: <DkReviewDay>[
    DkReviewDay('월', 2, 1, false),
    DkReviewDay('화', 1, 1, true),
    DkReviewDay('수', 1, 0, false),
    DkReviewDay('목', 1, 1, true),
    DkReviewDay('금', 1, 0, false),
    DkReviewDay('토', 1, 0, false),
    DkReviewDay('일', 0, 0, false),
  ],
  byCategory: <DkReviewCategory>[],
  insight: '',
);

void main() {
  testWidgets('계획·완료는 건수(개), 밀린 시간만 시간 단위로 표기한다(F10)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(440, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapForTest(ReviewScreen(review: _review, streak: 0, onBack: () {})),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('7개'), findsOneWidget); // 계획 건수
    expect(find.textContaining('3개'), findsOneWidget); // 완료 건수
    expect(find.textContaining('2시간'), findsOneWidget); // 밀린 시간(유일하게 시간)
  });
}
