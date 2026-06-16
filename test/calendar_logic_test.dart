import 'package:ieoseo/data/format.dart';
import 'package:ieoseo/data/mock_data.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/plan/calendar_logic.dart';
import 'package:flutter_test/flutter_test.dart';

/// mock 데이터가 kToday 상대(이슈 #52)라, 쿼리 날짜도 같은 오프셋으로 만든다.
String _d(int offset) => ymd(addDays(kToday, offset));

void main() {
  group('dayItems', () {
    test('해당 날짜의 태스크·이벤트·외부 일정을 모은다', () {
      // 2026-06-01: 태스크 6건(t1~t6).
      final List<DayItem> items = dayItems(
        _d(0),
        tasks: kTasks,
        events: kEvents,
        externals: kExternal,
      );
      expect(items.where((DayItem i) => i.kind == DayItemKind.task).length, 6);
    });

    test('T1 이벤트는 목표일에 노출된다', () {
      // e2 토익 2026-06-13.
      final List<DayItem> items = dayItems(
        _d(12),
        tasks: kTasks,
        events: kEvents,
        externals: kExternal,
      );
      expect(
        items.any(
          (DayItem i) => i.kind == DayItemKind.event && i.title.contains('토익'),
        ),
        true,
      );
    });

    test('T3 기간 이벤트는 시작·종료일에 시작/마감 라벨로', () {
      // e3 접수 start 2026-06-08 end 2026-06-12.
      final List<DayItem> start = dayItems(
        _d(7),
        tasks: kTasks,
        events: kEvents,
        externals: kExternal,
      );
      expect(start.any((DayItem i) => i.title.contains('시작')), true);

      final List<DayItem> end = dayItems(
        _d(11),
        tasks: kTasks,
        events: kEvents,
        externals: kExternal,
      );
      expect(end.any((DayItem i) => i.title.contains('마감')), true);
    });

    test('외부 일정은 출처와 시각을 가진다', () {
      // x1 Google 2026-06-02 10:00.
      final List<DayItem> items = dayItems(
        _d(1),
        tasks: kTasks,
        events: kEvents,
        externals: kExternal,
      );
      final DayItem ext = items.firstWhere(
        (DayItem i) => i.kind == DayItemKind.external,
      );
      expect(ext.source, DkSource.google);
      expect(ext.time, '10:00');
    });

    test('빈 날짜는 빈 목록', () {
      final List<DayItem> items = dayItems(
        _d(19),
        tasks: kTasks,
        events: kEvents,
        externals: kExternal,
      );
      expect(items, isEmpty);
    });
  });

  group('monthCells', () {
    test('2026년 6월은 앞쪽 패딩 1칸(1일=월) + 30일', () {
      final List<int?> cells = monthCells(2026, 6);
      // 6월 1일은 월요일 → 일요일 시작이므로 앞에 1칸 null.
      expect(cells.first, isNull);
      expect(cells.contains(1), true);
      expect(cells.contains(30), true);
      expect(cells.length % 7, 0);
    });
  });
}
