import '../meta.dart';
import '../mock_data.dart';
import '../models.dart';
import '../repository.dart';
import 'api_client.dart';
import 'calendar_api.dart';
import 'dtos.dart';

/// server REST 를 호출하는 [IeoseoRepository] 구현(이슈 #35, #59).
///
/// events/tasks/debts/calendar 는 [ApiClient] 로 호출한다(인증 헤더·envelope 언랩·401
/// refresh 는 ApiClient 담당, 오류는 ApiException). 외부 캘린더는 [CalendarApi] 경유.
/// server 엔드포인트가 아직 없는 읽기(주간 요약·집중 통계·스트릭·주간 리뷰)는 목 데이터로 제공한다.
class ApiRepository implements IeoseoRepository {
  ApiRepository(this._client, {CalendarSource? calendar})
    : _calendar = calendar ?? CalendarApi(_client);

  final ApiClient _client;
  final CalendarSource _calendar;

  /// envelope 의 `data` 배열을 안전하게 꺼낸다.
  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _asMap(dynamic data) =>
      data is Map<String, dynamic> ? data : const <String, dynamic>{};

  // ── Events ──────────────────────────────────────────────
  @override
  Future<List<DkEvent>> events() async {
    final dynamic data = await _client.get('/events');
    return _asList(data).map(DkEventDto.fromJson).toList(growable: false);
  }

  @override
  Future<DkEvent> createEvent(DkEvent draft) async {
    final dynamic data = await _client.post(
      '/events',
      body: DkEventDto.toCreateJson(draft),
    );
    return DkEventDto.fromJson(_asMap(data));
  }

  @override
  Future<DkEvent> updateEvent(DkEvent event) async {
    final dynamic data = await _client.put(
      '/events/${event.id}',
      body: DkEventDto.toUpdateJson(event),
    );
    return DkEventDto.fromJson(_asMap(data));
  }

  @override
  Future<void> deleteEvent(String id) => _client.delete('/events/$id');

  @override
  Future<DkEvent> completeEvent(String id) async {
    final dynamic data = await _client.post('/events/$id/complete');
    return DkEventDto.fromJson(_asMap(data));
  }

  @override
  Future<DkEvent> reopenEvent(String id) async {
    final dynamic data = await _client.post('/events/$id/reopen');
    return DkEventDto.fromJson(_asMap(data));
  }

  // ── Tasks ───────────────────────────────────────────────
  @override
  Future<List<DkTask>> tasks({String? date}) async {
    final dynamic data = await _client.get(
      '/tasks',
      query: date == null ? null : <String, dynamic>{'date': date},
    );
    return _asList(data).map(DkTaskDto.fromJson).toList(growable: false);
  }

  @override
  Future<DkTask> createTask(DkTask draft) async {
    final dynamic data = await _client.post(
      '/tasks',
      body: DkTaskDto.toCreateJson(draft),
    );
    return DkTaskDto.fromJson(_asMap(data));
  }

  @override
  Future<DkTask> updateTask(DkTask task) async {
    final dynamic data = await _client.put(
      '/tasks/${task.id}',
      body: DkTaskDto.toUpdateJson(task),
    );
    return DkTaskDto.fromJson(_asMap(data));
  }

  @override
  Future<void> deleteTask(String id) => _client.delete('/tasks/$id');

  @override
  Future<DkTask> completeTask(String id, {int? actualMinutes}) async {
    final dynamic data = await _client.post(
      '/tasks/$id/complete',
      body: <String, dynamic>{'actualMinutes': actualMinutes},
    );
    return DkTaskDto.fromJson(_asMap(data));
  }

  @override
  Future<DkTask> reopenTask(String id) async {
    final dynamic data = await _client.post('/tasks/$id/reopen');
    return DkTaskDto.fromJson(_asMap(data));
  }

  @override
  Future<DkTask> toggleComplete(DkTask task) {
    // 완료 취소는 전용 reopen 엔드포인트로 DONE → TODAY 전이(PUT 은 state 를 안 바꿔 무효).
    if (task.state == DkTaskState.done) {
      return reopenTask(task.id);
    }
    return completeTask(task.id, actualMinutes: task.actualMins);
  }

