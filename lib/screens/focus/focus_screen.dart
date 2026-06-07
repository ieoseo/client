import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/format.dart';
import '../../data/models.dart';
import '../../parts/app_header.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_button.dart';
import '../../widgets/dk_card.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_segmented.dart';
import 'focus_controller.dart';
import 'skins.dart';

const String _prefsKey = 'dk_focus';

/// 집중(포모도로) 탭. 프로토타입 `FocusScreen`.
///
/// 모드 세그먼트 + 스킨 4종 + 실시간 카운트다운 + 연결 태스크 + 완료 루프 + 통계.
/// 스킨/세션/모드/남은 시간은 shared_preferences에 영속화한다.
class FocusScreen extends StatefulWidget {
  const FocusScreen({
    super.key,
    required this.pomodoro,
    required this.focusStats,
    this.linkedTask,
    required this.onClearTask,
    required this.onBell,
    required this.onCompleteTask,
    required this.onToast,
    this.unread = 0,
  });

  final DkPomodoro pomodoro;
  final DkFocusStats focusStats;
  final DkTask? linkedTask;

  /// 안 읽은 알림 수(헤더 벨 점 표시용, 이슈 #46).
  final int unread;
  final VoidCallback onClearTask;
  final VoidCallback onBell;
  final ValueChanged<DkTask> onCompleteTask;

  /// (메시지, 아이콘, tone) 토스트 콜백.
  final void Function(String message, String icon, String tone) onToast;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late final FocusController _c;
  bool _wasDone = false;

  @override
  void initState() {
    super.initState();
    _c = FocusController(
      pomodoro: widget.pomodoro,
      startSessions: widget.focusStats.todaySessions,
      onPersist: _persist,
    );
    _c.addListener(_onChange);
    _load();
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _c.dispose();
    super.dispose();
  }

