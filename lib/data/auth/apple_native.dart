import 'dart:convert' show utf8;
import 'dart:math' show Random;

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'social_auth.dart';

/// iOS 네이티브 Sign in with Apple 지원(ADR-0014 의 네이티브 idToken 경로).
///
/// 웹 OAuth(`signInWithOAuth`)와 달리, iOS 에서는 Apple 심사 가이드라인 4.8 에 맞춰
/// 네이티브 시트로 받은 `identityToken` 을 Supabase `signInWithIdToken` 에 넘긴다.
/// 여기 모인 함수들은 SDK 없이 단위 테스트가 가능하도록 순수하게 둔다(난수·해시·판단).

const String _nonceCharset =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/// Apple/Supabase 가 요구하는 replay 방지용 raw nonce 를 만든다(url-safe 영숫자).
/// 호출부는 이 raw 를 [sha256OfString] 으로 해시해 Apple 에 보내고,
/// raw 자체는 Supabase `signInWithIdToken(nonce:)` 로 보낸다.
String generateRawNonce([int length = 32]) {
  final random = Random.secure();
  return List<String>.generate(
    length,
    (_) => _nonceCharset[random.nextInt(_nonceCharset.length)],
  ).join();
}

/// 입력 문자열의 SHA-256 16진 다이제스트(소문자)를 반환한다.
String sha256OfString(String input) =>
    sha256.convert(utf8.encode(input)).toString();

/// 해당 provider/플랫폼 조합에서 네이티브 Apple 로그인을 써야 하는지.
/// iOS + Apple 일 때만 true(그 외는 기존 웹 OAuth 유지). Google/Kakao 는 항상 웹.
bool shouldUseNativeApple(SocialProvider provider, TargetPlatform platform) =>
    provider == SocialProvider.apple && platform == TargetPlatform.iOS;

/// 네이티브 Apple 자격증명에서 `identityToken` 을 받는 얇은 어댑터.
/// 게이트웨이가 이 인터페이스에 의존해 테스트 시 가짜를 주입할 수 있게 한다.
abstract interface class AppleNativeSignIn {
  /// 해시된 nonce 로 Apple 네이티브 시트를 띄우고 `identityToken` 을 반환한다.
  /// 사용자가 취소하면 [SignInWithAppleAuthorizationException] 이 전파된다.
  Future<String> idToken({required String hashedNonce});
}

/// `sign_in_with_apple` 플러그인 기반 실제 구현.
class SignInWithApplePlugin implements AppleNativeSignIn {
  const SignInWithApplePlugin();

  @override
  Future<String> idToken({required String hashedNonce}) async {
    final AuthorizationCredentialAppleID credential =
        await SignInWithApple.getAppleIDCredential(
          scopes: const <AppleIDAuthorizationScopes>[
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );
    final String? token = credential.identityToken;
    if (token == null) {
      throw StateError('Apple identityToken 이 비어 있어요.');
    }
    return token;
  }
}
