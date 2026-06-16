import 'package:flutter/widgets.dart';

import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_button.dart';
import '../../widgets/dk_choice_chip.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_segmented.dart';
import '../../widgets/dk_sheet.dart';
import 'date_picker_sheet.dart';
import 'sheet_fields.dart';

const List<int> _minOptions = <int>[15, 30, 45, 60, 90, 120];

/// 태스크 추가/상세 시트 본문. 프로토타입 `TaskSheet`.
class TaskSheetBody extends StatefulWidget {
  const TaskSheetBody({
    super.key,
    this.task,
    required this.isNew,
    required this.onClose,
    this.onToggle,
    this.onDelete,
    this.onFocus,
    this.onSubmit,
    required this.onToast,
  });

  final DkTask? task;
  final bool isNew;
  final VoidCallback onClose;
  final ValueChanged<DkTask>? onToggle;
  final ValueChanged<DkTask>? onDelete;
  final ValueChanged<DkTask>? onFocus;

  /// 추가/저장 제출. 폼 값으로 만든 초안(신규는 id 빈 문자열)을 전달한다.
  final ValueChanged<DkTask>? onSubmit;
  final void Function(String message, String icon, String tone) onToast;

  @override
  State<TaskSheetBody> createState() => _TaskSheetBodyState();
}

enum _Repeat { none, weekly, monthly, yearly }

/// 예정일(YYYY-MM-DD)이 속한 요일(`DateTime.weekday` 월=1 … 일=7). 파싱 실패 시 kToday 기준.
/// 주간 반복 기본값은 임의 프리셋(과거 월·수·금)이 아니라 "그 태스크의 요일" 하나다.
int _weekdayOfYmd(String s) => (DateTime.tryParse(s.trim()) ?? kToday).weekday;

DkRecurrenceFreq _toFreq(_Repeat r) => switch (r) {
  _Repeat.none => DkRecurrenceFreq.none,
  _Repeat.weekly => DkRecurrenceFreq.weekly,
  _Repeat.monthly => DkRecurrenceFreq.monthly,
  _Repeat.yearly => DkRecurrenceFreq.yearly,
};

_Repeat _fromFreq(DkRecurrenceFreq f) => switch (f) {
  DkRecurrenceFreq.none => _Repeat.none,
  DkRecurrenceFreq.weekly => _Repeat.weekly,
  DkRecurrenceFreq.monthly => _Repeat.monthly,
  DkRecurrenceFreq.yearly => _Repeat.yearly,
};

class _TaskSheetBodyState extends State<TaskSheetBody> {
  late int _mins = widget.task?.mins ?? 30;
  late String _cat = widget.task?.category ?? '공부';
  late _Repeat _repeat = _fromFreq(
    widget.task?.recurrence.frequency ?? DkRecurrenceFreq.none,
  );

  /// 주간 반복 선택 요일(`DateTime.weekday` 월=1 … 일=7). 기존 규칙이 있으면 복원,
  /// 없으면 예정일의 요일 하나를 기본 선택(임의 월·수·금 프리셋 제거).
  late final Set<int> _weeklyDays =
      (widget.task?.recurrence.weeklyDays.isNotEmpty ?? false)
      ? <int>{...widget.task!.recurrence.weeklyDays}
      : <int>{_weekdayOfYmd(widget.task?.date ?? '2026-06-01')};

