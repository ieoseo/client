import '../models.dart';

/// 서버 응답 `data` ↔ 도메인 모델 매핑(이슈 #35).
///
/// 계약: docs/05-API/events-tasks-debts.md, server `web/dto/*`.
/// 날짜는 ISO ymd 문자열(`2026-06-04`), 시각은 ISO-8601 Instant(여기서는 미사용).
/// 응답 필드 추가는 비파괴적(모르는 필드 무시). 누락 필드는 보수적 기본값으로.

/// 문자열 필드를 안전하게 꺼낸다(null/비문자열 → null).
String? _str(Object? v) => v is String ? v : null;

/// 정수 필드를 안전하게 꺼낸다(num → int, 그 외 → null).
int? _int(Object? v) => v is num ? v.toInt() : null;

/// server recurrence 블록(`{frequency, weeklyDays, monthDay, yearMonth, yearDay}`)
/// → [DkRecurrence]. 누락/None 은 단발로 매핑한다(비파괴).
DkRecurrence _recurrenceFromJson(Object? raw) {
  if (raw is! Map) return DkRecurrence.none;
  final DkRecurrenceFreq freq = recurrenceFreqFromString(
    _str(raw['frequency']) ?? 'NONE',
  );
  if (freq == DkRecurrenceFreq.none) return DkRecurrence.none;

  final List<dynamic> days = raw['weeklyDays'] is List
      ? raw['weeklyDays'] as List<dynamic>
      : const <dynamic>[];
  return DkRecurrence(
    frequency: freq,
    weeklyDays: days
        .map((dynamic c) => kWeekdayCodeToNum[_str(c)])
        .whereType<int>()
        .toSet(),
    monthDay: _int(raw['monthDay']),
    yearMonth: _int(raw['yearMonth']),
    yearDay: _int(raw['yearDay']),
  );
}

/// [DkRecurrence] → server recurrence 생성 본문. 단발(none)은 null(필드 생략).
Map<String, dynamic>? _recurrenceToJson(DkRecurrence r) {
  if (!r.isRecurring) return null;
  return <String, dynamic>{
    'frequency': recurrenceFreqToString(r.frequency),
    if (r.frequency == DkRecurrenceFreq.weekly)
      'weeklyDays': r.weeklyDays
          .map((int n) => kWeekdayNumToCode[n])
          .whereType<String>()
          .toList(growable: false),
    if (r.frequency == DkRecurrenceFreq.monthly) 'monthDay': r.monthDay,
    if (r.frequency == DkRecurrenceFreq.yearly) ...<String, dynamic>{
      'yearMonth': r.yearMonth,
      'yearDay': r.yearDay,
    },
  };
}

/// D-Day 이벤트 DTO 매핑.
abstract final class DkEventDto {
  /// 서버 EventResponse `data` → [DkEvent]. `dday` 블록은 표현용이라 무시한다.
  static DkEvent fromJson(Map<String, dynamic> json) => DkEvent(
    id: _str(json['id']) ?? '',
    type: eventTypeFromString(_str(json['type']) ?? 'T1_DDAY'),
    title: _str(json['title']) ?? '',
    category: _str(json['category']) ?? '',
    date: _str(json['date']),
    start: _str(json['startDate']),
    end: _str(json['endDate']),
    pinned: json['pinned'] == true,
    memo: _str(json['memo']) ?? '',
    color: _str(json['color']) ?? 'cool',
  );

  /// [DkEvent] → 생성 요청 본문(EventCreateRequest). id/파생계산은 보내지 않는다.
  /// T1 은 `date`, T2/T3 은 `startDate`/`endDate` 를 채운다(타입 검증은 server 권위).
  static Map<String, dynamic> toCreateJson(DkEvent ev) => <String, dynamic>{
    'type': eventTypeToString(ev.type),
    'title': ev.title,
    'category': ev.category.isEmpty ? null : ev.category,
    'date': ev.type == DkEventType.single ? ev.date : null,
    'startDate': ev.type == DkEventType.single ? null : ev.start,
    'endDate': ev.type == DkEventType.single ? null : ev.end,
    'pinned': ev.pinned,
    'memo': ev.memo.isEmpty ? null : ev.memo,
    'color': ev.color,
  };

  /// 수정 요청 본문(EventUpdateRequest). 현재 계약은 생성과 동일 형태.
  static Map<String, dynamic> toUpdateJson(DkEvent ev) => toCreateJson(ev);
}

/// 할 일 DTO 매핑.
abstract final class DkTaskDto {
  /// 서버 TaskResponse `data` → [DkTask].
  static DkTask fromJson(Map<String, dynamic> json) => DkTask(
    id: _str(json['id']) ?? '',
    title: _str(json['title']) ?? '',
    mins: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
    date: _str(json['date']) ?? '',
    state: taskStateFromString(_str(json['state']) ?? 'PENDING'),
    category: _str(json['category']) ?? '',
    eventId: _str(json['eventId']),
    fromDate: _str(json['fromDate']),
    actualMins: (json['actualMinutes'] as num?)?.toInt(),
    recurrence: _recurrenceFromJson(json['recurrence']),
  );

  /// [DkTask] → 생성 요청 본문(TaskCreateRequest). 상태는 server 권위라 보내지 않는다.
  /// 반복 규칙은 단발(none)이 아닐 때만 `recurrence` 로 포함한다(FRD 5.4).
  static Map<String, dynamic> toCreateJson(DkTask task) {
    final Map<String, dynamic>? recurrence = _recurrenceToJson(task.recurrence);
    return <String, dynamic>{
      'title': task.title,
      'estimatedMinutes': task.mins,
      'date': task.date,
      'category': task.category.isEmpty ? null : task.category,
      'eventId': task.eventId,
      'recurrence': ?recurrence,
    };
  }

  /// 수정 요청 본문(TaskUpdateRequest). 현재 계약은 생성과 동일 형태.
  static Map<String, dynamic> toUpdateJson(DkTask task) => toCreateJson(task);
}

/// 시간부채("미룬 시간") DTO 매핑.
///
/// 서버 DebtResponse 는 원본 Task 제목(`title`)과 출처 라벨(`fromLabel`)을 함께
/// 내려준다(계약 §3, #41). 둘 다 server 가 소유자 스코프로 조인/산출한 값이라
/// 카드 제목·"…에서 발생" 문구에 그대로 쓴다. 누락 시 보수적 기본값으로 둔다.
abstract final class DkDebtDto {
  /// 서버 DebtResponse `data` → [DkDebt].
  /// `minutes→mins`, `originDate→fromDate`, `carriedToDate→assignedTo`,
  /// `title→title`, `fromLabel→fromLabel`.
  static DkDebt fromJson(Map<String, dynamic> json) => DkDebt(
    id: _str(json['id']) ?? '',
    title: _str(json['title']) ?? '',
    mins: (json['minutes'] as num?)?.toInt() ?? 0,
    fromDate: _str(json['originDate']) ?? '',
    status: debtStatusFromString(_str(json['status']) ?? 'PENDING'),
    assignedTo: _str(json['carriedToDate']),
    fromLabel: _str(json['fromLabel']),
  );
}
