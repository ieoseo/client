import 'package:flutter/foundation.dart';

import '../../data/models.dart';
import '../../theme/tokens.dart';

/// 통합 일정 항목의 종류.
enum DayItemKind { task, event, external }

/// 캘린더 하루의 통합 항목(태스크/이벤트/외부). 프로토타입 `dayItems` 결과.
@immutable
class DayItem {
  const DayItem({
    required this.kind,
    required this.title,
    this.source = DkSource.app,
    this.mins,
    this.time,
    this.taskState,
    this.colorName,
    this.task,
    this.event,
  });

  final DayItemKind kind;
  final String title;
  final DkSource source;

  /// 태스크 예상 소요(분).
  final int? mins;

  /// 외부 일정 시각.
  final String? time;
  final DkTaskState? taskState;

  /// hue 이름(태스크=카테고리 hue, 이벤트=ev.color, 외부=출처색은 호출부에서).
  final String? colorName;

  /// 참조(상세 시트 열기용).
  final DkTask? task;
  final DkEvent? event;

  bool get isEvent => kind == DayItemKind.event;
}

/// [dateStr](`YYYY-MM-DD`) 하루의 태스크·이벤트·외부 일정을 모은다.
/// 프로토타입 `dayItems`.
List<DayItem> dayItems(
  String dateStr, {
  required List<DkTask> tasks,
  required List<DkEvent> events,
  required List<DkExternal> externals,
}) {
  final List<DayItem> items = <DayItem>[];

  for (final DkTask t in tasks.where((DkTask t) => t.date == dateStr)) {
    items.add(
      DayItem(
        kind: DayItemKind.task,
        title: t.title,
        mins: t.mins,
        taskState: t.state,
        colorName: kCategoryHue[t.category] ?? 'cool',
        task: t,
      ),
    );
  }

  for (final DkEvent e in events) {
    if (e.type == DkEventType.single && e.date == dateStr) {
      items.add(
        DayItem(
          kind: DayItemKind.event,
          title: e.title,
          colorName: e.color,
          event: e,
        ),
      );
    } else if (e.type == DkEventType.period &&
        (e.start == dateStr || e.end == dateStr)) {
      items.add(
        DayItem(
          kind: DayItemKind.event,
          title: '${e.title} ${e.start == dateStr ? '시작' : '마감'}',
          colorName: e.color,
          event: e,
        ),
      );
    }
  }

  for (final DkExternal x in externals.where(
    (DkExternal x) => x.date == dateStr,
  )) {
    items.add(
      DayItem(
        kind: DayItemKind.external,
        title: x.title,
        source: x.source,
        time: x.time,
      ),
    );
  }

  return items;
}

/// 월 그리드 셀(일요일 시작). 앞쪽 패딩 + 1..말일 + 끝 패딩으로 7의 배수.
/// 프로토타입 `MonthGrid`의 cells. [month]는 1~12.
List<int?> monthCells(int year, int month) {
  final DateTime first = DateTime(year, month, 1);
  final int startPad = first.weekday % 7; // Dart: 월=1..일=7 → 일=0 시작.
  final int daysInMonth = DateTime(year, month + 1, 0).day;
  final List<int?> cells = <int?>[];
  for (int i = 0; i < startPad; i++) {
    cells.add(null);
  }
  for (int d = 1; d <= daysInMonth; d++) {
    cells.add(d);
  }
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}
