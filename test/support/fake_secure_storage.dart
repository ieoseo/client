import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 인메모리 [FlutterSecureStorage] 가짜. 토큰 저장/복원 로직을 서버·OS 없이 검증.
///
/// flutter_secure_storage의 read/write/delete만 오버라이드한다(테스트에 필요한 표면).
class FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _map = <String, String>{};

  Map<String, String> get snapshot => Map<String, String>.unmodifiable(_map);

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _map[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _map.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
