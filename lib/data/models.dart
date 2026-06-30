import 'package:flutter/foundation.dart';

/// copyWith 센티넬 — "인자 미지정"과 "null 로 비우기"를 구분하기 위한 표식.
/// (`field ?? this.field` 패턴은 nullable 필드를 null 로 설정하지 못한다.)
const Object _unset = Object();

/// D-Day 이벤트 타입. server 코드 `T1_DDAY | T2_PROGRESS | T3_PERIOD_DDAY`.
/// - [single] (T1): 단일 D-Day.
/// - [progress] (T2): 기간 진행률(%).
/// - [period] (T3): 기간 D-Day(시작/마감).
enum DkEventType { single, progress, period }

/// 할 일 상태. server `TaskState`(`PENDING`/`TODAY`/`DONE`/`MISSED`/`CARRIED`/
/// `OVERDUE`/`ABANDONED`). 전이 권위는 server.
enum DkTaskState { done, today, carried, overdue, pending, missed, abandoned }

/// 미룬 시간(부채) 상태. server `DebtStatus`(`PENDING`/`CARRIED`/`RESOLVED`/
/// `OVERDUE`/`ABANDONED`). [assigned] 는 server `CARRIED`(이월 배정)에 대응한다.
enum DkDebtStatus { pending, assigned, overdue, resolved, abandoned }

/// 외부 캘린더 출처. 프로토타입 `source`.
enum DkSource { app, google, apple, notion }

/// 반복 주기(FRD 5.4). server `RecurrenceFrequency`(`NONE`/`WEEKLY`/`MONTHLY`/`YEARLY`).
enum DkRecurrenceFreq { none, weekly, monthly, yearly }

/// server 요일 코드(`MON`…`SUN`) → `DateTime.weekday`(월=1 … 일=7).
const Map<String, int> kWeekdayCodeToNum = <String, int>{
  'MON': 1,
  'TUE': 2,
  'WED': 3,
  'THU': 4,
  'FRI': 5,
  'SAT': 6,
  'SUN': 7,
};

/// `DateTime.weekday`(월=1 … 일=7) → server 요일 코드(`MON`…`SUN`).
const Map<int, String> kWeekdayNumToCode = <int, String>{
  1: 'MON',
  2: 'TUE',
  3: 'WED',
  4: 'THU',
  5: 'FRI',
  6: 'SAT',
  7: 'SUN',
};

DkRecurrenceFreq recurrenceFreqFromString(String s) => switch (s) {
  'WEEKLY' => DkRecurrenceFreq.weekly,
  'MONTHLY' => DkRecurrenceFreq.monthly,
  'YEARLY' => DkRecurrenceFreq.yearly,
  _ => DkRecurrenceFreq.none,
};

String recurrenceFreqToString(DkRecurrenceFreq f) => switch (f) {
  DkRecurrenceFreq.weekly => 'WEEKLY',
  DkRecurrenceFreq.monthly => 'MONTHLY',
  DkRecurrenceFreq.yearly => 'YEARLY',
  DkRecurrenceFreq.none => 'NONE',
};

/// 태스크 반복 규칙(FRD 5.4). server `RecurrenceRule` 의 클라이언트 표현.
///
/// - [weeklyDays]: WEEKLY 요일 집합(`DateTime.weekday` 기준 월=1 … 일=7).
/// - [monthDay]: MONTHLY 일자(1~31).
/// - [yearMonth]/[yearDay]: YEARLY 월(1~12)/일(1~31).
@immutable
class DkRecurrence {
  const DkRecurrence({
    required this.frequency,
    this.weeklyDays = const <int>{},
    this.monthDay,
    this.yearMonth,
    this.yearDay,
  });

  /// 반복 없음(단발).
  static const DkRecurrence none = DkRecurrence(
    frequency: DkRecurrenceFreq.none,
  );

  final DkRecurrenceFreq frequency;
  final Set<int> weeklyDays;
  final int? monthDay;
  final int? yearMonth;
  final int? yearDay;

  bool get isRecurring => frequency != DkRecurrenceFreq.none;

  DkRecurrence copyWith({
    DkRecurrenceFreq? frequency,
    Set<int>? weeklyDays,
    int? monthDay,
    int? yearMonth,
    int? yearDay,
  }) {
    return DkRecurrence(
      frequency: frequency ?? this.frequency,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      monthDay: monthDay ?? this.monthDay,
      yearMonth: yearMonth ?? this.yearMonth,
      yearDay: yearDay ?? this.yearDay,
    );
  }
}

