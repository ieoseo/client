import 'package:flutter/widgets.dart';

import '../../data/format.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_button.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_sheet.dart';
import '../plan/calendar_logic.dart';

/// 기간(시작~종료)을 한 달력에서 연속 선택하는 시트. 시작 탭 → 종료 탭, 사이를 하이라이트한다.
/// 종료는 시작보다 앞설 수 없다(앞 날짜를 탭하면 시작이 재설정됨). 선택 완료 시 `(start, end)`,
/// 취소 시 null.
Future<({String start, String end})?> showDkDateRangePicker(
  BuildContext context, {
  required String initialStart,
  required String initialEnd,
}) {
  return showDkSheet<({String start, String end})>(
    context,
    title: '기간 선택',
    child: _DateRangePickerBody(
      initialStart: initialStart,
      initialEnd: initialEnd,
    ),
  );
}

class _DateRangePickerBody extends StatefulWidget {
  const _DateRangePickerBody({
    required this.initialStart,
    required this.initialEnd,
  });

  final String initialStart;
  final String initialEnd;

  @override
  State<_DateRangePickerBody> createState() => _DateRangePickerBodyState();
}

class _DateRangePickerBodyState extends State<_DateRangePickerBody> {
  late String? _start = _ymdOrNull(widget.initialStart);
  late String? _end = _ymdOrNull(widget.initialEnd);
  late DateTime _month = _firstOfMonth(parseYmd(_start ?? ymd(kToday)));

  String? _ymdOrNull(String s) {
    final DateTime? parsed = DateTime.tryParse(s.trim());
    return parsed == null ? null : ymd(parsed);
  }

  DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  /// 탭 로직: 시작이 없거나 이미 둘 다 있으면 새 시작(종료 초기화). 시작만 있으면 종료를 정하되,
  /// 시작보다 앞 날짜면 시작을 그 날짜로 재설정한다(종료 < 시작 방지).
  void _onTap(String key) {
    setState(() {
      if (_start == null || _end != null) {
        _start = key;
        _end = null;
      } else if (key.compareTo(_start!) < 0) {
        _start = key;
      } else {
        _end = key;
      }
    });
  }

  bool get _complete => _start != null && _end != null;

  String _summary() {
    if (_start == null) return '시작일을 선택하세요';
    if (_end == null) return '${fmtDate(_start)} ~ 종료일 선택';
    return '${fmtDate(_start)} ~ ${fmtDate(_end)}';
  }

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
        const SizedBox(height: 12),
        Center(
          child: Text(
            _summary(),
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _complete ? t.primary : t.fgSubtle,
            ),
          ),
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
          disabled: !_complete,
          onPressed: () {
            if (_complete) {
              Navigator.of(context).pop((start: _start!, end: _end!));
            }
          },
          child: Text(_complete ? '${fmtDate(_end)} 까지 선택' : '종료일을 선택하세요'),
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
    final bool isStart = key == _start;
    final bool isEnd = key == _end;
    final bool isEndpoint = isStart || isEnd;
    final bool inRange =
        _start != null &&
        _end != null &&
        key.compareTo(_start!) >= 0 &&
        key.compareTo(_end!) <= 0;
    final bool isToday = key == todayKey;
    final Color dayColor = dow == 0
        ? t.danger
        : dow == 6
        ? t.primary
        : t.fg;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(key),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // 범위 밴드(좌/우 반쪽). 시작 칸은 오른쪽만, 종료 칸은 왼쪽만, 중간은 양쪽.
            if (inRange && _start != _end)
              Positioned.fill(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        height: 38,
                        color: isStart ? null : t.primarySubtle,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 38,
                        color: isEnd ? null : t.primarySubtle,
                      ),
                    ),
                  ],
                ),
              ),
            // 마커/숫자.
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isEndpoint ? t.primary : null,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isEndpoint && !inRange
                    ? Border.all(color: t.primary, width: 1.5)
                    : null,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14.5,
                  fontWeight: isEndpoint || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isEndpoint
                      ? const Color(0xFFFFFFFF)
                      : inRange
                      ? t.fg
                      : dayColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
