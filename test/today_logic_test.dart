import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/today/today_logic.dart';
import 'package:flutter_test/flutter_test.dart';

DkTask _t(String id, DkTaskState state, {int mins = 30}) => DkTask(
  id: id,
  title: id,
  mins: mins,
  date: '2026-06-01',
  state: state,
  category: '공부',
);

void main() {
  group('todayStats', () {
    test('완료율·남은 시간·다음 할 일을 계산한다', () {
      final List<DkTask> tasks = <DkTask>[
        _t('a', DkTaskState.done, mins: 60),
        _t('b', DkTaskState.today, mins: 90),
        _t('c', DkTaskState.pending, mins: 30),
      ];

      final TodayStats s = todayStats(tasks, '2026-06-01');

      expect(s.total, 3);
      expect(s.doneCount, 1);
      expect(s.donePct, 33); // 1/3
      expect(s.remainMins, 120); // 90 + 30
      expect(s.next?.id, 'b');
      expect(s.allDone, false);
    });

    test('모두 완료면 allDone이 true이고 다음은 없다', () {
      final List<DkTask> tasks = <DkTask>[
        _t('a', DkTaskState.done),
        _t('b', DkTaskState.done),
      ];

      final TodayStats s = todayStats(tasks, '2026-06-01');

      expect(s.allDone, true);
      expect(s.donePct, 100);
      expect(s.next, isNull);
    });

    test('다른 날짜 태스크는 제외한다', () {
      final List<DkTask> tasks = <DkTask>[
        _t('a', DkTaskState.today),
        const DkTask(
          id: 'x',
          title: 'x',
          mins: 30,
          date: '2026-06-02',
          state: DkTaskState.pending,
          category: '공부',
        ),
      ];

      final TodayStats s = todayStats(tasks, '2026-06-01');
      expect(s.total, 1);
    });

    test('아젠다는 미완료(다음 먼저) 후 완료 순서', () {
      final List<DkTask> tasks = <DkTask>[
        _t('done1', DkTaskState.done),
        _t('next', DkTaskState.today),
        _t('pend', DkTaskState.pending),
      ];

      final TodayStats s = todayStats(tasks, '2026-06-01');
      expect(s.agenda.map((DkTask t) => t.id).toList(), <String>[
        'next',
        'pend',
        'done1',
      ]);
    });

    test('빈 목록은 0%·allDone false', () {
      final TodayStats s = todayStats(<DkTask>[], '2026-06-01');
      expect(s.total, 0);
      expect(s.donePct, 0);
      expect(s.allDone, false);
    });
  });
}