DkTaskState taskStateFromString(String s) => switch (s) {
  'DONE' => DkTaskState.done,
  'TODAY' => DkTaskState.today,
  'CARRIED' => DkTaskState.carried,
  'OVERDUE' => DkTaskState.overdue,
  'MISSED' => DkTaskState.missed,
  'ABANDONED' => DkTaskState.abandoned,
  _ => DkTaskState.pending,
};

/// server `TaskState` 코드 문자열. 상태는 server 권위이므로 보낼 일은 드물지만
/// round-trip 검증·디버깅에 사용.
String taskStateToString(DkTaskState s) => switch (s) {
  DkTaskState.done => 'DONE',
  DkTaskState.today => 'TODAY',
  DkTaskState.carried => 'CARRIED',
  DkTaskState.overdue => 'OVERDUE',
  DkTaskState.missed => 'MISSED',
  DkTaskState.abandoned => 'ABANDONED',
  DkTaskState.pending => 'PENDING',
};

DkDebtStatus debtStatusFromString(String s) => switch (s) {
  // server CARRIED(이월 배정) → 클라이언트 assigned.
  'CARRIED' => DkDebtStatus.assigned,
  'ASSIGNED' => DkDebtStatus.assigned,
  'OVERDUE' => DkDebtStatus.overdue,
  'RESOLVED' => DkDebtStatus.resolved,
  'ABANDONED' => DkDebtStatus.abandoned,
  _ => DkDebtStatus.pending,
};

/// server `DebtStatus` 코드 문자열. [DkDebtStatus.assigned] → `CARRIED`.
String debtStatusToString(DkDebtStatus s) => switch (s) {
  DkDebtStatus.assigned => 'CARRIED',
  DkDebtStatus.overdue => 'OVERDUE',
  DkDebtStatus.resolved => 'RESOLVED',
  DkDebtStatus.abandoned => 'ABANDONED',
  DkDebtStatus.pending => 'PENDING',
};

DkEventType eventTypeFromString(String s) => switch (s) {
  // server 코드.
  'T2_PROGRESS' => DkEventType.progress,
  'T3_PERIOD_DDAY' => DkEventType.period,
  'T1_DDAY' => DkEventType.single,
  // 프로토타입 단축 코드(하위 호환).
  'T2' => DkEventType.progress,
  'T3' => DkEventType.period,
  _ => DkEventType.single,
};

/// server `EventType` 코드 문자열.
String eventTypeToString(DkEventType t) => switch (t) {
  DkEventType.single => 'T1_DDAY',
  DkEventType.progress => 'T2_PROGRESS',
  DkEventType.period => 'T3_PERIOD_DDAY',
};

DkSource sourceFromString(String s) => switch (s) {
  'google' => DkSource.google,
  'apple' => DkSource.apple,
  'notion' => DkSource.notion,
  _ => DkSource.app,
};

/// D-Day 이벤트. 날짜는 `YYYY-MM-DD` 문자열(프로토타입과 동일).
@immutable
class DkEvent {
  const DkEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    this.date,
    this.start,
    this.end,
    this.pinned = false,
    this.memo = '',
    this.color = 'cool',
    this.remindDays = const <int>[],
    this.completed = false,
  });

  final String id;
  final DkEventType type;
  final String title;
  final String category;

  /// T1 단일 날짜.
  final String? date;

  /// T2/T3 시작 날짜.
  final String? start;

  /// T2/T3 종료 날짜.
  final String? end;

  final bool pinned;
  final String memo;

  /// hue 이름(blue/violet/orange/green/sky/cool/red).
  final String color;
  final List<int> remindDays;

  /// 종료(완료) 처리 여부. true 면 홈 "다가오는 일정"에서 숨긴다(server `completed`).
  /// 마감/기간이 지나도 자동 삭제하지 않고, 유저가 명시적으로 종료할 때만 true.
  final bool completed;

  /// nullable 날짜 필드(date/start/end)는 센티넬([_unset])로 받아 **null 로 비우기**도
  /// 가능하게 한다(`field ?? this.field` 패턴은 null 설정을 못 함). 예: T1↔T2 전환 시 date 비우기.
  DkEvent copyWith({
    String? id,
    DkEventType? type,
    String? title,
    String? category,
    Object? date = _unset,
    Object? start = _unset,
    Object? end = _unset,
    bool? pinned,
    String? memo,
    String? color,
    List<int>? remindDays,
    bool? completed,
  }) {
    return DkEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      date: identical(date, _unset) ? this.date : date as String?,
      start: identical(start, _unset) ? this.start : start as String?,
      end: identical(end, _unset) ? this.end : end as String?,
      pinned: pinned ?? this.pinned,
      memo: memo ?? this.memo,
      color: color ?? this.color,
      remindDays: remindDays ?? this.remindDays,
      completed: completed ?? this.completed,
    );
  }
}