  void _onChange() {
    if (_c.done && !_wasDone) {
      _wasDone = true;
      final bool focus = _c.mode == FocusMode.focus;
      widget.onToast(
        focus ? '집중 세션을 완료했어요. 잠깐 쉬어요' : '휴식 끝! 다시 집중해볼까요',
        focus ? 'check' : 'coffee',
        focus ? 'success' : 'primary',
      );
    } else if (!_c.done) {
      _wasDone = false;
    }
    setState(() {});
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      final FocusMode mode = focusModeFromName(m['mode'] as String?);
      final FocusSkin skin = focusSkinFromName(m['skin'] as String?);
      if (mode != _c.mode) _c.switchMode(mode);
      if (skin != _c.skin) _c.setSkin(skin);
    } on FormatException {
      // 손상된 값은 무시.
    }
  }

  Future<void> _persist(FocusController c) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(<String, dynamic>{
        'mode': focusModeName(c.mode),
        'left': c.left,
        'sessions': c.sessions,
        'skin': focusSkinName(c.skin),
      }),
    );
  }

  Color _modeColor(DkTokens t) => switch (_c.mode) {
    FocusMode.focus => t.primary,
    FocusMode.short => t.success,
    FocusMode.long => t.infoFg,
  };

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final Color modeColor = _modeColor(t);
    final FocusSkinProps props = FocusSkinProps(
      pct: _c.pct,
      color: modeColor,
      mm: _c.mm,
      ss: _c.ss,
      stateText: _c.stateText,
      sub: _c.sub,
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        AppHeader(
          title: '집중',
          subtitle: '포모도로로 실제로 실행해요',
          unread: widget.unread,
          onBell: widget.onBell,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DkSegmented<FocusMode>(
                full: true,
                value: _c.mode,
                onChanged: _c.switchMode,
                options: const <DkSegment<FocusMode>>[
                  DkSegment<FocusMode>(FocusMode.focus, '집중'),
                  DkSegment<FocusMode>(FocusMode.short, '짧은 휴식'),
                  DkSegment<FocusMode>(FocusMode.long, '긴 휴식'),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  DkIcon('sparkle', size: 14, color: t.fgSubtle),
                  const SizedBox(width: 5),
                  Text(
                    '스킨',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.48,
                      color: t.fgSubtle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DkSegmented<FocusSkin>(
                full: true,
                value: _c.skin,
                onChanged: _c.setSkin,
                options: const <DkSegment<FocusSkin>>[
                  DkSegment<FocusSkin>(FocusSkin.ring, '링'),
                  DkSegment<FocusSkin>(FocusSkin.minimal, '미니멀'),
                  DkSegment<FocusSkin>(FocusSkin.liquid, '리퀴드'),
                  DkSegment<FocusSkin>(FocusSkin.flip, '플립'),
                ],
              ),
              const SizedBox(height: 18),
              _linkedChip(t, modeColor),
              const SizedBox(height: 20),
              Center(child: _skin(props)),
              const SizedBox(height: 24),
              _controls(t, modeColor),
              if (_c.done &&
                  _c.mode == FocusMode.focus &&
                  widget.linkedTask != null) ...<Widget>[
                const SizedBox(height: 20),
                _completionLoop(t),
              ],
              const SizedBox(height: 20),
              _todayStats(t, modeColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _skin(FocusSkinProps props) {
    switch (_c.skin) {
      case FocusSkin.ring:
        return SkinRing(props: props);
      case FocusSkin.minimal:
        return SkinMinimal(props: props);
      case FocusSkin.liquid:
        return SkinLiquid(props: props);
      case FocusSkin.flip:
        return SkinFlip(props: props);
    }
  }

  Widget _linkedChip(DkTokens t, Color modeColor) {
    final DkTask? task = widget.linkedTask;
    if (task == null) {
      return Center(
        child: Text(
          '태스크에서 "집중 시작"으로 연결할 수 있어요',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: t.fgSubtle,
          ),
        ),
      );
    }
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Color.lerp(modeColor, t.bg, 0.88),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DkIcon('target', size: 16, color: modeColor, strokeWidth: 2),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                task.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: modeColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onClearTask,
              child: DkIcon('x', size: 15, color: modeColor, strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(DkTokens t, Color modeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _ctrlGhost('reset', t, _c.reset),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: _c.toggle,
          child: Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: modeColor,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: modeColor.withValues(alpha: 0.42),
                  offset: const Offset(0, 10),
                  blurRadius: 26,
                ),
              ],
            ),
            child: DkIcon(
              _c.running ? 'pause' : 'play',
              size: 36,
              color: const Color(0xFFFFFFFF),
              fill: const Color(0xFFFFFFFF),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _ctrlGhost('skip', t, _c.skip, fill: true),
      ],
    );
  }

  Widget _ctrlGhost(
    String icon,
    DkTokens t,
    VoidCallback onTap, {
    bool fill = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: t.bgPress, shape: BoxShape.circle),
        child: DkIcon(
          icon,
          size: 24,
          color: t.fgMuted,
          fill: fill ? t.fgMuted : null,
        ),
      ),
    );
  }

  Widget _completionLoop(DkTokens t) {
    final DkTask task = widget.linkedTask!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.successSubtle,
        borderRadius: BorderRadius.circular(t.radius),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.success,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const DkIcon(
              'check',
              size: 22,
              color: Color(0xFFFFFFFF),
              strokeWidth: 2.6,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '집중을 마쳤어요',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.successFg,
                  ),
                ),
                Text(
                  '‘${task.title}’ 할 일도 완료할까요?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: t.fgMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DkButton(
            size: DkButtonSize.sm,
            onPressed: () {
              widget.onCompleteTask(task);
              setState(() => _wasDone = false);
            },
            leading: const DkIcon(
              'check',
              size: 16,
              color: Color(0xFFFFFFFF),
              strokeWidth: 2.4,
            ),
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }

  Widget _todayStats(DkTokens t, Color modeColor) {
    final int goal = widget.focusStats.goal;
    return DkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '오늘 집중',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: t.fg,
                ),
              ),
              Text(
                '${_c.sessions} / $goal회',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.fgSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              for (int i = 0; i < goal; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i < _c.sessions ? modeColor : t.bgPress,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DkIcon(
                      'focus',
                      size: 18,
                      color: i < _c.sessions
                          ? const Color(0xFFFFFFFF)
                          : t.fgDisabled,
                      strokeWidth: 2,
                      fill: i < _c.sessions ? const Color(0x40FFFFFF) : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              DkIcon('clock', size: 14, color: t.fgSubtle, strokeWidth: 2),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '누적 ${fmtMins(_c.sessions * widget.pomodoro.focus)} 집중 · 4회마다 긴 휴식을 권해요',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: t.fgSubtle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
