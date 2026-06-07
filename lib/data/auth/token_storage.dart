import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_config.dart';

/// access/refresh 토큰을 OS 보안 저장소(Keychain/Keystore)에 보관(이슈 #32).
///
/// 보안 규칙: 토큰은 flutter_secure_storage만 사용(SharedPreferences 금지),
/// 평문 로깅 금지. 테스트를 위해 [FlutterSecureStorage]를 주입받는다.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// access 토큰 읽기(없으면 null).
  Future<String?> readAccess() => _storage.read(key: kAccessTokenKey);

  /// refresh 토큰 읽기(없으면 null).
  Future<String?> readRefresh() => _storage.read(key: kRefreshTokenKey);

  /// access/refresh 토큰 저장.
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: kAccessTokenKey, value: accessToken);
    await _storage.write(key: kRefreshTokenKey, value: refreshToken);
  }

  /// 저장된 토큰 전체 삭제(로그아웃/세션 폐기).
  Future<void> clear() async {
    await _storage.delete(key: kAccessTokenKey);
    await _storage.delete(key: kRefreshTokenKey);
  }

  /// 복원 가능한 세션이 있는지(refresh 토큰 존재 여부).
  Future<bool> hasSession() async {
    final String? refresh = await readRefresh();
    return refresh != null && refresh.isNotEmpty;
  }
}