  @override
  Future<DkTask> carryTask(String id, {required String toDate}) async {
    final dynamic data = await _client.post(
      '/tasks/$id/carry',
      body: <String, dynamic>{'toDate': toDate},
    );
    return DkTaskDto.fromJson(_asMap(data));
  }

  // ── TimeDebts ───────────────────────────────────────────
  @override
  Future<List<DkDebt>> debts({DkDebtStatus? status}) async {
    final dynamic data = await _client.get(
      '/debts',
      query: status == null
          ? null
          : <String, dynamic>{'status': debtStatusToString(status)},
    );
    return _asList(data).map(DkDebtDto.fromJson).toList(growable: false);
  }

  @override
  Future<DkDebt> carryDebt(String id, {required String toDate}) async {
    final dynamic data = await _client.post(
      '/debts/$id/carry',
      body: <String, dynamic>{'toDate': toDate},
    );
    return DkDebtDto.fromJson(_asMap(data));
  }

  @override
  Future<DkDebt> autoCarryDebt(String id) async {
    final dynamic data = await _client.post('/debts/$id/auto-carry');
    return DkDebtDto.fromJson(_asMap(data));
  }

  @override
  Future<DkDebt> abandonDebt(String id) async {
    final dynamic data = await _client.post('/debts/$id/abandon');
    return DkDebtDto.fromJson(_asMap(data));
  }

  // ── 외부 캘린더 연동(server: /calendar/*, 이슈 #59) ─────────
  @override
  Future<List<DkCalendarConnection>> calendarConnections() =>
      _calendar.connections();

  @override
  Future<DkCalendarConnection> connectCalendar(
    DkSource source, {
    String? accessToken,
    String? refreshToken,
  }) => _calendar.connect(
    source,
    accessToken: accessToken,
    refreshToken: refreshToken,
  );

  @override
  Future<void> disconnectCalendar(DkSource source) =>
      _calendar.disconnect(source);

  @override
  Future<List<DkCalendarConnection>> syncCalendars() => _calendar.sync();

  @override
  Future<String> googleCalendarConnectUrl() => _calendar.googleConnectUrl();

  @override
  Future<List<DkExternal>> externalEventsRange({
    required String from,
    required String to,
  }) => _calendar.external(from: from, to: to);

  // ── server 엔드포인트 없는 읽기는 목 데이터로 제공(데모/표현용) ──
  /// 데모용 더미. 캘린더 뷰 실연동은 [externalEventsRange] 를 쓴다(server 조회).
  @override
  List<DkExternal> externalEvents() => kExternal;

  // 주간 요약·집중 통계·포모도로·스트릭은 server 엔드포인트도, 조작 가능한 단일 값도 두지
  // 않는다. 운영 화면은 실데이터에서 파생(main_scaffold `_weekSummary`)하거나 0 으로 둔다.
  // 직접 호출은 잘못된 사용이므로 명시적으로 실패시킨다(조작 상수 반환 금지, F12).
  @override
  DkWeekSummary weekSummary() => throw UnsupportedError(
    '주간 요약은 ApiRepository 가 제공하지 않습니다. 로드된 task/debt 에서 파생하세요.',
  );

  @override
  DkFocusStats focusStats() => throw UnsupportedError(
    '집중 통계는 ApiRepository 가 제공하지 않습니다(server 엔드포인트 없음). 0 으로 두세요.',
  );

  @override
  DkPomodoro pomodoro() => throw UnsupportedError(
    '포모도로 설정은 ApiRepository 가 제공하지 않습니다. settings 또는 기본값을 쓰세요.',
  );

  @override
  int streak() => throw UnsupportedError(
    '스트릭은 ApiRepository 가 제공하지 않습니다(이력 없음). 0 으로 두세요.',
  );

  /// 주간 리뷰는 server 엔드포인트도, 조작 가능한 단일 값도 두지 않는다.
  /// 운영 화면은 로드된 실제 task/debt 에서 파생한다(main_scaffold 의 `_weekReview`).
  /// 직접 호출은 잘못된 사용이므로 명시적으로 실패시킨다(조작 상수 반환 금지).
  @override
  DkWeekReview weekReview() => throw UnsupportedError(
    '주간 리뷰는 ApiRepository 가 제공하지 않습니다. 로드된 task/debt 에서 파생하세요(buildWeekReview).',
  );
}
