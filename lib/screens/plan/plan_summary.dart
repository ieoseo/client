import '../../data/models.dart';

/// 플랜 MetricBar 의 3지표(계획·완료·밀린 시간)를 **시간 단위**로 산출하는 순수 함수.
///
/// 계획/완료는 태스크 '개수'가 아니라 예상 소요 **시간 합계**다(분→시간). 밀린 시간(부채)도
/// 분 단위 합계를 시간으로 환산한다. MetricBar 가 "시간"으로 표시하므로 단위를 맞춘다.
DkWeekSummary buildPlanSummary({
  required List<DkTask> tasks,
  required int debtMinutes,
}) {
  final int plannedMins = tasks.fold<int>(0, (int s, DkTask t) => s + t.mins);
  final int doneMins = tasks
      .where((DkTask t) => t.state == DkTaskState.done)
      .fold<int>(0, (int s, DkTask t) => s + t.mins);
  return DkWeekSummary(
    planned: plannedMins / 60.0,
    done: doneMins / 60.0,
    debt: debtMinutes / 60.0,
  );
}
