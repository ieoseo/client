import 'package:flutter/widgets.dart';

import '../../data/format.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_button.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_sheet.dart';
import '../plan/calendar_logic.dart';

/// 날짜 선택 시트를 열고 선택한 `YYYY-MM-DD` 를 반환한다(취소 시 null).
/// [initial] 이 가리키는 달을 첫 화면으로 보여준다.
Future<String?> showDkDatePicker(
  BuildContext context, {
  required String initial,
}) {
  return showDkSheet<String>(
    context,
    title: '날짜 선택',
    child: _DatePickerBody(initial: initial),
  );
}

/// 월 캘린더로 하루를 고르는 시트 본문. 월 이동(◀ ▶) + 7열 그리드 + '선택' 버튼.
class _DatePickerBody extends StatefulWidget {
  const _DatePickerBody({required this.initial});

  final String initial;

  @override
  State<_DatePickerBody> createState() => _DatePickerBodyState();
}

class _DatePickerBodyState extends State<_DatePickerBody> {
  late String _selected = _initialYmd();
  late DateTime _month = _firstOfMonth(parseYmd(_selected));

  String _initialYmd() {
    final DateTime? parsed = DateTime.tryParse(widget.initial.trim());
    return ymd(parsed ?? kToday);
  }

  DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final List<int?> cells = monthCells(_month.year, _month.month);
    final String monthPrefix =
        '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final String todayKey = ymd(kToday);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 월 이동 헤더.
        Row(
          children: <Widget>[
            _arrow(t, 'chevL', () => _shiftMonth(-1)),
            Expanded(
              child: Center(
                child: Text(
                  '${_month.year}년 ${kMonthsKo[_month.month - 1]}',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: t.fgStrong,
                  ),
                ),
              ),
            ),
            _arrow(t, 'chevR', () => _shiftMonth(1)),
          ],
        ),
        const SizedBox(height: 14),
        // 요일 헤더.
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
        // 날짜 그리드.
        for (int row = 0; row < cells.length ~/ 7; row++)
          Row(
            children: <Widget>[
              for (int col = 0; col < 7; col++)
                Expanded(
                  child: _cell(
                    t,
                    cells[row * 7 + col],
                    col,
                    monthPrefix,
                    todayKey,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
        DkButton(
          size: DkButtonSize.lg,
          full: true,
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text('${fmtDate(_selected)} 선택'),
        ),
      ],
    );
  }

  Widget _arrow(DkTokens t, String icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.bgSubtle,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DkIcon(icon, size: 20, color: t.fgMuted, strokeWidth: 2.2),
      ),
    );
  }

  Widget _cell(
    DkTokens t,
    int? day,
    int dow,
    String monthPrefix,
    String todayKey,
  ) {
    if (day == null) return const SizedBox(height: 44);
    final String key = '$monthPrefix-${day.toString().padLeft(2, '0')}';
    final bool isSelected = key == _selected;
    final bool isToday = key == todayKey;
    final Color dayColor = dow == 0
        ? t.danger
        : dow == 6
        ? t.primary
        : t.fg;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = key),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? t.primary : null,
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected
                  ? Border.all(color: t.primary, width: 1.5)
                  : null,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14.5,
                fontWeight: isSelected || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isSelected ? const Color(0xFFFFFFFF) : dayColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
