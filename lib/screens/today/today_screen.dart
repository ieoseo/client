import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../data/dday.dart';
import '../../data/format.dart';
import '../../data/meta.dart';
import '../../data/models.dart';
import '../../parts/task_row.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_badge.dart';
import '../../widgets/dk_card.dart';
import '../../widgets/dk_empty.dart';
import '../../widgets/dk_feedback.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_ring.dart';
import '../../widgets/dk_section.dart';
import 'today_logic.dart';

/// 오늘 탭. 프로토타입 `TodayScreen`.
///
/// 콕핏(ink, 완료율 ring, 다음 할 일) → 마감 D-Day 레일 → 오늘의 흐름 아젠다
/// 타임라인 → 미룬 시간 넛지.
/// 오늘 날짜를 "M월 d일 X요일"(한국어)로 포맷한다.
String _todayLabel() {
  final DateTime now = DateTime.now();
  const List<String> weekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
  return '${now.month}월 ${now.day}일 ${weekdays[now.weekday - 1]}요일';
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.userName,
    required this.tasks,
    required this.events,
    required this.debts,
    required this.onToggle,
    required this.onOpenTask,
    required this.onOpenEvent,
    required this.onAddTask,
    required this.onBell,
    required this.onOpenCalc,
    required this.onFocus,
    required this.onOpenDebt,
    this.unread = 0,
  });

  /// 인사말에 쓸 사용자 닉네임(실제 로그인 사용자).
  final String userName;

  final List<DkTask> tasks;
  final List<DkEvent> events;
  final List<DkDebt> debts;

  /// 안 읽은 알림 수(콕핏 벨 점 표시용, 이슈 #46).
  final int unread;
  final ValueChanged<DkTask> onToggle;
  final ValueChanged<DkTask> onOpenTask;
  final ValueChanged<DkEvent> onOpenEvent;
  final VoidCallback onAddTask;
  final VoidCallback onBell;
  final VoidCallback onOpenCalc;
  final ValueChanged<DkTask> onFocus;
  final VoidCallback onOpenDebt;

  @override
  Widget build(BuildContext context) {
    final TodayStats stats = todayStats(tasks, ymd(kToday));
    final List<DkEvent> ordered = <DkEvent>[...events]
      ..sort((DkEvent a, DkEvent b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0));
    final int debtTotal = debts.fold(0, (int s, DkDebt d) => s + d.mins);
    final int debtOverdue = debts
        .where((DkDebt d) => d.status == DkDebtStatus.overdue)
        .length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: <Widget>[
        const SizedBox(height: 54),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _Cockpit(
            userName: userName,
            stats: stats,
            unread: unread,
            onOpenTask: onOpenTask,
            onBell: onBell,
            onOpenCalc: onOpenCalc,
          ),
        ),
        const SizedBox(height: 26),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: DkSectionLabel('마감 D-DAY'),
        ),
        _DdayRail(events: ordered, onOpen: onOpenEvent),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: DkSectionHead(
            title: '오늘의 흐름',
            action: '추가',
            onAction: onAddTask,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: stats.agenda.isEmpty
              ? DkEmpty(
                  icon: 'tasks',
                  title: '오늘 할 일이 없어요',
                  body: '첫 태스크를 추가하고 집중 타이머로 실행해 보세요.',
                  cta: '태스크 추가',
                  onCta: onAddTask,
                )
              : Column(
                  children: <Widget>[
                    for (int i = 0; i < stats.agenda.length; i++)
                      _AgendaRow(
                        task: stats.agenda[i],
                        isLast: i == stats.agenda.length - 1,
                        isNext: stats.next?.id == stats.agenda[i].id,
                        onToggle: onToggle,
                        onOpen: onOpenTask,
                        onFocus: onFocus,
                      ),
                  ],
                ),
        ),
        if (debtTotal > 0) ...<Widget>[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _DebtNudge(
              total: debtTotal,
              overdueCount: debtOverdue,
              onTap: onOpenDebt,
            ),
          ),
        ],
      ],
    );
  }
}

/// ink 콕핏. 인사 + 진행 링 + 다음 할 일.
class _Cockpit extends StatelessWidget {
  const _Cockpit({
    required this.userName,
    required this.stats,
    required this.unread,
    required this.onOpenTask,
    required this.onBell,
    required this.onOpenCalc,
  });

