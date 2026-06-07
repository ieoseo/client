import 'package:flutter/foundation.dart';

import 'api/api_exception.dart';
import 'api/settings_api.dart';
import 'api/settings_dto.dart';

/// 사용자 설정 상태 컨트롤러(이슈 #56).
///
/// [SettingsSource] 위에 현재 설정·로딩/오류 상태를 얹는다. 진입 시 [load]로 서버 설정을 읽고,
/// 토글/값 변경은 [save]로 낙관적 저장한다(로컬 먼저 반영 → 실패 시 스냅샷 롤백 + ApiException 재던지기).
class SettingsController extends ChangeNotifier {
  SettingsController(this._source);

  final SettingsSource _source;

  DkSettings _settings = const DkSettings();
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  /// 현재 설정(로드 전이면 기본값).
  DkSettings get settings => _settings;
  bool get isLoading => _loading;

  /// 최초 로드 성공 여부(화면이 기본값/실값을 구분).
  bool get isLoaded => _loaded;
  String? get error => _error;

  /// 서버 설정을 로드한다. 실패 시 [error] 를 채우고 기본값을 유지한다.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _settings = await _source.get();
      _loaded = true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = '설정을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 설정 저장(낙관적). 로컬을 먼저 [next] 로 바꾸고 PUT 한다. 실패 시 이전 값으로 롤백하고
  /// [ApiException] 을 다시 던진다(화면이 토스트로 안내).
  Future<void> save(DkSettings next) async {
    final DkSettings snapshot = _settings;
    if (next == snapshot) return;
    _settings = next;
    notifyListeners();
    try {
      _settings = await _source.put(next);
      _loaded = true;
      notifyListeners();
    } on ApiException {
      _settings = snapshot;
      notifyListeners();
      rethrow;
    }
  }
}
