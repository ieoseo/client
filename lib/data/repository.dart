import 'meta.dart';
import 'mock_data.dart';
import 'models.dart';

/// 데이터 접근 추상 인터페이스(ADR-0005, 이슈 #35).
///
/// UI는 이 인터페이스에만 의존한다. events/tasks/debts 는 server REST 를 호출하는
/// 비동기 메서드다(구현: [ApiRepository]). 외부 캘린더·주간 요약·집중 통계 등 아직
/// server 엔드포인트가 없는 읽기는 동기 목 데이터로 남긴다([MockRepository]).
/// 도메인 권위(상태 전이·D-Day·자동 이월)는 server.
abstract class IeoseoRepository {
  // ── Events ──────────────────────────────────────────────
  /// 이벤트 목록(server: GET /events).
  Future<List<DkEvent>> events();

  /// 이벤트 생성(server: POST /events → 201). 생성된 이벤트 반환.
  Future<DkEvent> createEvent(DkEvent draft);

  /// 이벤트 전체 수정(server: PUT /events/{id}).
  Future<DkEvent> updateEvent(DkEvent event);

  /// 이벤트 삭제(server: DELETE /events/{id} → 204).
  Future<void> deleteEvent(String id);

  /// 홈 고정 토글. server 전용 엔드포인트가 없어 PUT 으로 `pinned` 만 갱신한다.
  Future<DkEvent> pinEvent(DkEvent event, {required bool pinned});

  // ── Tasks ───────────────────────────────────────────────
  /// 태스크 목록(server: GET /tasks). [date] 지정 시 해당 일자만.
  Future<List<DkTask>> tasks({String? date});

  /// 태스크 생성(server: POST /tasks → 201).
  Future<DkTask> createTask(DkTask draft);

  /// 태스크 전체 수정(server: PUT /tasks/{id}).
  Future<DkTask> updateTask(DkTask task);

  /// 태스크 삭제(server: DELETE /tasks/{id} → 204).
  Future<void> deleteTask(String id);

  /// 완료 처리(server: POST /tasks/{id}/complete). [actualMinutes] 실제 소요(분).
  Future<DkTask> completeTask(String id, {int? actualMinutes});

  /// 완료 토글. 완료 상태면 수정(PUT)으로 되돌리고, 아니면 complete 한다.
  /// (server 에 별도 un-complete 액션이 없어 PUT 으로 today 복귀를 표현.)
  Future<DkTask> toggleComplete(DkTask task);

  /// 수동 이월(server: POST /tasks/{id}/carry). [toDate] ymd.
  Future<DkTask> carryTask(String id, {required String toDate});

  // ── TimeDebts ───────────────────────────────────────────
  /// 부채 목록(server: GET /debts). [status] 필터(server 코드 매핑).
  Future<List<DkDebt>> debts({DkDebtStatus? status});

  /// 수동 이월(server: POST /debts/{id}/carry). [toDate] ymd.
  Future<DkDebt> carryDebt(String id, {required String toDate});

  /// 자동 이월(server: POST /debts/{id}/auto-carry). 가장 여유 있는 날을
  /// server 가 산출해 배정한다(우선순위 권위는 server). 같은 주 불가 시 OVERDUE.
  Future<DkDebt> autoCarryDebt(String id);

  /// 탕감/내려놓기(server: POST /debts/{id}/abandon → ABANDONED).
  Future<DkDebt> abandonDebt(String id);

  // ── 외부 캘린더 연동(server: /calendar/*, 이슈 #59) ─────────
  /// 연결 목록(GET /calendar/connections).
  Future<List<DkCalendarConnection>> calendarConnections();

  /// 연결 등록/갱신(POST /calendar/connections/{provider}). 토큰/보조값 전달.
  Future<DkCalendarConnection> connectCalendar(
    DkSource source, {
    String? accessToken,
    String? refreshToken,
  });

  /// 연결 해제(DELETE /calendar/connections/{provider}).
  Future<void> disconnectCalendar(DkSource source);

  /// 수동 동기화(POST /calendar/sync). 갱신된 연결 목록.
  Future<List<DkCalendarConnection>> syncCalendars();

  /// 외부 일정 범위 조회(GET /calendar/external?from&to). 연결 0이면 빈 목록(graceful).
  Future<List<DkExternal>> externalEventsRange({
    required String from,
    required String to,
  });

  // ── 목 전용 동기 읽기(server 엔드포인트 없음) ──────────────
  /// 데모/테스트용 더미 외부 일정(동기). 실연동은 [externalEventsRange] 를 쓴다.
  List<DkExternal> externalEvents();
  DkWeekSummary weekSummary();
  DkFocusStats focusStats();
  DkPomodoro pomodoro();
  int streak();
  DkWeekReview weekReview();
}

/// in-memory 구현(테스트·데모용). 시드는 `mock_data.dart`.
///
/// 읽기/쓰기를 비동기로 노출하되 즉시 완료한다. 쓰기는 불변 패턴으로 내부
/// 리스트를 교체한다(원본 [kEvents]/[kTasks]/[kDebts] 는 변경하지 않음).
class MockRepository implements IeoseoRepository {
  MockRepository({
    List<DkEvent>? events,
    List<DkTask>? tasks,
    List<DkDebt>? debts,
  }) : _events = <DkEvent>[...(events ?? kEvents)],
       _tasks = <DkTask>[...(tasks ?? kTasks)],
       _debts = <DkDebt>[...(debts ?? kDebts)];

  List<DkEvent> _events;
  List<DkTask> _tasks;
  List<DkDebt> _debts;

  int _seq = 0;
  String _newId(String prefix) => '$prefix-mock-${++_seq}';

  @override
  Future<List<DkEvent>> events() async => List<DkEvent>.unmodifiable(_events);

