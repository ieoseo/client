import 'package:flutter/widgets.dart';

import '../../data/models.dart';
import '../../widgets/dk_segmented.dart';
import '../../widgets/dk_sheet.dart';
import 'event_sheet.dart';
import 'task_sheet.dart';

/// 추가 시트의 상단 탭(무엇을 추가할지). 앱은 D-Day 중심이라 event 를 앞에 둔다(#158).
enum _AddTab { event, task }

/// 통합 추가 시트. 하단 + 로 열며, **상단 세그먼트 [D-Day 일정 | 할 일]** 로 한 시트 안에서
/// 종류를 전환한다(별도 선택지 시트 없이). 태스크(할 일)와 이벤트(D-Day)는 별개 도메인이라
/// 폼이 다르므로, 선택한 탭에 맞는 본문(`TaskSheetBody`/`EventSheetBody`)을 보여준다.
Future<void> showAddSheet(
  BuildContext context, {
  required ValueChanged<DkTask> onAddTask,
  required ValueChanged<DkEvent> onAddEvent,
  required void Function(String message, String icon, String tone) onToast,
}) {
  return showDkSheet<void>(
    context,
    title: '추가',
    full: true,
    child: Builder(
      builder: (BuildContext sheetContext) => _AddSheetBody(
        onClose: () => Navigator.of(sheetContext).maybePop(),
        onAddTask: onAddTask,
        onAddEvent: onAddEvent,
        onToast: onToast,
      ),
    ),
  );
}

class _AddSheetBody extends StatefulWidget {
  const _AddSheetBody({
    required this.onClose,
    required this.onAddTask,
    required this.onAddEvent,
    required this.onToast,
  });

  final VoidCallback onClose;
  final ValueChanged<DkTask> onAddTask;
  final ValueChanged<DkEvent> onAddEvent;
  final void Function(String message, String icon, String tone) onToast;

  @override
  State<_AddSheetBody> createState() => _AddSheetBodyState();
}

class _AddSheetBodyState extends State<_AddSheetBody> {
  _AddTab _tab = _AddTab.event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DkSegmented<_AddTab>(
          full: true,
          value: _tab,
          onChanged: (_AddTab v) => setState(() => _tab = v),
          options: const <DkSegment<_AddTab>>[
            DkSegment<_AddTab>(_AddTab.event, 'D-Day 일정'),
            DkSegment<_AddTab>(_AddTab.task, '할 일'),
          ],
        ),
        const SizedBox(height: 16),
        // 탭별 폼. 신규 추가 전용이라 isNew=true(편집은 각 항목 탭 시 전용 시트로).
        if (_tab == _AddTab.task)
          TaskSheetBody(
            isNew: true,
            onClose: widget.onClose,
            onSubmit: widget.onAddTask,
            onToast: widget.onToast,
          )
        else
          EventSheetBody(
            isNew: true,
            onClose: widget.onClose,
            onSubmit: widget.onAddEvent,
          ),
      ],
    );
  }
}
