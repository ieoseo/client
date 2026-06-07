import 'package:ieoseo/data/auth/social_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_social_token_provider.dart';

void main() {
  group('SocialProvider', () {
    test('wireName 은 서버 경로 세그먼트 소문자', () {
      expect(SocialProvider.google.wireName, 'google');
      expect(SocialProvider.apple.wireName, 'apple');
      expect(SocialProvider.kakao.wireName, 'kakao');
    });

    test('tokenField: google/apple=idToken, kakao=accessToken', () {
      expect(SocialProvider.google.tokenField, 'idToken');
      expect(SocialProvider.apple.tokenField, 'idToken');
      expect(SocialProvider.kakao.tokenField, 'accessToken');
    });
  });

  group('SocialToken', () {
    test('toRequestBody: google → {idToken}', () {
      const SocialToken token = SocialToken(
        provider: SocialProvider.google,
        value: 'g-id-token',
      );
      expect(token.toRequestBody(), <String, dynamic>{'idToken': 'g-id-token'});
    });

    test('toRequestBody: kakao → {accessToken}', () {
      const SocialToken token = SocialToken(
        provider: SocialProvider.kakao,
        value: 'k-access-token',
      );
      expect(token.toRequestBody(), <String, dynamic>{
        'accessToken': 'k-access-token',
      });
    });

    test('toString 은 토큰 평문을 노출하지 않는다(마스킹)', () {
      const SocialToken token = SocialToken(
        provider: SocialProvider.apple,
        value: 'super-secret-identity-token',
      );
      expect(token.toString(), isNot(contains('super-secret')));
      expect(token.toString(), contains('masked'));
    });
  });

  group('FakeSocialTokenProvider', () {
    test('성공 시 요청한 provider 토큰 반환 + 호출 기록', () async {
      final FakeSocialTokenProvider fake = FakeSocialTokenProvider(
        token: 't-1',
      );

      final SocialToken token = await fake.getToken(SocialProvider.google);

      expect(token.provider, SocialProvider.google);
      expect(token.value, 't-1');
      expect(fake.calls, <SocialProvider>[SocialProvider.google]);
    });

    test('cancel=true → SocialSignInCancelled', () {
      final FakeSocialTokenProvider fake = FakeSocialTokenProvider(
        cancel: true,
      );

      expect(
        () => fake.getToken(SocialProvider.kakao),
        throwsA(isA<SocialSignInCancelled>()),
      );
    });

    test('error 지정 → 해당 예외 전파', () {
      final FakeSocialTokenProvider fake = FakeSocialTokenProvider(
        error: Exception('sdk boom'),
      );

      expect(
        () => fake.getToken(SocialProvider.apple),
        throwsA(isA<Exception>()),
      );
    });
  });
}
