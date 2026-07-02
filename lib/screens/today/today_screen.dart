import 'package:flutter/widgets.dart';

import '../../data/dday.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../parts/app_header.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_badge.dart';
import '../../widgets/dk_card.dart';
import '../../widgets/dk_choice_chip.dart';
import '../../widgets/dk_empty.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_section.dart';
import 'today_logic.dart';

/// 오늘 탭. D-Day 중심.
///
/// 인사 헤더(ink) → 다가오는 일정(임박순 D-Day 목록) → 미룬 시간 넛지.
/// 오늘 할 일 목록은 "플랜 > 할 일" 탭으로 일원화했다(이슈: 오늘 탭 D-Day 전환).
/// 오늘 날짜를 "M월 d일 X요일"(한국어)로 포맷한다.
String _todayLabel() {
  final DateTime now = DateTime.now();
  const List<String> weekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
  return '${now.month}월 ${now.day}일 ${weekdays[now.weekday - 1]}요일';
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.events,
    required this.debts,
    required this.onOpenEvent,
    required this.onBell,
    required this.onOpenDebt,
    this.unread = 0,
  });

  final List<DkEvent> events;
  final List<DkDebt> debts;

  /// 안 읽은 알림 수(헤더 벨 점 표시용, 이슈 #46).
  final int unread;
  final ValueChanged<DkEvent> onOpenEvent;
  final VoidCallback onBell;
  final VoidCallback onOpenDebt;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  /// 선택한 카테고리 필터(null=전체, 세션 한정 — 저장 안 함, #163).
  String? _category;

  /// 이벤트에 실제로 등장하는 카테고리를 표준 순서(kCategoryIcon)로, 미매핑은 뒤에 붙여 나열.
  List<String> _presentCategories(List<DkEvent> events) {
    final Set<String> present = events.map((DkEvent e) => e.category).toSet();
    final List<String> ordered = <String>[
      for (final String c in kCategoryIcon.keys)
        if (present.contains(c)) c,
    ];
    final List<String> extras =
        present.where((String c) => !kCategoryIcon.containsKey(c)).toList()
          ..sort();
    return <String>[...ordered, ...extras];
  }

  @override
  Widget build(BuildContext context) {
    // 종료(완료) 처리한 이벤트는 홈에서 숨긴다(미종료는 D+ 로 계속 노출). FRD 5.1.
    final List<DkEvent> live = widget.events
        .where((DkEvent e) => !e.completed)
        .toList(growable: false);
    final List<String> categories = _presentCategories(live);
    // 선택 카테고리가 목록에서 사라지면(데이터 변경) 전체로 되돌린다.
    final String? active = (_category != null && categories.contains(_category))
        ? _category
        : null;
    final List<DkEvent> filtered = active == null
        ? live
        : live.where((DkEvent e) => e.category == active).toList();
    final List<DkEvent> ordered = ddayOrdered(filtered);

    final int debtTotal = widget.debts.fold(0, (int s, DkDebt d) => s + d.mins);
    final int debtOverdue = widget.debts
        .where((DkDebt d) => d.status == DkDebtStatus.overdue)
        .length;

    // 카테고리가 2개 이상일 때만 필터 칩을 노출한다(1개면 필터 의미 없음).
    final bool showFilter = categories.length >= 2;

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: <Widget>[
        // 다른 탭과 동일한 AppHeader — 좌측 상단에 오늘 날짜(제목), 우측 상단에 알림 벨.
        // ink 인사 카드는 제거(요청)하고 헤더 위치/벨을 4개 탭에서 통일한다.
        AppHeader(
          title: _todayLabel(),
          unread: widget.unread,
          onBell: widget.onBell,
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: DkSectionLabel('다가오는 일정'),
        ),
        if (showFilter) ...<Widget>[
          _CategoryFilter(
            categories: categories,
            selected: active,
            onSelect: (String? c) => setState(() => _category = c),
          ),
          const SizedBox(height: 14),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ordered.isEmpty
              ? DkEmpty(
                  icon: 'target',
                  title: active == null ? '다가오는 일정이 없어요' : '$active 일정이 없어요',
                  body: active == null
                      ? '플랜에서 D-Day 일정을 추가하면 임박한 순서로 모아 보여드려요.'
                      : '다른 카테고리를 선택하거나 전체로 보세요.',
                )
              : Column(
                  children: <Widget>[
                    for (int i = 0; i < ordered.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 10),
                      _DdayRow(event: ordered[i], onOpen: widget.onOpenEvent),
                    ],
                  ],
                ),
        ),
        if (debtTotal > 0) ...<Widget>[
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _DebtNudge(
              total: debtTotal,
              overdueCount: debtOverdue,
              onTap: widget.onOpenDebt,
            ),
          ),
        ],
      ],
    );
  }
}

/// 홈 상단 카테고리 필터 칩 줄(전체 + 등장 카테고리, 단일 선택, #163).
class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: <Widget>[
          DkChoiceChip(
            label: '전체',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final String c in categories) ...<Widget>[
            const SizedBox(width: 8),
            DkChoiceChip(
              label: c,
              selected: selected == c,
              onTap: () => onSelect(c),
            ),
          ],
        ],
      ),
    );
  }
}

/// 다가오는 일정 행(임박순 D-Day). 좌측 hue 아이콘 + 제목·카테고리, 우측 큰 D-값.
class _DdayRow extends StatelessWidget {
  const _DdayRow({required this.event, required this.onOpen});

  final DkEvent event;
  final ValueChanged<DkEvent> onOpen;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final DkDdayInfo info = ddayInfo(event);
    final DkHue h = DkHue.byName(event.color);
    // 진행률 뷰라도 마감이 지나면 %가 아니라 '마감 D+N'(카운트다운과 수렴)으로 보인다.
    final String big = info.type == DkEventType.progress
        ? (info.urgency == DkUrgency.past
              ? info.label.replaceAll('마감 ', '')
              : '${info.pct}%')
        : info.label.replaceAll('마감 ', '').replaceAll('시작 ', '');

    return GestureDetector(
      onTap: () => onOpen(event),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.borderSubtle),
          boxShadow: t.shadows.s1,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: h.subtle,
                borderRadius: BorderRadius.circular(12),
              ),
              // 카테고리에 맞는 아이콘(자격증→graduationCap 등). 미매핑은 target 폴백.
              child: DkIcon(
                kCategoryIcon[event.category] ?? 'target',
                size: 19,
                color: h.color,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: t.fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.category,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: h.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 실제 날짜(단일=목표일, 기간=시작~종료)를 보여 D-값의 기준을 명확히 한다(#157).
                  Text(
                    eventDateLabel(event),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.12,
                      color: t.fgSubtle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              big,
              style: TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.72,
                // 종료(D+)는 강조 해제(회색), 임박은 danger, 그 외 기본.
                color: switch (info.urgency) {
                  DkUrgency.high => t.danger,
                  DkUrgency.past => t.fgDisabled,
                  _ => t.fgStrong,
                },
              ),
            ),
          ],
        ),
      ),
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
