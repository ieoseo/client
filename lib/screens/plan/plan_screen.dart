import 'package:flutter/widgets.dart';

import '../../data/models.dart';
import '../../parts/app_header.dart';
import '../../widgets/dk_segmented.dart';
import 'calendar_screen.dart';
import 'task_screen.dart';

/// 플랜 탭. 프로토타입 `PlanScreen`.
///
/// AppHeader(추가 버튼) + 캘린더↔할 일 세그먼트 토글 → CalendarScreen/TaskScreen.
class PlanScreen extends StatefulWidget {
  const PlanScreen({
    super.key,
    required this.tasks,
    required this.events,
    required this.externals,
    required this.summary,
    required this.debtTotal,
    required this.debtOverdue,
    required this.onToggle,
    required this.onOpenTask,
    required this.onOpenEvent,
    required this.onAddTask,
    required this.onAddEvent,
    required this.onOpenDebt,
    required this.onBell,
    this.unread = 0,
  });

  final List<DkTask> tasks;
  final List<DkEvent> events;
  final List<DkExternal> externals;
  final DkWeekSummary summary;
  final int debtTotal;
  final int debtOverdue;

  /// 안 읽은 알림 수(헤더 벨 점 표시용, 이슈 #46).
  final int unread;
  final ValueChanged<DkTask> onToggle;
  final ValueChanged<DkTask> onOpenTask;
  final ValueChanged<DkEvent> onOpenEvent;
  final VoidCallback onAddTask;
  final VoidCallback onAddEvent;
  final VoidCallback onOpenDebt;
  final VoidCallback onBell;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

enum _PlanView { calendar, tasks }

class _PlanScreenState extends State<PlanScreen> {
  _PlanView _view = _PlanView.calendar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        AppHeader(
          title: '플랜',
          subtitle: '일정과 할 일을 한 곳에서',
          unread: widget.unread,
          onBell: widget.onBell,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: DkSegmented<_PlanView>(
            full: true,
            value: _view,
            onChanged: (_PlanView v) => setState(() => _view = v),
            options: const <DkSegment<_PlanView>>[
              DkSegment<_PlanView>(_PlanView.calendar, '캘린더'),
              DkSegment<_PlanView>(_PlanView.tasks, '할 일'),
            ],
          ),
        ),
        if (_view == _PlanView.calendar)
          CalendarScreen(
            tasks: widget.tasks,
            events: widget.events,
            externals: widget.externals,
            onOpenTask: widget.onOpenTask,
            onOpenEvent: widget.onOpenEvent,
          )
        else
          TaskScreen(
            tasks: widget.tasks,
            summary: widget.summary,
            debtTotal: widget.debtTotal,
            debtOverdue: widget.debtOverdue,
            onToggle: widget.onToggle,
            onOpenTask: widget.onOpenTask,
            onAddTask: widget.onAddTask,
            onOpenDebt: widget.onOpenDebt,
          ),
      ],
    );
  }
}
