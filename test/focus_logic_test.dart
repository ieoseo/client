import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/focus/focus_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const DkPomodoro _pomo = DkPomodoro();

void main() {
  group('FocusController 카운트다운', () {
    test('초기 상태는 집중 모드 25분, 정지', () {
      final FocusController c = FocusController(
        pomodoro: _pomo,
        startSessions: 3,
      );
      expect(c.mode, FocusMode.focus);
      expect(c.left, 25 * 60);
      expect(c.running, false);
      expect(c.done, false);
    });

    test('tick은 1초씩 줄인다', () {
      final FocusController c = FocusController(
        pomodoro: _pomo,
        startSessions: 0,
      );
      c.start();
      c.tick();
      expect(c.left, 25 * 60 - 1);
      c.tick();
      expect(c.left, 25 * 60 - 2);
    });

    test('0에 도달하면 완료·정지하고 집중 세션을 +1', () {
      final FocusController c = FocusController(
        pomodoro: const DkPomodoro(focus: 1),
        startSessions: 2,
      );
      c.start();
      for (int i = 0; i < 60; i++) {
        c.tick();
      }
      expect(c.left, 0);
      expect(c.done, true);
      expect(c.running, false);
      expect(c.sessions, 3); // 집중 모드라 +1
    });

    test('휴식 모드 완료는 세션을 늘리지 않는다', () {
      final FocusController c = FocusController(
        pomodoro: const DkPomodoro(shortBreak: 1),
        startSessions: 2,
      );
      c.switchMode(FocusMode.short);
      c.start();
      for (int i = 0; i < 60; i++) {
        c.tick();
      }
      expect(c.done, true);
      expect(c.sessions, 2);
    });

    test('reset은 시간을 채우고 멈춘다', () {
      final FocusController c = FocusController(
        pomodoro: _pomo,
        startSessions: 0,
      );
      c.start();
      c.tick();
      c.reset();
      expect(c.left, 25 * 60);
      expect(c.running, false);
      expect(c.done, false);
    });

    test('switchMode는 해당 모드 시간으로 리셋', () {
      final FocusController c = FocusController(
        pomodoro: _pomo,
        startSessions: 0,
      );
      c.switchMode(FocusMode.long);
      expect(c.mode, FocusMode.long);
      expect(c.left, 15 * 60);
    });

    test('skip: 집중→(4의 배수)긴 휴식', () {
      // sessions=3 → +1 후 4 → long
      final FocusController c = FocusController(
        pomodoro: _pomo,
        startSessions: 3,
      );
      c.skip();
      expect(c.mode, FocusMode.long);
    });

    test('skip: 집중→짧은 휴식(4의 배수 아님)', () {
      final FocusController c = FocusController(
        pomodoro: _pomo,
        startSessions: 0,
      );
      c.skip();
      expect(c.mode, FocusMode.short);
    });

    test('skip: 휴식→집중', () {
      final FocusController c = FocusController(
        pomodoro: _pomo,
        startSessions: 0,
      );
      c.switchMode(FocusMode.short);
      c.skip();
      expect(c.mode, FocusMode.focus);
    });
  });

  group('FocusController 표시값', () {
    test('mmss는 2자리 패딩', () {
      final FocusController c = FocusController(
        pomodoro: _pomo,
        startSessions: 0,
      );
      c.switchMode(FocusMode.short); // 5분
      expect(c.mmss, '05:00');
    });

    test('진행률 pct는 경과 비율', () {
      final FocusController c = FocusController(
        pomodoro: const DkPomodoro(focus: 1),
        startSessions: 0,
      );
      c.start();
      for (int i = 0; i < 30; i++) {
        c.tick();
      }
      expect(c.pct, closeTo(50, 0.001));
    });
  });
}
