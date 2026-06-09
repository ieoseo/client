/// 지원하는 소셜 로그인 provider(ADR-0014).
///
/// 인증은 Supabase `signInWithOAuth`(웹 흐름)로 처리한다. [wireName]은 로그인 버튼 식별 등
/// 표시·키 용도의 소문자 식별자다.
enum SocialProvider {
  /// Google.
  google,

  /// Apple.
  apple,

  /// Kakao.
  kakao;

  /// 소문자 식별자(버튼 key 등).
  String get wireName => switch (this) {
    SocialProvider.google => 'google',
    SocialProvider.apple => 'apple',
    SocialProvider.kakao => 'kakao',
  };
}

/// 사용자가 소셜 로그인 흐름을 직접 취소했음을 나타내는 신호.
///
/// 취소는 오류가 아니라 정상 흐름이다 — UI는 이 예외를 **조용히 무시**한다.
class SocialSignInCancelled implements Exception {
  const SocialSignInCancelled([this.provider]);

  /// 취소가 발생한 provider(있으면).
  final SocialProvider? provider;

  @override
  String toString() => 'SocialSignInCancelled(${provider?.wireName ?? '?'})';
}

/// 해당 provider 가 아직 구성되지 않아 소셜 로그인을 진행할 수 없음.
/// UI는 안내 메시지로 처리한다.
class SocialNotConfigured implements Exception {
  const SocialNotConfigured(this.provider);

  final SocialProvider provider;

  @override
  String toString() => 'SocialNotConfigured(${provider.wireName})';
}
