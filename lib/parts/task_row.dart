import 'package:flutter/widgets.dart';

import '../data/format.dart';
import '../data/meta.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/dk_badge.dart';
import '../widgets/dk_icon.dart';

/// 완료 체크박스 26 radius 9. done이면 success 채움 + check.
class DkCheckbox extends StatelessWidget {
  const DkCheckbox({super.key, required this.done, this.onTap, this.size = 26});

  final bool done;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? t.success : const Color(0x00000000),
          borderRadius: BorderRadius.circular(9),
          border: done ? null : Border.all(color: t.borderStrong, width: 2),
        ),
        child: done
            ? const DkIcon(
                'check',
                size: 16,
                color: Color(0xFFFFFFFF),
                strokeWidth: 3,
              )
            : null,
      ),
    );
  }
}

/// 할 일 행. 프로토타입 `TaskRow`.
///
/// radius 16, padding 13×14, shadow-1. 체크 26 + 제목(done 취소선) +
/// 메타(clock+시간 · 점 · 카테고리색+이름 · CARRIED면 "{from}에서 옮겨옴") +
/// (TODAY/PENDING 외) 상태 뱃지 + eventId면 target 아이콘.
class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    this.onToggle,
    this.onOpen,
    this.showState = true,
  });

  final DkTask task;
  final ValueChanged<DkTask>? onToggle;
  final ValueChanged<DkTask>? onOpen;
  final bool showState;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final bool done = task.state == DkTaskState.done;
    final DkStateMeta st = taskStateMeta(task.state);
    final DkHue h = categoryHue(task.category);
    final bool showBadge =
        showState &&
        task.state != DkTaskState.today &&
        task.state != DkTaskState.pending;

    return GestureDetector(
      onTap: onOpen == null ? null : () => onOpen!(task),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.borderSubtle),
          boxShadow: t.shadows.s1,
        ),
        child: Row(
          children: <Widget>[
            DkCheckbox(
              done: done,
              onTap: onToggle == null ? null : () => onToggle!(task),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
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
                  const SizedBox(height: 3),
                  _meta(t, h),
                ],
              ),
            ),
            if (task.recurrence.isRecurring) ...<Widget>[
              const SizedBox(width: 8),
              DkIcon(
                'repeat',
                key: const ValueKey<String>('task-recurrence-badge'),
                size: 16,
                color: t.infoFg,
                strokeWidth: 2,
              ),
            ],
            if (showBadge) ...<Widget>[
              const SizedBox(width: 8),
              DkBadge(st.label, tone: st.tone),
            ],
            if (task.eventId != null) ...<Widget>[
              const SizedBox(width: 8),
              DkIcon('target', size: 16, color: t.fgDisabled),
            ],
          ],
        ),
      ),
    );
  }

  Widget _meta(DkTokens t, DkHue h) {
    return Row(
      children: <Widget>[
        DkIcon('clock', size: 13, color: t.fgSubtle, strokeWidth: 2),
        const SizedBox(width: 3),
        Text(
          fmtMins(task.mins),
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: t.fgSubtle,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: t.borderStrong,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: h.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            task.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: h.color,
            ),
          ),
        ),
        if (task.state == DkTaskState.carried && task.fromLabel != null)
          Flexible(
            child: Text(
              ' · ${task.fromLabel}에서 옮겨옴',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: t.infoFg,
              ),
            ),
          ),
      ],
    );
  }
}
