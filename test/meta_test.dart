import 'package:ieoseo/data/format.dart';
import 'package:ieoseo/data/meta.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('eventDateLabel', () {
    test('T1은 단일 날짜를 점 표기로', () {
      const DkEvent ev = DkEvent(
        id: 'e',
        type: DkEventType.single,
        title: '시험',
        category: '자격증',
        date: '2026-06-29',
      );
      expect(eventDateLabel(ev), '2026. 06. 29');
    });

    test('T2/T3은 시작 ~ 종료', () {
      const DkEvent ev = DkEvent(
        id: 'e',
        type: DkEventType.period,
        title: '접수',
        category: '자격증',
        start: '2026-06-08',
        end: '2026-06-12',
      );
      expect(eventDateLabel(ev), '2026. 06. 08 ~ 2026. 06. 12');
    });
  });

  group('categoryHue', () {
    test('카테고리명 → 해당 hue', () {
      expect(categoryHue('자격증'), DkHue.violet);
      expect(categoryHue('어학'), DkHue.blue);
      expect(categoryHue('건강'), DkHue.green);
    });

    test('미상 카테고리는 cool', () {
      expect(categoryHue('없는카테고리'), DkHue.cool);
    });
  });

  group('상태 메타', () {
    test('태스크 상태 → 톤·라벨', () {
      expect(taskStateMeta(DkTaskState.done).label, '완료');
      expect(taskStateMeta(DkTaskState.overdue).label, '밀림');
      expect(taskStateMeta(DkTaskState.carried).label, '옮김');
    });

    test('부채 상태 → 톤·라벨', () {
      expect(debtStateMeta(DkDebtStatus.overdue).label, '계속 밀림');
      expect(debtStateMeta(DkDebtStatus.assigned).label, '배정됨');
    });

    test('출처 메타 라벨', () {
      expect(sourceMeta(DkSource.google).label, 'Google');
      expect(sourceMeta(DkSource.app).label, '이어서');
    });
  });

  group('주간 리뷰 목 데이터', () {
    test('합계가 일관적이다', () {
      expect(kWeekReview.byDay.length, 7);
      expect(kWeekReview.byCategory.isNotEmpty, true);
      expect(kWeekReview.planned, 21);
    });
  });
}
