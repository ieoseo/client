import 'package:flutter/widgets.dart';

import '../../data/dday.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../parts/app_header.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_badge.dart';
import '../../widgets/dk_card.dart';
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

class TodayScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // 종료(완료) 처리한 이벤트는 홈에서 숨긴다(미종료는 D+ 로 계속 노출). FRD 5.1.
    final List<DkEvent> ordered = ddayOrdered(
      events.where((DkEvent e) => !e.completed).toList(growable: false),
    );
    final int debtTotal = debts.fold(0, (int s, DkDebt d) => s + d.mins);
    final int debtOverdue = debts
        .where((DkDebt d) => d.status == DkDebtStatus.overdue)
        .length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: <Widget>[
        // 다른 탭과 동일한 AppHeader — 좌측 상단에 오늘 날짜(제목), 우측 상단에 알림 벨.
        // ink 인사 카드는 제거(요청)하고 헤더 위치/벨을 4개 탭에서 통일한다.
        AppHeader(title: _todayLabel(), unread: unread, onBell: onBell),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: DkSectionLabel('다가오는 일정'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ordered.isEmpty
              ? const DkEmpty(
                  icon: 'target',
                  title: '다가오는 일정이 없어요',
                  body: '플랜에서 D-Day 일정을 추가하면 임박한 순서로 모아 보여드려요.',
                )
              : Column(
                  children: <Widget>[
                    for (int i = 0; i < ordered.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 10),
                      _DdayRow(event: ordered[i], onOpen: onOpenEvent),
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
              onTap: onOpenDebt,
            ),
          ),
        ],
      ],
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
