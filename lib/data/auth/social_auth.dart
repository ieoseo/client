import 'package:flutter/foundation.dart';

/// 지원하는 소셜 로그인 provider(이슈 #38).
///
/// 서버 계약(`docs/05-API/auth.md`) `POST /auth/oauth/{provider}` 의 경로 세그먼트와
/// 동일한 소문자 식별자를 [wireName]으로 노출한다.
enum SocialProvider {
  /// Google — ID token 기반.
  google,

  /// Apple — identity token(ID token) 기반.
  apple,

  /// Kakao — access token 기반.
  kakao;

  /// 서버 `/auth/oauth/{provider}` 경로에 쓰는 소문자 식별자.
  String get wireName => switch (this) {
    SocialProvider.google => 'google',
    SocialProvider.apple => 'apple',
    SocialProvider.kakao => 'kakao',
  };

  /// 서버에 보낼 토큰 필드명. google/apple = `idToken`, kakao = `accessToken`.
  String get tokenField => switch (this) {
    SocialProvider.google || SocialProvider.apple => 'idToken',
    SocialProvider.kakao => 'accessToken',
  };
}

/// provider SDK가 돌려준 토큰. 서버 `/auth/oauth/{provider}` 요청 본문 1개 필드로 매핑된다.
///
/// 토큰 평문은 로깅하지 않는다([toString]에서 마스킹).
@immutable
class SocialToken {
  const SocialToken({required this.provider, required this.value});

  final SocialProvider provider;

  /// google/apple = ID token, kakao = access token.
  final String value;

  /// 서버 요청 본문(`{idToken: ...}` 또는 `{accessToken: ...}`).
  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    provider.tokenField: value,
  };

  @override
  String toString() => 'SocialToken(${provider.wireName}, <masked>)';
}

/// 사용자가 소셜 로그인 흐름을 직접 취소했음을 나타내는 신호(이슈 #38).
///
/// 취소는 오류가 아니라 정상 흐름이다 — UI는 이 예외를 **조용히 무시**하고
/// 토스트를 띄우지 않는다. SDK별 취소 코드를 이 공통 타입으로 정규화한다.
class SocialSignInCancelled implements Exception {
  const SocialSignInCancelled([this.provider]);

  /// 취소가 발생한 provider(있으면).
  final SocialProvider? provider;

  @override
  String toString() => 'SocialSignInCancelled(${provider?.wireName ?? '?'})';
}

/// 해당 provider의 키(`--dart-define`)가 설정되지 않아 소셜 로그인을 진행할 수 없음.
/// UI는 이 예외를 "준비 중 — 이메일로 가입" 안내로 처리하고 **수동 로그인으로 폴백**한다.
class SocialNotConfigured implements Exception {
  const SocialNotConfigured(this.provider);

  final SocialProvider provider;

  @override
  String toString() => 'SocialNotConfigured(${provider.wireName})';
}

/// 소셜 토큰 획득 추상화(이슈 #38).
///
/// 실제 네이티브 SDK(google_sign_in/sign_in_with_apple/kakao) 호출을 이 인터페이스
/// 뒤로 감춘다. [AuthController.oauthSignIn]은 이 추상화에만 의존하므로 단위 테스트는
/// 가짜 구현을 주입해 SDK 없이 검증할 수 있다.
///
/// 규약:
/// - 성공 시 [SocialToken] 반환.
/// - 사용자가 취소하면 [SocialSignInCancelled] 던짐(오류 아님 — UI가 무시).
/// - 그 외 실패는 일반 [Exception] 던짐(UI가 토스트로 표시).
abstract class SocialTokenProvider {
  /// 지정 [provider]의 SDK 흐름을 실행해 토큰을 획득한다.
  Future<SocialToken> getToken(SocialProvider provider);
}
