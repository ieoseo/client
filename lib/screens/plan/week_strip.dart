import 'package:flutter/widgets.dart';

import '../../data/format.dart';
import '../../theme/tokens.dart';

/// 주간 7일 스트립. 프로토타입 `WeekStrip`(월요일 시작 2026-06-01).
///
/// 각 칸: 요일 라벨 + 날짜 36 radius 12. 오늘=테두리, 선택=primary 채움.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.selected,
    required this.onSelect,
    this.weekStart,
  });

  /// 선택된 날짜 `YYYY-MM-DD`.
  final String selected;
  final ValueChanged<String> onSelect;

  /// 표시할 주의 시작(월요일). 지정하면 그 주를 그린다(PageView 페이지별 주). null 이면
  /// 선택일이 속한 주를 파생한다(단독 사용 시).
  final DateTime? weekStart;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    // 주 시작: 명시되면 그 주, 아니면 선택일이 속한 주의 월요일.
    final DateTime selDate = parseYmd(selected);
    final DateTime start = weekStart ?? addDays(selDate, 1 - selDate.weekday);
    final String todayKey = ymd(kToday);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < 7; i++)
            Expanded(child: _day(t, addDays(start, i), todayKey)),
        ],
      ),
    );
  }

  Widget _day(DkTokens t, DateTime d, String todayKey) {
    final String key = ymd(d);
    final bool on = key == selected;
    final bool isToday = key == todayKey;
    final String wd = kWeekdaysKo[d.weekday % 7];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: <Widget>[
            Text(
              wd,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: on ? t.primary : t.fgSubtle,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? t.primary : const Color(0x00000000),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !on && isToday ? t.primary : const Color(0x00000000),
                  width: 1.5,
                ),
              ),
              child: Text(
                '${d.day}',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: on
                      ? const Color(0xFFFFFFFF)
                      : isToday
                      ? t.primary
                      : t.fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
