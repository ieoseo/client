import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/meta.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/review/week_review_builder.dart';

/// 주 시작(월요일)으로 고정된 참조일. 2026-06-01 은 월요일.
final DateTime _ref = DateTime(2026, 6, 1);

DkTask _task(
  String id,
  String date,
  DkTaskState state, {
  String category = '자격증',
  int mins = 60,
}) => DkTask(
  id: id,
  title: id,
  mins: mins,
  date: date,
  state: state,
  category: category,
);

DkDebt _debt(String id, int mins, DkDebtStatus status) => DkDebt(
  id: id,
  title: id,
  mins: mins,
  fromDate: '2026-05-30',
  status: status,
);

void main() {
  group('buildWeekReview', () {
    test('해당 주 task 의 전체/완료 건수를 집계한다', () {
      final List<DkTask> tasks = <DkTask>[
        _task('a', '2026-06-01', DkTaskState.done),
        _task('b', '2026-06-02', DkTaskState.today),
        _task('c', '2026-06-03', DkTaskState.done),
        // 다른 주 → 제외.
        _task('z', '2026-06-08', DkTaskState.done),
      ];
      final DkWeekReview r = buildWeekReview(
        tasks: tasks,
        debts: const <DkDebt>[],
        reference: _ref,
      );
      expect(r.planned, 3);
      expect(r.done, 2);
      expect(r.byDay.length, 7);
    });

    test('미해소 미룬 시간 합계를 시간 단위로 반올림한다', () {
      final List<DkDebt> debts = <DkDebt>[
        _debt('d1', 90, DkDebtStatus.pending),
        _debt('d2', 60, DkDebtStatus.overdue),
        // 해소/내려놓음은 제외.
        _debt('d3', 120, DkDebtStatus.resolved),
        _debt('d4', 120, DkDebtStatus.abandoned),
      ];
      final DkWeekReview r = buildWeekReview(
        tasks: const <DkTask>[],
        debts: debts,
        reference: _ref,
      );
      // (90 + 60) / 60 = 2.5 → 3.
      expect(r.carried, 3);
    });

    test('요일별 막대: 계획 전부 완료면 allDone', () {
      final List<DkTask> tasks = <DkTask>[
        _task('a', '2026-06-02', DkTaskState.done), // 화 1/1 → allDone
        _task('b', '2026-06-03', DkTaskState.done), // 수 1/2
        _task('c', '2026-06-03', DkTaskState.today),
      ];
      final DkWeekReview r = buildWeekReview(
        tasks: tasks,
        debts: const <DkDebt>[],
        reference: _ref,
      );
      final DkReviewDay tue = r.byDay[1];
      final DkReviewDay wed = r.byDay[2];
      expect(tue.day, '화');
      expect(tue.allDone, true);
      expect(wed.day, '수');
      expect(wed.allDone, false);
    });

    test('카테고리별 분포는 예상 소요 합계 내림차순', () {
      final List<DkTask> tasks = <DkTask>[
        _task('a', '2026-06-01', DkTaskState.done, category: '어학', mins: 30),
        _task('b', '2026-06-02', DkTaskState.today, category: '자격증', mins: 120),
        _task('c', '2026-06-03', DkTaskState.today, category: '어학', mins: 30),
      ];
      final DkWeekReview r = buildWeekReview(
        tasks: tasks,
        debts: const <DkDebt>[],
        reference: _ref,
      );
      expect(r.byCategory.first.cat, '자격증');
      expect(r.byCategory.first.mins, 120);
      expect(r.byCategory[1].cat, '어학');
      expect(r.byCategory[1].mins, 60);
      expect(r.byCategory.first.color, 'violet');
    });

    test('카테고리가 비면 분포는 빈 목록(지어내지 않음)', () {
      final List<DkTask> tasks = <DkTask>[
        _task('a', '2026-06-01', DkTaskState.today, category: ''),
      ];
      final DkWeekReview r = buildWeekReview(
        tasks: tasks,
        debts: const <DkDebt>[],
        reference: _ref,
      );
      expect(r.byCategory, isEmpty);
    });

    test('데이터가 없으면 정직한 0/빈 상태와 안내 문구', () {
      final DkWeekReview r = buildWeekReview(
        tasks: const <DkTask>[],
        debts: const <DkDebt>[],
        reference: _ref,
      );
      expect(r.planned, 0);
      expect(r.done, 0);
      expect(r.carried, 0);
      expect(r.byCategory, isEmpty);
      expect(r.byDay.length, 7);
      expect(r.byDay.every((DkReviewDay d) => d.planned == 0), true);
      expect(r.insight, contains('계획한 일이 없었어요'));
    });

    test('주 범위 라벨은 월~일 7일', () {
      final DkWeekReview r = buildWeekReview(
        tasks: const <DkTask>[],
        debts: const <DkDebt>[],
        reference: _ref,
      );
      expect(r.range, '6월 1일 - 6월 7일');
    });

    test('가장 빠듯했던 요일을 인사이트로 안내', () {
      final List<DkTask> tasks = <DkTask>[
        // 수요일: 계획 2, 완료 0 (가장 빠듯).
        _task('c1', '2026-06-03', DkTaskState.today),
        _task('c2', '2026-06-03', DkTaskState.today),
        // 월요일: 계획 1, 완료 1.
        _task('m1', '2026-06-01', DkTaskState.done),
      ];
      final DkWeekReview r = buildWeekReview(
        tasks: tasks,
        debts: const <DkDebt>[],
        reference: _ref,
      );
      expect(r.insight, contains('수요일'));
    });
  });
}