  @override
  Future<DkEvent> createEvent(DkEvent draft) async {
    final DkEvent created = draft.copyWith(id: _newId('e'));
    _events = <DkEvent>[..._events, created];
    return created;
  }

  @override
  Future<DkEvent> updateEvent(DkEvent event) async {
    _events = _events.map((DkEvent e) => e.id == event.id ? event : e).toList();
    return event;
  }

  @override
  Future<void> deleteEvent(String id) async {
    _events = _events.where((DkEvent e) => e.id != id).toList();
  }

  @override
  Future<DkEvent> pinEvent(DkEvent event, {required bool pinned}) =>
      updateEvent(event.copyWith(pinned: pinned));

  @override
  Future<List<DkTask>> tasks({String? date}) async {
    final Iterable<DkTask> all = date == null
        ? _tasks
        : _tasks.where((DkTask t) => t.date == date);
    return List<DkTask>.unmodifiable(all);
  }

  @override
  Future<DkTask> createTask(DkTask draft) async {
    final DkTask created = draft.copyWith(
      id: _newId('t'),
      state: DkTaskState.today,
    );
    _tasks = <DkTask>[..._tasks, created];
    return created;
  }

  @override
  Future<DkTask> updateTask(DkTask task) async {
    _tasks = _tasks.map((DkTask t) => t.id == task.id ? task : t).toList();
    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks = _tasks.where((DkTask t) => t.id != id).toList();
  }

  @override
  Future<DkTask> completeTask(String id, {int? actualMinutes}) async {
    final DkTask done = _tasks
        .firstWhere((DkTask t) => t.id == id)
        .copyWith(state: DkTaskState.done, actualMins: actualMinutes);
    return updateTask(done);
  }

  @override
  Future<DkTask> toggleComplete(DkTask task) {
    if (task.state == DkTaskState.done) {
      return updateTask(task.copyWith(state: DkTaskState.today));
    }
    return completeTask(task.id, actualMinutes: task.actualMins);
  }

  @override
  Future<DkTask> carryTask(String id, {required String toDate}) async {
    final DkTask src = _tasks.firstWhere((DkTask t) => t.id == id);
    final DkTask carried = src.copyWith(
      fromDate: src.date,
      date: toDate,
      state: DkTaskState.carried,
    );
    return updateTask(carried);
  }

  @override
  Future<List<DkDebt>> debts({DkDebtStatus? status}) async {
    final Iterable<DkDebt> all = status == null
        ? _debts
        : _debts.where((DkDebt d) => d.status == status);
    return List<DkDebt>.unmodifiable(all);
  }

  @override
  Future<DkDebt> carryDebt(String id, {required String toDate}) async {
    final DkDebt updated = _debts
        .firstWhere((DkDebt d) => d.id == id)
        .copyWith(status: DkDebtStatus.assigned, assignedTo: toDate);
    _debts = _debts.map((DkDebt d) => d.id == id ? updated : d).toList();
    return updated;
  }

  @override
  Future<DkDebt> autoCarryDebt(String id) async {
    // 실제 우선순위 산출은 server 권위. 목은 데모용 고정 대상일(가장 여유 있는 날).
    final DkDebt updated = _debts
        .firstWhere((DkDebt d) => d.id == id)
        .copyWith(status: DkDebtStatus.assigned, assignedTo: '2026-06-06');
    _debts = _debts.map((DkDebt d) => d.id == id ? updated : d).toList();
    return updated;
  }

  @override
  Future<DkDebt> abandonDebt(String id) async {
    final DkDebt updated = _debts
        .firstWhere((DkDebt d) => d.id == id)
        .copyWith(status: DkDebtStatus.abandoned);
    _debts = _debts.map((DkDebt d) => d.id == id ? updated : d).toList();
    return updated;
  }

  // ── 외부 캘린더(데모용 in-memory) ─────────────────────────
  List<DkCalendarConnection> _connections = const <DkCalendarConnection>[];

  @override
  Future<List<DkCalendarConnection>> calendarConnections() async =>
      List<DkCalendarConnection>.unmodifiable(_connections);

  @override
  Future<DkCalendarConnection> connectCalendar(
    DkSource source, {
    String? accessToken,
    String? refreshToken,
  }) async {
    final DkCalendarConnection conn = DkCalendarConnection(
      source: source,
      status: DkConnectionStatus.connected,
    );
    _connections = <DkCalendarConnection>[
      ..._connections.where((DkCalendarConnection c) => c.source != source),
      conn,
    ];
    return conn;
  }

  @override
  Future<void> disconnectCalendar(DkSource source) async {
    _connections = _connections
        .where((DkCalendarConnection c) => c.source != source)
        .toList();
  }

  @override
  Future<List<DkCalendarConnection>> syncCalendars() async {
    final String now = DateTime.now().toUtc().toIso8601String();
    _connections = _connections
        .map(
          (DkCalendarConnection c) => DkCalendarConnection(
            source: c.source,
            status: DkConnectionStatus.connected,
            lastSyncedAt: now,
          ),
        )
        .toList();
    return List<DkCalendarConnection>.unmodifiable(_connections);
  }

  @override
  Future<List<DkExternal>> externalEventsRange({
    required String from,
    required String to,
  }) async => kExternal
      .where(
        (DkExternal x) =>
            x.date.compareTo(from) >= 0 && x.date.compareTo(to) <= 0,
      )
      .toList(growable: false);

  @override
  List<DkExternal> externalEvents() => kExternal;

  @override
  DkWeekSummary weekSummary() => kWeekSummary;

  @override
  DkFocusStats focusStats() => kFocusStats;

  @override
  DkPomodoro pomodoro() => kPomodoro;

  @override
  int streak() => kStreak;

  @override
  DkWeekReview weekReview() => kWeekReview;
}
