import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/plan/plan_summary.dart';

DkTask _task(int mins, DkTaskState state) => DkTask(
  id: 't$mins-${state.name}',
  title: 'x',
  mins: mins,
  date: '2026-06-17',
  state: state,
  category: '공부',
);

void main() {
  test('계획은 태스크 개수가 아니라 예상 시간 합계(분→시간)다', () {
    // 2시간(120분) 태스크 1개 → 계획 2.0 시간(개수 1 이 아님).
    final DkWeekSummary s = buildPlanSummary(
      tasks: <DkTask>[_task(120, DkTaskState.today)],
      debtMinutes: 0,
    );

    expect(s.planned, 2.0);
    expect(s.done, 0.0);
  });

  test('완료는 done 태스크의 시간 합계, 밀린 시간은 부채 분→시간', () {
    final DkWeekSummary s = buildPlanSummary(
      tasks: <DkTask>[
        _task(120, DkTaskState.done), // 2h 완료
        _task(90, DkTaskState.today), // 1.5h 계획만
      ],
      debtMinutes: 30, // 0.5h
    );

    expect(s.planned, closeTo(3.5, 1e-9)); // (120+90)/60
    expect(s.done, 2.0);
    expect(s.debt, 0.5);
  });

  test('태스크가 없으면 모두 0', () {
    final DkWeekSummary s = buildPlanSummary(
      tasks: const <DkTask>[],
      debtMinutes: 0,
    );

    expect(s.planned, 0.0);
    expect(s.done, 0.0);
    expect(s.debt, 0.0);
  });
}