/// 할 일.
@immutable
class DkTask {
  const DkTask({
    required this.id,
    required this.title,
    required this.mins,
    required this.date,
    required this.state,
    required this.category,
    this.startDate,
    this.actualMins,
    this.eventId,
    this.fromDate,
    this.fromLabel,
    this.recurrence = DkRecurrence.none,
  });

  final String id;
  final String title;

  /// 예상 소요 시간(분).
  final int mins;

  /// 마감/종료일 `YYYY-MM-DD`. 항상 존재하는 앵커(단일=그날, 범위=종료). server 권위(ADR-0026).
  final String date;
  final DkTaskState state;
  final String category;

  /// 범위 태스크 시작일 `YYYY-MM-DD`(#50). null 이면 단일 날짜. 있으면 `startDate ~ date`.
  final String? startDate;

  /// 실제 소요 시간(분).
  final int? actualMins;

  /// 연결된 D-Day 이벤트 id.
  final String? eventId;

  /// 이월 전 원래 날짜.
  final String? fromDate;

  /// 이월 전 날짜 라벨(예: "지난주 금요일").
  final String? fromLabel;

  /// 반복 규칙(FRD 5.4). 기본 단발(`DkRecurrence.none`).
  final DkRecurrence recurrence;

  bool get isDone => state == DkTaskState.done;
  bool get isCarried =>
      state == DkTaskState.carried || state == DkTaskState.overdue;

  /// 범위 태스크 여부(시작일이 있으면 범위, #50).
  bool get isRange => startDate != null;

  /// nullable 필드(startDate/actualMins/eventId/fromDate/fromLabel)는 센티넬([_unset])로 받아
  /// **null 로 비우기**도 가능하게 한다(`field ?? this.field` 패턴은 null 설정을 못 함).
  /// 인자를 생략하면 기존 값 유지, `null` 을 명시하면 비운다(범위→단일 전환 시 startDate=null).
  DkTask copyWith({
    String? id,
    String? title,
    int? mins,
    String? date,
    DkTaskState? state,
    String? category,
    Object? startDate = _unset,
    Object? actualMins = _unset,
    Object? eventId = _unset,
    Object? fromDate = _unset,
    Object? fromLabel = _unset,
    DkRecurrence? recurrence,
  }) {
    return DkTask(
      id: id ?? this.id,
      title: title ?? this.title,
      mins: mins ?? this.mins,
      date: date ?? this.date,
      state: state ?? this.state,
      category: category ?? this.category,
      startDate: identical(startDate, _unset)
          ? this.startDate
          : startDate as String?,
      actualMins: identical(actualMins, _unset)
          ? this.actualMins
          : actualMins as int?,
      eventId: identical(eventId, _unset) ? this.eventId : eventId as String?,
      fromDate: identical(fromDate, _unset)
          ? this.fromDate
          : fromDate as String?,
      fromLabel: identical(fromLabel, _unset)
          ? this.fromLabel
          : fromLabel as String?,
      recurrence: recurrence ?? this.recurrence,
    );
  }
}

/// 미룬 시간(부채) 항목.
@immutable
class DkDebt {
  const DkDebt({
    required this.id,
    required this.title,
    required this.mins,
    required this.fromDate,
    required this.status,
    this.assignedTo,
    this.fromLabel,
  });

  final String id;
  final String title;
  final int mins;
  final String fromDate;
  final DkDebtStatus status;

  /// 배정된 날짜 `YYYY-MM-DD`.
  final String? assignedTo;
  final String? fromLabel;