  final String userName;
  final TodayStats stats;
  final int unread;
  final ValueChanged<DkTask> onOpenTask;
  final VoidCallback onBell;
  final VoidCallback onOpenCalc;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    const Color white = Color(0xFFFFFFFF);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: t.ink,
          borderRadius: BorderRadius.circular(28),
          boxShadow: t.shadows.s3,
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -90,
              right: -60,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: t.primary.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _todayLabel(),
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: t.onInkMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '안녕하세요, $userName님',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.66,
                                color: t.onInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _inkBtn('calc', onOpenCalc, t),
                      const SizedBox(width: 8),
                      _inkBtn('bell', onBell, t, dot: unread > 0),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      DkRing(
                        size: 104,
                        stroke: 11,
                        pct: stats.donePct.toDouble(),
                        color: white,
                        track: const Color(0x29FFFFFF),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            DkCountUp(
                              value: stats.donePct.toDouble(),
                              suffix: '%',
                              style: const TextStyle(
                                fontFamily: 'WantedSans',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.78,
                                color: white,
                              ),
                            ),
                            Text(
                              '완료',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: t.onInkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(child: _summary(t)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _nextRow(t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(DkTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '오늘의 할 일',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.onInkMuted,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.02,
                  color: t.onInk,
                ),
                children: <InlineSpan>[
                  TextSpan(text: '${stats.doneCount}'),
                  TextSpan(
                    text: '/${stats.total}',
                    style: TextStyle(color: t.onInkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '완료',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.onInkMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          stats.allDone
              ? '오늘 계획을 모두 끝냈어요'
              : '남은 ${fmtMins(stats.remainMins)} 정도면 끝나요',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: t.onInkMuted,
          ),
        ),
      ],
    );
  }

  Widget _nextRow(DkTokens t) {
    const Color white = Color(0xFFFFFFFF);
    if (stats.allDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            const DkIcon('trophy', size: 22, color: white),
            const SizedBox(width: 10),
            Text(
              '오늘 목표 달성! 푹 쉬어요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: t.onInk,
              ),
            ),
          ],
        ),
      );
    }
    final DkTask? next = stats.next;
    if (next == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => onOpenTask(next),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            Text(
              '다음',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.69,
                color: t.onInkMuted,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                next.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: t.onInk,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              fmtMins(next.mins),
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: t.onInkMuted,
              ),
            ),
            const SizedBox(width: 4),
            DkIcon('chevR', size: 18, color: t.onInkMuted, strokeWidth: 2.2),
          ],
        ),
      ),
    );
  }

  Widget _inkBtn(
    String icon,
    VoidCallback onTap,
    DkTokens t, {
    bool dot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            DkIcon(icon, size: 20, color: t.onInk),
            if (dot)
              Positioned(
                top: -3,
                right: -2,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: t.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 마감 D-Day 가로 레일.
class _DdayRail extends StatelessWidget {
  const _DdayRail({required this.events, required this.onOpen});

  final List<DkEvent> events;
  final ValueChanged<DkEvent> onOpen;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < events.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 12),
            _railCard(t, events[i]),
          ],
        ],
      ),
    );
  }

  Widget _railCard(DkTokens t, DkEvent ev) {
    final DkDdayInfo info = ddayInfo(ev);
    final DkHue h = DkHue.byName(ev.color);
    final String big = info.type == DkEventType.progress
        ? '${info.pct}%'
        : info.label.replaceAll('마감 ', '').replaceAll('시작 ', '');

    return GestureDetector(
      onTap: () => onOpen(ev),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.borderSubtle),
          boxShadow: t.shadows.s1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: h.subtle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DkIcon(
                    'target',
                    size: 17,
                    color: h.color,
                    strokeWidth: 2,
                  ),
                ),
                if (ev.pinned) DkIcon('pin', size: 14, color: t.fgDisabled),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ev.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.fgSubtle,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              big,
              style: TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.78,
                color: info.urgency == DkUrgency.high ? t.danger : t.fgStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 아젠다 타임라인 행(좌측 레일 점 + 카드).
class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.task,
    required this.isLast,
    required this.isNext,
    required this.onToggle,
    required this.onOpen,
    required this.onFocus,
  });

  final DkTask task;
  final bool isLast;
  final bool isNext;
  final ValueChanged<DkTask> onToggle;
  final ValueChanged<DkTask> onOpen;
  final ValueChanged<DkTask> onFocus;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final bool done = task.state == DkTaskState.done;
    final DkHue h = categoryHue(task.category);
    final DkStateMeta st = taskStateMeta(task.state);
    final Color dotColor = done
        ? t.success
        : isNext
        ? t.primary
        : h.color;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 22,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 16),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: done ? t.success : t.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 3),
                    boxShadow: isNext
                        ? <BoxShadow>[
                            BoxShadow(
                              color: t.primarySubtle,
                              blurRadius: 0,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4),
                      color: t.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onOpen(task),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: t.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNext ? t.primary : t.borderSubtle,
                      width: isNext ? 1.5 : 1,
                    ),
                    boxShadow: t.shadows.s1,
                  ),
                  child: Row(
                    children: <Widget>[
                      DkCheckbox(done: done, onTap: () => onToggle(task)),
                      const SizedBox(width: 11),
                      Expanded(child: _content(t, done, h, st)),
                      if (!done) ...<Widget>[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onFocus(task),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: t.primarySubtle,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: DkIcon(
                              'focus',
                              size: 18,
                              color: t.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(DkTokens t, bool done, DkHue h, DkStateMeta st) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (isNext) ...<Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: t.primarySubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '지금',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: t.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.15,
                  color: done ? t.fgDisabled : t.fg,
                  decoration: done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: <Widget>[
            Text(
              fmtMins(task.mins),
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: t.fgSubtle,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: t.borderStrong,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              task.category,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: h.color,
              ),
            ),
            if (task.state == DkTaskState.carried ||
                task.state == DkTaskState.overdue) ...<Widget>[
              const SizedBox(width: 6),
              DkBadge(st.label, tone: st.tone),
            ],
          ],
        ),
      ],
    );
  }
}

/// 미룬 시간 넛지 카드.
class _DebtNudge extends StatelessWidget {
  const _DebtNudge({
    required this.total,
    required this.overdueCount,
    required this.onTap,
  });

  final int total;
  final int overdueCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return DkCard(
      padding: 0,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.warningSubtle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DkIcon(
                'carryForward',
                size: 23,
                color: t.warningFg,
                strokeWidth: 1.9,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        '미룬 시간',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: t.fg,
                        ),
                      ),
                      if (overdueCount > 0) ...<Widget>[
                        const SizedBox(width: 6),
                        DkBadge('계속 밀림 $overdueCount건', tone: DkTone.danger),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: t.fgSubtle,
                      ),
                      children: <InlineSpan>[
                        const TextSpan(text: '총 '),
                        TextSpan(
                          text: fmtMins(total),
                          style: TextStyle(
                            color: t.warningFg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' · 여유 있는 날로 옮겨드릴게요'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DkIcon('chevR', size: 20, color: t.fgDisabled),
          ],
        ),
      ),
    );
  }
}
