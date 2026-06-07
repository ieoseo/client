import '../models.dart';
import 'api_client.dart';

/// 외부 캘린더 연동·동기화 데이터 소스 추상화(이슈 #59).
///
/// 구현은 [CalendarApi](server 연동) / 테스트 가짜. 인증 헤더·envelope 언랩·401 refresh 는
/// [ApiClient] 가 담당하며, 오류는 ApiException. 토큰은 요청으로만 보내고 응답엔 없다.
abstract class CalendarSource {
  /// 연결 목록(server: GET /calendar/connections).
  Future<List<DkCalendarConnection>> connections();

  /// 연결 등록/갱신(server: POST /calendar/connections/{provider}). 토큰/보조값 전달.
  Future<DkCalendarConnection> connect(
    DkSource source, {
    String? accessToken,
    String? refreshToken,
  });

  /// 연결 해제(server: DELETE /calendar/connections/{provider} → 204).
  Future<void> disconnect(DkSource source);

  /// 수동 동기화(server: POST /calendar/sync). 갱신된 연결 목록을 반환한다.
  Future<List<DkCalendarConnection>> sync();

  /// 외부 일정 범위 조회(server: GET /calendar/external?from&to). ISO ymd.
  Future<List<DkExternal>> external({required String from, required String to});
}

/// server 캘린더 REST 를 호출하는 [CalendarSource] 구현(이슈 #59).
class CalendarApi implements CalendarSource {
  const CalendarApi(this._client);

  final ApiClient _client;

  @override
  Future<List<DkCalendarConnection>> connections() async {
    final dynamic data = await _client.get('/calendar/connections');
    return _asList(data).map(_connectionFromJson).toList(growable: false);
  }

  @override
  Future<DkCalendarConnection> connect(
    DkSource source, {
    String? accessToken,
    String? refreshToken,
  }) async {
    final String code = (calendarProviderCode(source) ?? '').toLowerCase();
    final dynamic data = await _client.post(
      '/calendar/connections/$code',
      body: <String, dynamic>{
        'accessToken': ?accessToken,
        'refreshToken': ?refreshToken,
      },
    );
    return _connectionFromJson(_asMap(data));
  }

  @override
  Future<void> disconnect(DkSource source) {
    final String code = (calendarProviderCode(source) ?? '').toLowerCase();
    return _client.delete('/calendar/connections/$code');
  }

  @override
  Future<List<DkCalendarConnection>> sync() async {
    final dynamic data = await _client.post('/calendar/sync');
    // sync 응답은 provider별 결과(SyncResultResponse). 상태/시각만 연결 모델로 환원한다.
    return _asList(data).map(_connectionFromSyncResult).toList(growable: false);
  }

  @override
  Future<List<DkExternal>> external({
    required String from,
    required String to,
  }) async {
    final dynamic data = await _client.get(
      '/calendar/external',
      query: <String, dynamic>{'from': from, 'to': to},
    );
    return _asList(data).map(_externalFromJson).toList(growable: false);
  }

  // ── 매핑 ────────────────────────────────────────────────

  DkCalendarConnection _connectionFromJson(Map<String, dynamic> json) =>
      DkCalendarConnection(
        source: calendarSourceFromCode(json['provider'] as String?),
        status: _statusFromCode(json['status'] as String?),
        lastSyncedAt: json['lastSyncedAt'] as String?,
      );

  DkCalendarConnection _connectionFromSyncResult(Map<String, dynamic> json) =>
      DkCalendarConnection(
        source: calendarSourceFromCode(json['provider'] as String?),
        status: _statusFromCode(json['status'] as String?),
        lastSyncedAt: json['syncedAt'] as String?,
      );

  DkExternal _externalFromJson(Map<String, dynamic> json) => DkExternal(
    id: (json['id'] as String?) ?? '',
    title: (json['title'] as String?) ?? '',
    date: (json['date'] as String?) ?? '',
    time: (json['time'] as String?) ?? '', // 종일이면 '' (DkExternal.time 비널)
    source: calendarSourceFromCode(json['provider'] as String?),
  );

  DkConnectionStatus _statusFromCode(String? code) => switch (code) {
    'CONNECTED' => DkConnectionStatus.connected,
    'SYNC_FAILED' => DkConnectionStatus.syncFailed,
    _ => DkConnectionStatus.none,
  };

  List<Map<String, dynamic>> _asList(dynamic data) => data is List
      ? data.whereType<Map<String, dynamic>>().toList(growable: false)
      : const <Map<String, dynamic>>[];

  Map<String, dynamic> _asMap(dynamic data) =>
      data is Map<String, dynamic> ? data : const <String, dynamic>{};
}
