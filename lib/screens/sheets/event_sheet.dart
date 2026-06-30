import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../data/dday.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_button.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_segmented.dart';
import '../../widgets/dk_sheet.dart';
import '../me/settings_section.dart';
import 'date_picker_sheet.dart';
import 'date_range_picker_sheet.dart';
import 'sheet_fields.dart';

/// 이벤트 추가/상세 시트 본문. 프로토타입 `EventSheet`.
class EventSheetBody extends StatefulWidget {
  const EventSheetBody({
    super.key,
    this.event,
    required this.isNew,
    required this.onClose,
    this.onDelete,
    this.onSubmit,
    this.onComplete,
  });

  final DkEvent? event;
  final bool isNew;
  final VoidCallback onClose;
  final ValueChanged<DkEvent>? onDelete;

  /// 추가/저장 제출. 폼 값으로 만든 초안(신규는 id 빈 문자열)을 전달한다.
  final ValueChanged<DkEvent>? onSubmit;

  /// 종료(완료) 토글. 현재 이벤트를 전달하면 호출부가 `completed` 에 따라 종료/재개한다.
  final ValueChanged<DkEvent>? onComplete;

  @override
  State<EventSheetBody> createState() => _EventSheetBodyState();
}

class _EventSheetBodyState extends State<EventSheetBody> {
  late DkEventType _type = widget.event?.type ?? DkEventType.single;
  late String _cat = widget.event?.category ?? '자격증';
  bool _remind = true;
  late final TextEditingController _title = TextEditingController(
    text: widget.event?.title ?? '',
  );
  // 기본값은 오늘 기준 상대(과거 고정 날짜 제거): 목표일 4주 뒤, 기간 오늘~5일.
  late final TextEditingController _date = TextEditingController(
    text: widget.event?.date ?? ymd(addDays(kToday, 28)),
  );
  late final TextEditingController _start = TextEditingController(
    text: widget.event?.start ?? ymd(kToday),
  );
  late final TextEditingController _end = TextEditingController(
    text: widget.event?.end ?? ymd(addDays(kToday, 4)),
  );
  late final TextEditingController _memo = TextEditingController(
    text: widget.event?.memo ?? '',
  );

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    _start.dispose();
    _end.dispose();
    _memo.dispose();
    super.dispose();
  }

  /// 폼 값으로 만든 초안(신규는 id 빈 문자열). 색은 기존 값/기본 hue.
  DkEvent _draft() {
    final bool single = _type == DkEventType.single;
    return DkEvent(
      id: widget.event?.id ?? '',
      type: _type,
      title: _title.text.trim(),
      category: _cat,
      date: single ? _date.text.trim() : null,
      start: single ? null : _start.text.trim(),
      end: single ? null : _end.text.trim(),
      // 핀(홈 고정) 기능 제거 — 신규는 false, 편집은 기존 값 보존(서버 계약 필드는 유지).
      pinned: widget.event?.pinned ?? false,
      memo: _memo.text.trim(),
      color: widget.event?.color ?? 'cool',
    );
  }

  /// [controller] 의 날짜를 달력 시트로 골라 반영한다(텍스트 직접 입력 대신).
  Future<void> _pickInto(TextEditingController controller) async {
    final String? picked = await showDkDatePicker(
      context,
      initial: controller.text,
    );
    if (picked != null && mounted) {
      setState(() => controller.text = picked);
    }
  }

  /// 탭하면 달력 피커를 여는 날짜 표시 필드.
  Widget _dateField(DkTokens t, TextEditingController controller, Key key) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: () => _pickInto(controller),
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
                fmtDate(controller.text),
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

  /// 기간(시작~종료)을 단일 달력 범위 선택 시트로 고른다.
  Future<void> _pickRange() async {
    final ({String start, String end})? picked = await showDkDateRangePicker(
      context,
      initialStart: _start.text,
      initialEnd: _end.text,
    );
    if (picked != null && mounted) {
      setState(() {
        _start.text = picked.start;
        _end.text = picked.end;
      });
    }
  }

  /// 탭하면 범위 달력을 여는 "시작 ~ 종료" 표시 필드.
  Widget _rangeField(DkTokens t) {
    return GestureDetector(
      key: const ValueKey<String>('event-range-field'),
      behavior: HitTestBehavior.opaque,
      onTap: _pickRange,
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
                '${fmtDate(_start.text)}  ~  ${fmtDate(_end.text)}',
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
    final DkEvent? ev = widget.event;
    final bool showHero = !widget.isNew && ev != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showHero) _hero(t, ev),
        DkField(
          label: '이벤트 타입',
          child: DkSegmented<DkEventType>(
            full: true,
            value: _type,
            onChanged: (DkEventType v) => setState(() => _type = v),
            options: const <DkSegment<DkEventType>>[
              DkSegment<DkEventType>(DkEventType.single, 'D-Day'),
              DkSegment<DkEventType>(DkEventType.progress, '기간 진행률'),
              DkSegment<DkEventType>(DkEventType.period, '기간 D-Day'),
            ],
          ),
        ),
        DkField(
          label: '제목',
          child: DkTextInput(controller: _title, placeholder: '예) 정보처리기사 실기'),
        ),
        DkField(
          label: '카테고리',
          child: DkCategoryPills(
            value: _cat,
            onChanged: (String c) => setState(() => _cat = c),
          ),
        ),
        DkField(
          label: _type == DkEventType.single ? '목표일' : '기간 (시작 ~ 종료)',
          child: _type == DkEventType.single
              ? _dateField(t, _date, const ValueKey<String>('event-date-field'))
              : _rangeField(t),
        ),
        DkField(
          label: '메모',
          child: DkTextInput(
            controller: _memo,
            placeholder: '메모를 남겨보세요',
            minHeight: 64,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: t.bgSubtle,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: <Widget>[
              _toggleRow(t, 'bell', 'D-Day 알림 (7·3·1일 전)', _remind, (bool v) {
                setState(() => _remind = v);
              }),
            ],
          ),
        ),
        _stickyActions(t, ev),
      ],
    );
  }

  Widget _hero(DkTokens t, DkEvent ev) {
    final DkDdayInfo info = ddayInfo(ev);
    final DkHue h = DkHue.byName(ev.color);
    const Color white = Color(0xFFFFFFFF);
    final String big = info.type == DkEventType.progress
        ? '${info.pct}%'
        : info.label.replaceAll('마감 ', '');

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: t.fgStrong,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -50,
              right: -30,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: h.color.withValues(alpha: 0.32),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${ev.category} · ${eventDateLabel(ev)}',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 13,
                                color: Color(0xB3FFFFFF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ev.title,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        big,
                        style: const TextStyle(
                          fontFamily: 'WantedSans',
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                          color: white,
                        ),
                      ),
                    ],
                  ),
                  if (info.type == DkEventType.progress) ...<Widget>[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                        height: 7,
                        child: Stack(
                          children: <Widget>[
                            Container(color: const Color(0x33FFFFFF)),
                            FractionallySizedBox(
                              widthFactor: info.pct / 100,
                              child: Container(color: white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(
    DkTokens t,
    String icon,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          DkIcon(icon, size: 19, color: t.fgMuted),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: t.fg,
              ),
            ),
          ),
          DkToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _stickyActions(DkTokens t, DkEvent? ev) {
    final bool isCompleted = ev?.completed ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // 종료(완료) 토글 — 기존 이벤트만. 자동 삭제 대신 유저가 명시적으로 종료(FRD 5.1).
        if (!widget.isNew &&
            ev != null &&
            widget.onComplete != null) ...<Widget>[
          SizedBox(
            width: double.infinity,
            child: DkButton(
              size: DkButtonSize.lg,
              full: true,
              variant: DkButtonVariant.outline,
              onPressed: () {
                widget.onComplete!.call(ev);
                widget.onClose();
              },
              leading: DkIcon(
                isCompleted ? 'repeat' : 'check',
                size: 18,
                color: t.fg,
                strokeWidth: 2,
              ),
              child: Text(isCompleted ? '종료 취소' : '종료 처리'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: <Widget>[
            if (!widget.isNew && ev != null) ...<Widget>[
              DkButton(
                size: DkButtonSize.lg,
                variant: DkButtonVariant.danger,
                onPressed: () {
                  widget.onDelete?.call(ev);
                  widget.onClose();
                },
                leading: DkIcon(
                  'trash',
                  size: 18,
                  color: t.danger,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: DkButton(
                size: DkButtonSize.lg,
                full: true,
                onPressed: () {
                  widget.onSubmit?.call(_draft());
                  widget.onClose();
                },
                child: Text(widget.isNew ? '추가하기' : '저장'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 이벤트 시트를 띄운다.
Future<void> showEventSheet(
  BuildContext context, {
  DkEvent? event,
  required bool isNew,
  ValueChanged<DkEvent>? onDelete,
  ValueChanged<DkEvent>? onSubmit,
  ValueChanged<DkEvent>? onComplete,
}) {
  return showDkSheet<void>(
    context,
    title: isNew ? '이벤트 추가' : '이벤트 상세',
    full: true,
    child: Builder(
      builder: (BuildContext sheetContext) => EventSheetBody(
        event: event,
        isNew: isNew,
        onClose: () => Navigator.of(sheetContext).maybePop(),
        onDelete: onDelete,
        onSubmit: onSubmit,
        onComplete: onComplete,
      ),
    ),
  );
}
