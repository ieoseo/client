import 'package:flutter/widgets.dart';

import '../../data/dday.dart';
import '../../data/format.dart';
import '../../data/meta.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_brand_mark.dart';
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

enum _CalView { month, week }

class _CalendarScreenState extends State<CalendarScreen> {
  _CalView _view = _CalView.month;
  String _sel = ymd(kToday);

  /// 표시 중인 월(선택과 독립). 이전/다음 달로 이동할 수 있게 별도 상태로 둔다.
  DateTime _month = DateTime(kToday.year, kToday.month);

  // 주간 PageView(주 단위 캐러셀 슬라이드 — 끌면 옆 주가 따라오고 ‹›도 슬라이드).
  // 페이지 = anchor 주로부터의 주 수. anchor 는 주간 진입 시점 선택일의 월요일.
  PageController? _weekCtrl;
  DateTime _weekAnchorMonday = addDays(kToday, 1 - kToday.weekday);
  static const int _weekAnchorPage = 100000;
  static const Duration _kWeekAnim = Duration(milliseconds: 300);

  DateTime _mondayOf(DateTime d) => addDays(d, 1 - d.weekday);
  DateTime _mondayForPage(int page) =>
      addDays(_weekAnchorMonday, (page - _weekAnchorPage) * 7);

  /// UTC 자정 기준 일수(주 차이 계산용 — DST 영향 없음).
  int _epochDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  int _pageForMonday(DateTime mon) =>
      _weekAnchorPage + (_epochDay(mon) - _epochDay(_weekAnchorMonday)) ~/ 7;

  @override
  void dispose() {
    _weekCtrl?.dispose();
    super.dispose();
  }

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  /// 뷰 전환. 주간 진입 시 anchor=현재 선택주로 PageController 생성, 이탈 시 해제.
  void _setView(_CalView v) {
    setState(() {
      if (v == _CalView.week) {
        _weekAnchorMonday = _mondayOf(parseYmd(_sel));
        _weekCtrl?.dispose();
        _weekCtrl = PageController(initialPage: _weekAnchorPage);
      } else {
        _weekCtrl?.dispose();
        _weekCtrl = null;
      }
      _view = v;
    });
  }

