import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models.dart';

/// 포모도로 모드. 프로토타입 `MODES`(focus/short/long).
enum FocusMode { focus, short, long }

/// 타이머 스킨. 프로토타입 `FOCUS_SKINS`.
enum FocusSkin { ring, minimal, liquid, flip }

FocusMode focusModeFromName(String? s) => switch (s) {
  'short' => FocusMode.short,
  'long' => FocusMode.long,
  _ => FocusMode.focus,
};

String focusModeName(FocusMode m) => switch (m) {
  FocusMode.focus => 'focus',
  FocusMode.short => 'short',
  FocusMode.long => 'long',
};

FocusSkin focusSkinFromName(String? s) => switch (s) {
  'minimal' => FocusSkin.minimal,
  'liquid' => FocusSkin.liquid,
  'flip' => FocusSkin.flip,
  _ => FocusSkin.ring,
};

String focusSkinName(FocusSkin s) => switch (s) {
  FocusSkin.ring => 'ring',
  FocusSkin.minimal => 'minimal',
  FocusSkin.liquid => 'liquid',
  FocusSkin.flip => 'flip',
};

/// 포모도로 상태 + 카운트다운 로직. 프로토타입 `FocusScreen`의 상태부를 추출한다.
///
/// [tick]은 1초 감소를 수행하는 순수 진입점(테스트에서 직접 호출).
/// 실제 화면은 [start]/[pause]가 1초 [Timer]로 [tick]을 호출하게 한다.
/// 상태가 바뀌면 [onPersist]로 (mode/left/sessions/skin)을 알린다.
class FocusController extends ChangeNotifier {
  FocusController({
    required this.pomodoro,
    int startSessions = 0,
    FocusMode mode = FocusMode.focus,
    this._skin = FocusSkin.ring,
    int? startLeft,
    this._onPersist,
  }) : _mode = mode,
       _sessions = startSessions {
    _left = startLeft ?? _modeMins(mode) * 60;
  }

  /// 포모도로 시간 설정. 집중 탭 설정이 바뀌면 [setPomodoro] 로 갱신한다(서버 설정 권위).
  DkPomodoro pomodoro;
  final void Function(FocusController)? _onPersist;

  FocusMode _mode;
  FocusSkin _skin;
  int _left = 0;
  int _sessions;
  bool _running = false;
  bool _done = false;
  Timer? _timer;

  FocusMode get mode => _mode;
  FocusSkin get skin => _skin;
  int get left => _left;
  int get sessions => _sessions;
  bool get running => _running;
  bool get done => _done;

  int get totalSeconds => _modeMins(_mode) * 60;

  int _modeMins(FocusMode m) => switch (m) {
    FocusMode.focus => pomodoro.focus,
    FocusMode.short => pomodoro.shortBreak,
    FocusMode.long => pomodoro.longBreak,
  };

  /// "mm:ss".
  String get mmss => '$mm:$ss';

  String get mm => (_left ~/ 60).toString().padLeft(2, '0');
  String get ss => (_left % 60).toString().padLeft(2, '0');

  /// 경과 비율(0~100).
  double get pct {
    final int total = totalSeconds;
    if (total == 0) return 0;
    return (total - _left) / total * 100;
  }

  /// 상태 텍스트. 프로토타입 `stateText`.
  String get stateText {
    if (_done) return '완료했어요';
    if (_running) return _mode == FocusMode.focus ? '집중하는 중' : '쉬는 중';
    if (_left < totalSeconds) return '일시정지';
    return '시작 준비 완료';
  }

  /// 하단 보조 텍스트. 프로토타입 `sub`.
  String get sub => _mode == FocusMode.focus
      ? '오늘 ${_sessions + 1}번째 집중'
      : '${_modeMins(_mode)}분 휴식';

  /// 1초 감소. 0에 도달하면 완료 처리(집중 모드면 세션 +1).
  void tick() {
    if (_left <= 1) {
      _left = 0;
      _running = false;
      _done = true;
      _stopTimer();
      if (_mode == FocusMode.focus) _sessions++;
      _persist();
      notifyListeners();
      return;
    }
    _left--;
    _persist();
    notifyListeners();
  }

  /// 시작/재개. 실제 화면용: 1초 [Timer]로 [tick] 반복.
  void start() {
    if (_running) return;
    _done = false;
    _running = true;
    _startTimer();
    notifyListeners();
  }

  /// 일시정지.
  void pause() {
    _running = false;
    _stopTimer();
    notifyListeners();
  }

  /// 시작/정지 토글.
  void toggle() => _running ? pause() : start();

  /// 현재 모드 시간으로 리셋.
  void reset() {
    _left = totalSeconds;
    _running = false;
    _done = false;
    _stopTimer();
    _persist();
    notifyListeners();
  }

  /// 모드 전환(시간 리셋·정지).
  void switchMode(FocusMode m) {
    _mode = m;
    _left = _modeMins(m) * 60;
    _running = false;
    _done = false;
    _stopTimer();
    _persist();
    notifyListeners();
  }

  /// 스킨 전환.
  void setSkin(FocusSkin s) {
    _skin = s;
    _persist();
    notifyListeners();
  }

  /// 포모도로 시간 설정 반영(집중 탭 설정 변경). 진행 중이 아니면 현재 모드의 새 시간으로
  /// 리셋해 즉시 보이게 한다. 변화가 없으면 아무 일도 하지 않는다.
  void setPomodoro(DkPomodoro next) {
    if (next.focus == pomodoro.focus &&
        next.shortBreak == pomodoro.shortBreak &&
        next.longBreak == pomodoro.longBreak &&
        next.longEvery == pomodoro.longEvery) {
      return;
    }
    pomodoro = next;
    if (!_running) {
      _left = _modeMins(_mode) * 60;
      _done = false;
    }
    notifyListeners();
  }

  /// 건너뛰기. 집중이면 4의 배수마다 긴 휴식, 아니면 짧은 휴식. 휴식이면 집중.
  void skip() {
    final FocusMode next = _mode == FocusMode.focus
        ? ((_sessions + 1) % pomodoro.longEvery == 0
              ? FocusMode.long
              : FocusMode.short)
        : FocusMode.focus;
    switchMode(next);
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _persist() => _onPersist?.call(this);

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