  late final TextEditingController _title = TextEditingController(
    text: widget.task?.title ?? '',
  );
  late final TextEditingController _date = TextEditingController(
    text: widget.task?.date ?? '2026-06-01',
  );

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    super.dispose();
  }

  /// 현재 폼 상태로 만든 반복 규칙. 주간은 선택 요일을, 월간/연간은 예정일에서 일자/월일을 끌어온다.
  DkRecurrence _recurrence() {
    final DkRecurrenceFreq freq = _toFreq(_repeat);
    final DateTime? d = DateTime.tryParse(_date.text.trim());
    return switch (freq) {
      DkRecurrenceFreq.none => DkRecurrence.none,
      DkRecurrenceFreq.weekly => DkRecurrence(
        frequency: DkRecurrenceFreq.weekly,
        weeklyDays: _weeklyDays.isEmpty
            ? <int>{_weekdayOfYmd(_date.text)}
            : _weeklyDays,
      ),
      DkRecurrenceFreq.monthly => DkRecurrence(
        frequency: DkRecurrenceFreq.monthly,
        monthDay: d?.day ?? 1,
      ),
      DkRecurrenceFreq.yearly => DkRecurrence(
        frequency: DkRecurrenceFreq.yearly,
        yearMonth: d?.month ?? 1,
        yearDay: d?.day ?? 1,
      ),
    };
  }

  /// 폼 값으로 만든 초안(신규는 id 빈 문자열, 상태는 server 권위라 pending).
  DkTask _draft() => DkTask(
    id: widget.task?.id ?? '',
    title: _title.text.trim(),
    mins: _mins,
    date: _date.text.trim(),
    state: widget.task?.state ?? DkTaskState.pending,
    category: _cat,
    eventId: widget.task?.eventId,
    recurrence: _recurrence(),
  );

  /// 예정일 달력 시트를 열어 선택값을 _date 에 반영한다(이슈 #57).
  Future<void> _pickDate() async {
    final String? picked = await showDkDatePicker(context, initial: _date.text);
    if (picked != null && mounted) {
      setState(() => _date.text = picked);
    }
  }

  /// 예정일 표시 필드. 탭하면 달력 피커를 연다(텍스트 직접 입력 대신).
  Widget _dateField(DkTokens t) {
    return GestureDetector(
      key: const ValueKey<String>('task-date-field'),
      behavior: HitTestBehavior.opaque,
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border, width: 1.5),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                fmtDate(_date.text),
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: t.fg,
                ),
              ),
            ),
            DkIcon('calendar', size: 18, color: t.fgMuted, strokeWidth: 2),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final DkTask? task = widget.task;
    final bool carried =
        !widget.isNew &&
        task != null &&
        (task.state == DkTaskState.carried ||
            task.state == DkTaskState.overdue);
    final bool done = task?.state == DkTaskState.done;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (carried)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: t.infoSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                DkIcon('repeat', size: 17, color: t.infoFg, strokeWidth: 2),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '${task.fromLabel}에서 옮겨온 할 일이에요',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: t.infoFg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        DkField(
          label: '제목',
          child: DkTextInput(
            controller: _title,
            placeholder: '예) 정처기 실기 기출 1회',
          ),
        ),
        DkField(
          label: '예상 소요시간',
          hint: "자정까지 못 하면 이 시간만큼 '미룬 시간'으로 쌓여요.",
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[for (final int v in _minOptions) _minChip(v)],
          ),
        ),
        DkField(
          label: '카테고리',
          child: DkCategoryPills(
            value: _cat,
            onChanged: (String c) => setState(() => _cat = c),
          ),
        ),
        DkField(label: '예정일', child: _dateField(t)),
        DkField(
          label: '반복',
          child: DkSegmented<_Repeat>(
            full: true,
            value: _repeat,
            onChanged: (_Repeat r) => setState(() => _repeat = r),
            options: const <DkSegment<_Repeat>>[
              DkSegment<_Repeat>(_Repeat.none, '없음'),
              DkSegment<_Repeat>(_Repeat.weekly, '주간'),
              DkSegment<_Repeat>(_Repeat.monthly, '월간'),
              DkSegment<_Repeat>(_Repeat.yearly, '연간'),
            ],
          ),
        ),
        if (_repeat == _Repeat.weekly)
          DkField(
            label: '반복 요일',
            child: Row(
              children: <Widget>[for (int i = 0; i < 7; i++) _weekdayChip(i)],
            ),
          ),
        if (!widget.isNew && task != null) ...<Widget>[
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: DkButton(
                  size: DkButtonSize.lg,
                  variant: DkButtonVariant.outline,
                  full: true,
                  onPressed: () {
                    widget.onFocus?.call(task);
                    widget.onClose();
                  },
                  leading: DkIcon(
                    'focus',
                    size: 19,
                    color: t.fg,
                    strokeWidth: 2,
                  ),
                  child: const Text('집중 시작'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DkButton(
                  size: DkButtonSize.lg,
                  variant: DkButtonVariant.outline,
                  full: true,
                  onPressed: () {
                    widget.onToast('가장 여유 있는 날로 옮겼어요', 'repeat', 'info');
                    widget.onClose();
                  },
                  leading: DkIcon(
                    'repeat',
                    size: 18,
                    color: t.fg,
                    strokeWidth: 2,
                  ),
                  child: const Text('날짜 옮기기'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _stickyActions(t, task, done),
      ],
    );
  }

  Widget _minChip(int v) {
    return DkChoiceChip(
      label: fmtMins(v),
      selected: v == _mins,
      onTap: () => setState(() => _mins = v),
    );
  }

  /// 칩 인덱스 i(일=0 … 토=6, kWeekdaysKo 순서) → `DateTime.weekday`(월=1 … 일=7).
  int _weekdayNum(int i) => i == 0 ? 7 : i;

  Widget _weekdayChip(int i) {
    final int num = _weekdayNum(i);
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
        child: AspectRatio(
          aspectRatio: 1,
          child: DkChoiceChip(
            label: kWeekdaysKo[i],
            selected: _weeklyDays.contains(num),
            fontSize: 13,
            expand: true,
            onTap: () => setState(() {
              if (!_weeklyDays.add(num)) _weeklyDays.remove(num);
            }),
          ),
        ),
      ),
    );
  }

  Widget _stickyActions(DkTokens t, DkTask? task, bool done) {
    if (widget.isNew || task == null) {
      return DkButton(
        size: DkButtonSize.lg,
        full: true,
        onPressed: () {
          widget.onSubmit?.call(_draft());
          widget.onClose();
        },
        child: const Text('추가하기'),
      );
    }
    return Row(
      children: <Widget>[
        DkButton(
          size: DkButtonSize.lg,
          variant: DkButtonVariant.danger,
          onPressed: () {
            widget.onDelete?.call(task);
            widget.onClose();
          },
          leading: DkIcon('trash', size: 18, color: t.danger, strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DkButton(
            size: DkButtonSize.lg,
            variant: done ? DkButtonVariant.outline : DkButtonVariant.primary,
            full: true,
            onPressed: () {
              widget.onToggle?.call(task);
              widget.onClose();
            },
            leading: DkIcon(
              'check',
              size: 19,
              color: done ? t.fg : const Color(0xFFFFFFFF),
              strokeWidth: 2.4,
            ),
            child: Text(done ? '완료 취소' : '완료 처리'),
          ),
        ),
      ],
    );
  }
}

/// 태스크 시트를 띄운다.
Future<void> showTaskSheet(
  BuildContext context, {
  DkTask? task,
  required bool isNew,
  ValueChanged<DkTask>? onToggle,
  ValueChanged<DkTask>? onDelete,
  ValueChanged<DkTask>? onFocus,
  ValueChanged<DkTask>? onSubmit,
  required void Function(String message, String icon, String tone) onToast,
}) {
  return showDkSheet<void>(
    context,
    title: isNew ? '태스크 추가' : '태스크 상세',
    full: true,
    child: Builder(
      builder: (BuildContext sheetContext) => TaskSheetBody(
        task: task,
        isNew: isNew,
        onClose: () => Navigator.of(sheetContext).maybePop(),
        onToggle: onToggle,
        onDelete: onDelete,
        onFocus: onFocus,
        onSubmit: onSubmit,
        onToast: onToast,
      ),
    ),
  );
}