  /// 오늘로 복귀: 표시 월·선택을 오늘로 맞춘다(주간이면 해당 주로 슬라이드).
  void _goToday() {
    setState(() {
      _month = DateTime(kToday.year, kToday.month);
      _sel = ymd(kToday);
    });
    final PageController? c = _weekCtrl;
    if (_view == _CalView.week && c != null && c.hasClients) {
      c.animateToPage(
        _pageForMonday(_mondayOf(kToday)),
        duration: _kWeekAnim,
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// PageView 페이지 변경 → 선택 요일을 유지하며 해당 주로 이동.
  void _onWeekPage(int page) {
    setState(() {
      final DateTime monday = _mondayForPage(page);
      final int weekdayOffset = parseYmd(_sel).weekday - 1; // 0=월..6=일
      _sel = ymd(addDays(monday, weekdayOffset));
    });
  }

  void _openItem(DayItem it) {
    if (it.task != null) {
      widget.onOpenTask(it.task!);
    } else if (it.event != null) {
      widget.onOpenEvent(it.event!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime d = parseYmd(_sel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: DkSegmented<_CalView>(
            full: true,
            value: _view,
            onChanged: _setView,
            options: const <DkSegment<_CalView>>[
              DkSegment<_CalView>(_CalView.month, '월간'),
              DkSegment<_CalView>(_CalView.week, '주간'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (_view == _CalView.month)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DkCard(
              padding: 16,
              child: _MonthGrid(
                month: _month,
                selected: _sel,
                tasks: widget.tasks,
                events: widget.events,
                externals: widget.externals,
                onSelect: (String k) => setState(() => _sel = k),
                onPrev: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
                onToday: _goToday,
              ),
            ),
          ),
        // 주간: 주 단위 네비(‹›) + 오늘. PageView 로 주를 페이징해 손가락으로 끌면 옆 주가
        // 따라오고(이전·다음 주가 겹쳐 보이며 슬라이드), ‹› 도 같은 슬라이드로 넘어간다.
        if (_view == _CalView.week) ...<Widget>[
          _CalNav(
            onPrev: () => _weekCtrl?.previousPage(
              duration: _kWeekAnim,
              curve: Curves.easeOutCubic,
            ),
            onNext: () => _weekCtrl?.nextPage(
              duration: _kWeekAnim,
              curve: Curves.easeOutCubic,
            ),
            onToday: _goToday,
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 76,
            child: PageView.builder(
              controller: _weekCtrl,
              onPageChanged: _onWeekPage,
              itemBuilder: (BuildContext _, int page) => WeekStrip(
                weekStart: _mondayForPage(page),
                selected: _sel,
                onSelect: (String k) => setState(() => _sel = k),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          // 섹션헤드의 '오늘' 버튼은 제거(각 뷰 네비로 이동) — 날짜 제목만.
          child: DkSectionHead(
            title: '${d.month}월 ${d.day}일 (${kWeekdaysKo[d.weekday % 7]})',
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
        // FAB 가림 방지용 하단 여백(하단 출처 로고 범례는 제거 — 출처 구분은
        // 아래 일정 행의 브랜드 아이콘으로만 한다).
        const SizedBox(height: 120),
      ],
    );
  }
}

/// 캘린더 출처 → 브랜드 마크 키(`DkBrandMark`). app 출처는 이어서 로고.
String _brandKey(DkSource s) => switch (s) {
  DkSource.app => 'ieoseo',
  DkSource.google => 'google',
  DkSource.apple => 'apple',
  DkSource.notion => 'notion',
};

/// '오늘' 칩 버튼(primary-subtle). 월/주/일 뷰 네비에서 공유한다.
Widget _todayChip(DkTokens t, VoidCallback onTap) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: t.primarySubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '오늘',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: t.primary,
        ),
      ),
    ),
  );
}

/// 주간 뷰 네비: 이전 ‹ · 오늘 · 다음 ›.
class _CalNav extends StatelessWidget {
  const _CalNav({
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          _arrow(t, const ValueKey<String>('calnav-prev'), 'chevL', onPrev),
          Expanded(child: Center(child: _todayChip(t, onToday))),
          _arrow(t, const ValueKey<String>('calnav-next'), 'chevR', onNext),
        ],
      ),
    );
  }

  Widget _arrow(DkTokens t, Key key, String icon, VoidCallback onTap) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.bgSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DkIcon(icon, size: 18, color: t.fgMuted, strokeWidth: 2.2),
      ),
    );
  }
}

/// 월 그리드. 상단에 이전/다음 달 이동 헤더. 셀에 출처 점 최대 3개.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.tasks,
    required this.events,
    required this.externals,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  /// 표시할 월(해당 월의 1일 등 아무 날이어도 됨 — year/month 만 사용).
  final DateTime month;
  final String selected;
  final List<DkTask> tasks;
  final List<DkEvent> events;
  final List<DkExternal> externals;
  final ValueChanged<String> onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  Widget _navArrow(DkTokens t, Key key, String icon, VoidCallback onTap) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.bgSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DkIcon(icon, size: 18, color: t.fgMuted, strokeWidth: 2.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final List<int?> cells = monthCells(month.year, month.month);
    final String todayKey = ymd(kToday);
    final String monthPrefix =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';

    return Column(
      children: <Widget>[
        // 월 이동 헤더(이전 ‹ · YYYY년 M월 · 다음 ›).
        Row(
          children: <Widget>[
            _navArrow(t, const ValueKey<String>('cal-prev'), 'chevL', onPrev),
            Expanded(
              child: Center(
                child: Text(
                  '${month.year}년 ${kMonthsKo[month.month - 1]}',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: t.fgStrong,
                  ),
                ),
              ),
            ),
            _todayChip(t, onToday),
            const SizedBox(width: 8),
            _navArrow(t, const ValueKey<String>('cal-next'), 'chevR', onNext),
          ],
        ),
        const SizedBox(height: 12),
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
                Expanded(
                  child: _cell(
                    t,
                    cells[row * 7 + col],
                    col,
                    todayKey,
                    monthPrefix,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(
    DkTokens t,
    int? day,
    int dow,
    String todayKey,
    String monthPrefix,
  ) {
    if (day == null) return const SizedBox(height: 45);
    final String key = '$monthPrefix-${day.toString().padLeft(2, '0')}';
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
  // 이어서 출처(태스크·이벤트)는 카테고리별 색이 아니라 단일 이어서 색으로 통일한다.
  // (범례의 '이어서 = 파랑'과 일치 — 한 날에 카테고리가 섞여도 색이 갈리지 않게.)
  return t.primary;
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
        ? (it.event != null ? ddayInfo(it.event!).label : 'D-Day')
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
                        // 외부 연동 캘린더(Google/Apple/Notion)만 브랜드 아이콘으로 출처 표시.
                        // (이어서 출처는 표시 안 함, '읽기전용' 텍스트·색점 제거.)
                        DkBrandMark(brand: _brandKey(it.source), size: 16),
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
