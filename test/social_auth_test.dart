import 'package:ieoseo/data/auth/social_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// 소셜은 Supabase signInWithOAuth(웹 흐름)로 처리(ADR-0014).
/// 여기서는 표시/식별용 [SocialProvider] 와 취소·미구성 신호만 검증한다.
void main() {
  group('SocialProvider', () {
    test('wireName 은 소문자 식별자', () {
      expect(SocialProvider.google.wireName, 'google');
      expect(SocialProvider.apple.wireName, 'apple');
      expect(SocialProvider.kakao.wireName, 'kakao');
    });
  });

  group('신호 예외', () {
    test('SocialSignInCancelled toString 에 provider 포함', () {
      const SocialSignInCancelled c = SocialSignInCancelled(
        SocialProvider.kakao,
      );
      expect(c.toString(), contains('kakao'));
    });

    test('SocialNotConfigured toString 에 provider 포함', () {
      const SocialNotConfigured n = SocialNotConfigured(SocialProvider.google);
      expect(n.toString(), contains('google'));
    });
  });
}
