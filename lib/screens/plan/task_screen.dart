import 'package:flutter/widgets.dart';

import '../../data/format.dart';
import '../../data/models.dart';
import '../../parts/metric_bar.dart';
import '../../parts/task_row.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_badge.dart';
import '../../widgets/dk_card.dart';
import '../../widgets/dk_empty.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_section.dart';
import 'week_strip.dart';

/// 할 일 뷰. 프로토타입 `TaskScreen`(embedded).
///
/// WeekStrip → MetricBar → 미룬 시간 콜아웃 → 옮겨온 할 일 → 당일 할 일 리스트.
class TaskScreen extends StatefulWidget {
  const TaskScreen({
    super.key,
    required this.tasks,
    required this.summary,
    required this.debtTotal,
    required this.debtOverdue,
    required this.onToggle,
    required this.onOpenTask,
    required this.onAddTask,
    required this.onOpenDebt,
  });

  final List<DkTask> tasks;
  final DkWeekSummary summary;
  final int debtTotal;
  final int debtOverdue;
  final ValueChanged<DkTask> onToggle;
  final ValueChanged<DkTask> onOpenTask;
  final VoidCallback onAddTask;
  final VoidCallback onOpenDebt;

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String _day = ymd(kToday);

  @override
  Widget build(BuildContext context) {
    final List<DkTask> dayTasks = widget.tasks
        .where((DkTask t) => t.date == _day)
        .toList();
    final List<DkTask> carried = widget.tasks
        .where(
          (DkTask t) =>
              t.state == DkTaskState.carried || t.state == DkTaskState.overdue,
        )
        .toList();
    final bool isToday = _day == ymd(kToday);
    final DateTime d = parseYmd(_day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 4),
        WeekStrip(
          selected: _day,
          onSelect: (String k) => setState(() => _day = k),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MetricBar(summary: widget.summary),
        ),
        const SizedBox(height: 22),
        if (widget.debtTotal > 0) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _debtCallout(context),
          ),
          const SizedBox(height: 22),
        ],
        if (carried.isNotEmpty) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: DkSectionHead(
              title: '옮겨온 할 일',
              action: '미룬 시간',
              onAction: widget.onOpenDebt,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < carried.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 8),
                  TaskRow(
                    task: carried[i],
                    onToggle: widget.onToggle,
                    onOpen: widget.onOpenTask,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          // 추가 진입점은 하단 FAB(+)·빈 상태 CTA 로 충분해, 헤더의 중복 '추가' 는 제거.
          child: DkSectionHead(
            title: isToday
                ? '오늘의 할 일'
                : '${d.day}일 (${kWeekdaysKo[d.weekday % 7]}) 할 일',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          child: dayTasks.isEmpty
              ? DkEmpty(
                  icon: 'tasks',
                  title: '이 날은 비어 있어요',
                  body: '할 일을 추가하면 예상 시간만큼 하루 계획에 반영돼요.',
                  cta: '태스크 추가',
                  onCta: widget.onAddTask,
                )
              : Column(
                  children: <Widget>[
                    for (int i = 0; i < dayTasks.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 8),
                      TaskRow(
                        task: dayTasks[i],
                        onToggle: widget.onToggle,
                        onOpen: widget.onOpenTask,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _debtCallout(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return DkCard(
      padding: 0,
      onTap: widget.onOpenDebt,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.warningSubtle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DkIcon(
                'carryForward',
                size: 24,
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
                      if (widget.debtOverdue > 0) ...<Widget>[
                        const SizedBox(width: 6),
                        DkBadge(
                          '계속 밀림 ${widget.debtOverdue}건',
                          tone: DkTone.danger,
                        ),
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
                          text: fmtMins(widget.debtTotal),
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
