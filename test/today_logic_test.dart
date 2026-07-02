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

  group('ddayOrdered', () {
    DkEvent ev(String id, String date, {bool pinned = false}) => DkEvent(
      id: id,
      type: DkEventType.single,
      title: id,
      category: '공부',
      date: date,
      pinned: pinned,
    );

    test('임박한(가까운 미래) 일정이 먼저 온다', () {
      final List<DkEvent> events = <DkEvent>[
        ev('far', '2026-06-20'), // D-19
        ev('soon', '2026-06-03'), // D-2
        ev('mid', '2026-06-10'), // D-9
      ];

      final List<DkEvent> out = ddayOrdered(
        events,
        today: DateTime(2026, 6, 1),
      );
      expect(out.map((DkEvent e) => e.id).toList(), <String>[
        'soon',
        'mid',
        'far',
      ]);
    });

    test('지난 일정은 미래 일정보다 뒤로 간다', () {
      final List<DkEvent> events = <DkEvent>[
        ev('past', '2026-05-20'), // 지남
        ev('future', '2026-06-05'), // D-4
      ];

      final List<DkEvent> out = ddayOrdered(
        events,
        today: DateTime(2026, 6, 1),
      );
      expect(out.map((DkEvent e) => e.id).toList(), <String>['future', 'past']);
    });

    test('원본 리스트를 변형하지 않는다', () {
      final List<DkEvent> events = <DkEvent>[
        ev('b', '2026-06-10'),
        ev('a', '2026-06-03'),
      ];
      ddayOrdered(events, today: DateTime(2026, 6, 1));
      expect(events.map((DkEvent e) => e.id).toList(), <String>['b', 'a']);
    });

    test('핀 고정 일정은 덜 임박해도 상단에 온다(#162)', () {
      final List<DkEvent> events = <DkEvent>[
        ev('soon', '2026-06-03'), // D-2 (핀 아님)
        ev('pinnedFar', '2026-06-20', pinned: true), // D-19 이지만 핀
      ];

      final List<DkEvent> out = ddayOrdered(
        events,
        today: DateTime(2026, 6, 1),
      );
      expect(out.map((DkEvent e) => e.id).toList(), <String>[
        'pinnedFar',
        'soon',
      ]);
    });

    test('핀 고정끼리는 임박순으로 정렬한다(#162)', () {
      final List<DkEvent> events = <DkEvent>[
        ev('pinFar', '2026-06-20', pinned: true), // D-19
        ev('pinSoon', '2026-06-05', pinned: true), // D-4
        ev('plain', '2026-06-03'), // D-2
      ];

      final List<DkEvent> out = ddayOrdered(
        events,
        today: DateTime(2026, 6, 1),
      );
      expect(out.map((DkEvent e) => e.id).toList(), <String>[
        'pinSoon',
        'pinFar',
        'plain',
      ]);
    });
  });
}
