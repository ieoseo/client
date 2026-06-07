/// 이어서 날짜·시간 포매팅 헬퍼. 프로토타입 `daykit-data.jsx`의 함수들을 이식.
///
/// "오늘"은 주간 뷰 + D-Day 계산이 안정적으로 보이도록 2026-06-01(월)에 고정한다.
library;

import 'models.dart';

/// 고정된 "오늘"(2026년 6월 1일 월요일).
final DateTime kToday = DateTime(2026, 6, 1);

/// 요일 라벨(일~토).
const List<String> kWeekdaysKo = <String>['일', '월', '화', '수', '목', '금', '토'];

/// 월 라벨(1월~12월).
const List<String> kMonthsKo = <String>[
  '1월',
  '2월',
  '3월',
  '4월',
  '5월',
  '6월',
  '7월',
  '8월',
  '9월',
  '10월',
  '11월',
  '12월',
];

/// `DateTime` → `YYYY-MM-DD`.
String ymd(DateTime d) {
  final String m = d.month.toString().padLeft(2, '0');
  final String day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

/// `YYYY-MM-DD` → `DateTime`(자정).
DateTime parseYmd(String s) {
  final List<int> parts = s.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

/// 두 날짜(문자열 또는 DateTime) 사이의 일수. `b - a`.
int daysBetween(Object a, Object b) {
  final DateTime da = a is String ? parseYmd(a) : a as DateTime;
  final DateTime db = b is String ? parseYmd(b) : b as DateTime;
  // 자정 기준 정규화 후 일수 차이.
  final DateTime na = DateTime(da.year, da.month, da.day);
  final DateTime nb = DateTime(db.year, db.month, db.day);
  return nb.difference(na).inDays;
}

/// 날짜에 [n]일을 더한 새 `DateTime`.
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// 분 → 한국어 시간 라벨. 예: 90 → "1시간 30분", 30 → "30분".
String fmtMins(int m) {
  if (m < 60) return '$m분';
  final int h = m ~/ 60;
  final int mm = m % 60;
  return mm > 0 ? '$h시간 $mm분' : '$h시간';
}

/// `YYYY-MM-DD` → `YYYY. MM. DD`. 빈 값은 빈 문자열.
String fmtDate(String? s) => s == null ? '' : s.replaceAll('-', '. ');

/// 이벤트의 날짜 라벨. 프로토타입 `eventDateLabel`.
/// T1은 단일 날짜, 그 외(T2/T3)는 "시작 ~ 종료".
String eventDateLabel(DkEvent ev) {
  if (ev.type == DkEventType.single) return fmtDate(ev.date);
  return '${fmtDate(ev.start)} ~ ${fmtDate(ev.end)}';
}
