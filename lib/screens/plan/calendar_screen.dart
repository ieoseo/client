import 'package:flutter/widgets.dart';

import '../../data/format.dart';
import '../../data/meta.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_badge.dart';
import '../../widgets/dk_card.dart';
import '../../widgets/dk_empty.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_section.dart';
import '../../widgets/dk_segmented.dart';
import 'calendar_logic.dart';
import 'week_strip.dart';

/// 캘린더 뷰. 프로토타입 `CalendarScreen`(embedded).
///
/// 월/주/일 세그먼트 → 동기화 줄 → (월)MonthGrid·(주)WeekStrip → 선택일 DayList →
/// 출처 범례.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.tasks,
    required this.events,
    required this.externals,
    required this.onOpenTask,
    required this.onOpenEvent,
  });

  final List<DkTask> tasks;
  final List<DkEvent> events;
  final List<DkExternal> externals;
  final ValueChanged<DkTask> onOpenTask;
  final ValueChanged<DkEvent> onOpenEvent;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

enum _CalView { month, week, day }

class _CalendarScreenState extends State<CalendarScreen> {
  _CalView _view = _CalView.month;
  String _sel = ymd(kToday);

  void _openItem(DayItem it) {
    if (it.task != null) {
      widget.onOpenTask(it.task!);
    } else if (it.event != null) {
      widget.onOpenEvent(it.event!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final DateTime d = parseYmd(_sel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: DkSegmented<_CalView>(
            full: true,
            value: _view,
            onChanged: (_CalView v) => setState(() => _view = v),
            options: const <DkSegment<_CalView>>[
              DkSegment<_CalView>(_CalView.month, '월간'),
              DkSegment<_CalView>(_CalView.week, '주간'),
              DkSegment<_CalView>(_CalView.day, '일간'),
            ],
          ),
        ),
        // 동기화 상태
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              DkIcon('sync', size: 15, color: t.success, strokeWidth: 2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Google · Apple · Notion 연동됨 · 방금 동기화',
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
        ),
        const SizedBox(height: 18),
        if (_view == _CalView.month)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DkCard(
              padding: 16,
              child: _MonthGrid(
                selected: _sel,
                tasks: widget.tasks,
                events: widget.events,
                externals: widget.externals,
                onSelect: (String k) => setState(() => _sel = k),
              ),
            ),
          ),
        if (_view == _CalView.week)
          WeekStrip(
            selected: _sel,
            onSelect: (String k) => setState(() => _sel = k),
          ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DkSectionHead(
            title: '${d.month}월 ${d.day}일 (${kWeekdaysKo[d.weekday % 7]})',
            action: _sel == ymd(kToday) ? '오늘' : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _DayList(
            dateStr: _sel,
            tasks: widget.tasks,
            events: widget.events,
            externals: widget.externals,
            onOpen: _openItem,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              for (final DkSource s in kSourceOrder) _legend(t, s),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(DkTokens t, DkSource s) {
    final DkSourceMeta m = sourceMeta(s);
    final Color color = s == DkSource.app ? t.primary : m.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          m.label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: t.fgSubtle,
          ),
        ),
      ],
    );
  }
}

/// 월 그리드(2026년 6월 고정). 셀에 출처 점 최대 3개.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.selected,
    required this.tasks,
    required this.events,
    required this.externals,
    required this.onSelect,
  });

  final String selected;
  final List<DkTask> tasks;
  final List<DkEvent> events;
  final List<DkExternal> externals;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final List<int?> cells = monthCells(2026, 6);
    final String todayKey = ymd(kToday);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (int i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    kWeekdaysKo[i],
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: i == 0
                          ? t.danger
                          : i == 6
                          ? t.primary
                          : t.fgSubtle,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (int row = 0; row < cells.length ~/ 7; row++)
          Row(
            children: <Widget>[
              for (int col = 0; col < 7; col++)
                Expanded(child: _cell(t, cells[row * 7 + col], col, todayKey)),
            ],
          ),
      ],
    );
  }

  Widget _cell(DkTokens t, int? day, int dow, String todayKey) {
    if (day == null) return const SizedBox(height: 45);
    final String key = '2026-06-${day.toString().padLeft(2, '0')}';
    final List<DayItem> items = dayItems(
      key,
      tasks: tasks,
      events: events,
      externals: externals,
    );
    final bool on = key == selected;
    final bool isToday = key == todayKey;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(key),
      child: Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 4),
        child: Column(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on
                    ? t.primary
                    : isToday
                    ? t.primarySubtle
                    : const Color(0x00000000),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14.5,
                  fontWeight: on || isToday ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.3,
                  color: on
                      ? const Color(0xFFFFFFFF)
                      : isToday
                      ? t.primary
                      : dow == 0
                      ? t.danger
                      : t.fg,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (final DayItem it in items.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _dotColor(t, it),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _dotColor(DkTokens t, DayItem it) {
  if (it.kind == DayItemKind.external) {
    return it.source == DkSource.app ? t.primary : sourceMeta(it.source).color;
  }
  return DkHue.byName(it.colorName).color;
}

/// 선택일 항목 리스트. 외부면 "출처 · 읽기전용" 뱃지.
class _DayList extends StatelessWidget {
  const _DayList({
    required this.dateStr,
    required this.tasks,
    required this.events,
    required this.externals,
    required this.onOpen,
  });

  final String dateStr;
  final List<DkTask> tasks;
  final List<DkEvent> events;
  final List<DkExternal> externals;
  final ValueChanged<DayItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final List<DayItem> items = dayItems(
      dateStr,
      tasks: tasks,
      events: events,
      externals: externals,
    );
    if (items.isEmpty) {
      return const DkEmpty(
        icon: 'calendar',
        title: '일정이 없는 날',
        body: '이 날에는 등록된 D-Day, 할 일, 외부 일정이 없어요.',
      );
    }
    return Column(
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          _row(t, items[i]),
        ],
      ],
    );
  }

  Widget _row(DkTokens t, DayItem it) {
    final bool clickable = it.task != null || it.event != null;
    final bool done = it.taskState == DkTaskState.done;
    final Color color = _dotColor(t, it);
    final String meta = it.isEvent
        ? 'D-Day'
        : it.kind == DayItemKind.task
        ? fmtMins(it.mins ?? 0)
        : (it.time ?? '');

    return GestureDetector(
      onTap: clickable ? () => onOpen(it) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.borderSubtle),
          boxShadow: t.shadows.s1,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 4,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    it.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.15,
                      color: done ? t.fgDisabled : t.fg,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Text(
                        meta,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: t.fgSubtle,
                        ),
                      ),
                      if (it.source != DkSource.app) ...<Widget>[
                        const SizedBox(width: 8),
                        DkBadge(
                          '${sourceMeta(it.source).label} · 읽기전용',
                          tone: DkTone.neutral,
                          leading: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (clickable)
              DkIcon('chevR', size: 18, color: t.fgDisabled)
            else if (it.isEvent)
              DkIcon('target', size: 16, color: t.fgDisabled),
          ],
        ),
      ),
    );
  }
}
