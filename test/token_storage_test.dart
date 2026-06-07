import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/auth/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_secure_storage.dart';

void main() {
  late FakeSecureStorage fake;
  late TokenStorage storage;

  setUp(() {
    fake = FakeSecureStorage();
    storage = TokenStorage(storage: fake);
  });

  test('save → 보안 저장소 키에 access/refresh를 기록한다', () async {
    await storage.save(accessToken: 'acc-1', refreshToken: 'ref-1');

    expect(fake.snapshot[kAccessTokenKey], 'acc-1');
    expect(fake.snapshot[kRefreshTokenKey], 'ref-1');
  });

  test('readAccess/readRefresh → 저장값을 읽는다', () async {
    await storage.save(accessToken: 'acc-1', refreshToken: 'ref-1');

    expect(await storage.readAccess(), 'acc-1');
    expect(await storage.readRefresh(), 'ref-1');
  });

  test('비어 있으면 null을 반환한다', () async {
    expect(await storage.readAccess(), isNull);
    expect(await storage.readRefresh(), isNull);
  });

  test('clear → 토큰을 모두 삭제한다', () async {
    await storage.save(accessToken: 'acc-1', refreshToken: 'ref-1');

    await storage.clear();

    expect(fake.snapshot.containsKey(kAccessTokenKey), isFalse);
    expect(fake.snapshot.containsKey(kRefreshTokenKey), isFalse);
  });

  test('hasSession → refresh 존재 여부로 판단한다', () async {
    expect(await storage.hasSession(), isFalse);
    await storage.save(accessToken: 'acc-1', refreshToken: 'ref-1');
    expect(await storage.hasSession(), isTrue);
  });
}