  /// nullable 필드(assignedTo/fromLabel)는 센티넬([_unset])로 받아 **null 로 비우기**도
  /// 가능하게 한다(`field ?? this.field` 패턴은 null 설정을 못 함). 예: 배정 해제 시 assignedTo 비우기.
  DkDebt copyWith({
    String? id,
    String? title,
    int? mins,
    String? fromDate,
    DkDebtStatus? status,
    Object? assignedTo = _unset,
    Object? fromLabel = _unset,
  }) {
    return DkDebt(
      id: id ?? this.id,
      title: title ?? this.title,
      mins: mins ?? this.mins,
      fromDate: fromDate ?? this.fromDate,
      status: status ?? this.status,
      assignedTo: identical(assignedTo, _unset)
          ? this.assignedTo
          : assignedTo as String?,
      fromLabel: identical(fromLabel, _unset)
          ? this.fromLabel
          : fromLabel as String?,
    );
  }
}

/// 외부 캘린더 이벤트(읽기 전용).
@immutable
class DkExternal {
  const DkExternal({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.source,
  });

  final String id;
  final String title;
  final String date;
  final String time;
  final DkSource source;
}

/// 외부 캘린더 연결 상태(이슈 #59). server `ConnectionStatus`(CONNECTED/SYNC_FAILED) +
/// 미연결([none] — 연결 레코드 부재)을 표현. 표시 라벨은 화면에서 결정한다.
enum DkConnectionStatus { none, connected, syncFailed }

/// 외부 캘린더 연결 한 건(이슈 #59). server `CalendarConnectionResponse` 매핑.
///
/// 토큰은 절대 담지 않는다(server 응답에도 없음). [lastSyncedAt] 은 ISO-8601 Instant
/// 문자열(없으면 null = 한 번도 동기화 안 함).
@immutable
class DkCalendarConnection {
  const DkCalendarConnection({
    required this.source,
    required this.status,
    this.lastSyncedAt,
  });

  /// 미연결 상태의 기본 항목(설정 화면에서 provider 별 빈 행 표시용).
  const DkCalendarConnection.disconnected(this.source)
    : status = DkConnectionStatus.none,
      lastSyncedAt = null;

  final DkSource source;
  final DkConnectionStatus status;
  final String? lastSyncedAt;

  bool get isConnected => status != DkConnectionStatus.none;
}

/// 외부 캘린더 연동 가능한 provider(앱 출처 [DkSource.app] 제외).
const List<DkSource> kCalendarProviders = <DkSource>[
  DkSource.google,
  DkSource.apple,
  DkSource.notion,
];

/// 캘린더 연동 화면에 **노출**할 provider(이슈 #67, MVP). 현재는 **Google만**.
///
/// Apple·Notion 은 연동 코드/매핑([calendarProviderCode])을 그대로 두되 UI에서만
/// 숨긴다 — 재노출하려면 이 목록에 추가하면 된다.
const List<DkSource> kVisibleCalendarProviders = <DkSource>[DkSource.google];

/// [DkSource] → server CalendarProvider 코드(GOOGLE/APPLE/NOTION). app 은 외부 아님.
String? calendarProviderCode(DkSource source) => switch (source) {
  DkSource.google => 'GOOGLE',
  DkSource.apple => 'APPLE',
  DkSource.notion => 'NOTION',
  DkSource.app => null,
};

/// server CalendarProvider 코드 → [DkSource]. 미상은 [DkSource.app](방어적).
DkSource calendarSourceFromCode(String? code) => switch (code) {
  'GOOGLE' => DkSource.google,
  'APPLE' => DkSource.apple,
  'NOTION' => DkSource.notion,
  _ => DkSource.app,
};

/// 주간 요약(시간 단위).
@immutable
class DkWeekSummary {
  const DkWeekSummary({
    required this.planned,
    required this.done,
    required this.debt,
  });

  final double planned;
  final double done;
  final double debt;
}

/// 포모도로 설정(분).
@immutable
class DkPomodoro {
  const DkPomodoro({
    this.focus = 25,
    this.shortBreak = 5,
    this.longBreak = 15,
    this.longEvery = 4,
  });

  final int focus;
  final int shortBreak;
  final int longBreak;
  final int longEvery;
}

/// 집중 통계.
@immutable
class DkFocusStats {
  const DkFocusStats({
    required this.todaySessions,
    required this.todayMinutes,
    required this.goal,
  });

  final int todaySessions;
  final int todayMinutes;
  final int goal;
}
