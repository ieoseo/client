import 'api_client.dart';
import 'settings_dto.dart';

/// 사용자 설정 데이터 소스 추상화(이슈 #56). 구현은 [SettingsApi](server 연동) / 테스트 가짜.
abstract class SettingsSource {
  /// 설정 조회(server: GET /auth/me/settings, 없으면 기본값).
  Future<DkSettings> get();

  /// 설정 전체 저장(server: PUT /auth/me/settings).
  Future<DkSettings> put(DkSettings settings);
}

/// server 설정 REST 를 호출하는 [SettingsSource] 구현(이슈 #56).
///
/// 인증 헤더·envelope 언랩·401 refresh 는 [ApiClient] 가 담당하며, 오류는 ApiException.
class SettingsApi implements SettingsSource {
  const SettingsApi(this._client);

  final ApiClient _client;

  @override
  Future<DkSettings> get() async {
    final dynamic data = await _client.get('/auth/me/settings');
    return DkSettings.fromJson(_asMap(data));
  }

  @override
  Future<DkSettings> put(DkSettings settings) async {
    final dynamic data = await _client.put(
      '/auth/me/settings',
      body: settings.toJson(),
    );
    return DkSettings.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(dynamic data) =>
      data is Map<String, dynamic> ? data : const <String, dynamic>{};
}
