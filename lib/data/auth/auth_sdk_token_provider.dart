import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'social_auth.dart';

/// 소셜 로그인 SDK 구성값(이슈 #38).
///
/// 실제 키는 코드에 박지 않는다 — `--dart-define`로 주입한다(없으면 빈 문자열).
/// 네이티브 키(iOS reversed client id, Kakao native app key 등)는 플랫폼 설정 파일
/// (Info.plist/AndroidManifest)에서 별도로 관리한다. 여기 값은 Dart 측 초기화용이다.
class SocialAuthConfig {
  const SocialAuthConfig({
    this.googleServerClientId,
    this.googleIosClientId,
    this.kakaoNativeAppKey,
  });

  /// 서버 검증용 Google OAuth client id(audience). server client id를 넣어야
  /// idToken 의 aud 가 서버와 맞는다. `--dart-define=GOOGLE_SERVER_CLIENT_ID`.
  final String? googleServerClientId;

  /// iOS Google OAuth client id. `--dart-define=GOOGLE_IOS_CLIENT_ID`.
  final String? googleIosClientId;

  /// Kakao native app key. `--dart-define=KAKAO_NATIVE_APP_KEY`.
  final String? kakaoNativeAppKey;

  /// Google 서버(웹) OAuth client id 기본값. 공개값(시크릿 아님)이라 코드에 둔다 →
  /// 릴리스 빌드가 별도 주입 없이 Google 로그인을 켠다. 서버 GOOGLE_CLIENT_ID 와 동일 값.
  static const String _kDefaultGoogleServerClientId =
      '621764515915-jm6hb02cfc13gd7i0u2ma5d7k9ga5fpu.apps.googleusercontent.com';

  /// `--dart-define` 환경에서 구성값을 읽어 만든다(Google 은 기본값으로 활성).
  factory SocialAuthConfig.fromEnvironment() {
    const String google = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: _kDefaultGoogleServerClientId,
    );
    const String googleIos = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    const String kakao = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
    return SocialAuthConfig(
      googleServerClientId: google.isEmpty ? null : google,
      googleIosClientId: googleIos.isEmpty ? null : googleIos,
      kakaoNativeAppKey: kakao.isEmpty ? null : kakao,
    );
  }
}

/// 네이티브 SDK를 호출하는 [SocialTokenProvider] 구현(이슈 #38).
///
/// google_sign_in / sign_in_with_apple / kakao_flutter_sdk_user 를 각 provider별로
/// 호출해 토큰을 얻고, 취소는 [SocialSignInCancelled]로, 그 외 실패는 일반
/// [Exception]으로 정규화한다. 단위 테스트는 이 클래스 대신 가짜 provider를 주입한다
/// (네이티브 호출은 테스트에서 직접 실행하지 않는다).
///
/// 토큰 평문은 로깅하지 않는다.
class AuthSdkTokenProvider implements SocialTokenProvider {
  AuthSdkTokenProvider({this.config = const SocialAuthConfig()});

  final SocialAuthConfig config;

  bool _googleInitialized = false;
  bool _kakaoInitialized = false;

  @override
  Future<SocialToken> getToken(SocialProvider provider) {
    return switch (provider) {
      SocialProvider.google => _google(),
      SocialProvider.apple => _apple(),
      SocialProvider.kakao => _kakao(),
    };
  }

  /// Google: initialize → authenticate → idToken.
  Future<SocialToken> _google() async {
    // 키 미설정이면 수동 로그인으로 폴백하도록 신호한다.
    if (config.googleServerClientId == null &&
        config.googleIosClientId == null) {
      throw const SocialNotConfigured(SocialProvider.google);
    }
    final GoogleSignIn signIn = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await signIn.initialize(
        clientId: config.googleIosClientId,
        serverClientId: config.googleServerClientId,
      );
      _googleInitialized = true;
    }
    try {
      final GoogleSignInAccount account = await signIn.authenticate(
        scopeHint: const <String>['email'],
      );
      final String? idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google idToken 을 받지 못했어요.');
      }
      return SocialToken(provider: SocialProvider.google, value: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialSignInCancelled(SocialProvider.google);
      }
      rethrow;
    }
  }

  /// Apple: getAppleIDCredential → identityToken(=ID token).
  Future<SocialToken> _apple() async {
    try {
      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
            scopes: const <AppleIDAuthorizationScopes>[
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
          );
      final String? identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Apple identityToken 을 받지 못했어요.');
      }
      return SocialToken(provider: SocialProvider.apple, value: identityToken);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const SocialSignInCancelled(SocialProvider.apple);
      }
      rethrow;
    }
  }

  /// Kakao: 카카오톡 설치 시 앱, 미설치 시 카카오계정 웹 → access token.
  Future<SocialToken> _kakao() async {
    _ensureKakaoInitialized();
    try {
      final OAuthToken token = await isKakaoTalkInstalled()
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();
      return SocialToken(
        provider: SocialProvider.kakao,
        value: token.accessToken,
      );
    } on KakaoClientException catch (e) {
      // 카카오톡 앱 로그인에서 사용자가 취소한 경우.
      if (e.reason == ClientErrorCause.cancelled) {
        throw const SocialSignInCancelled(SocialProvider.kakao);
      }
      rethrow;
    } on KakaoAuthException catch (e) {
      // 카카오계정 웹 동의 화면에서 거부(access_denied)한 경우.
      if (e.error == AuthErrorCause.accessDenied) {
        throw const SocialSignInCancelled(SocialProvider.kakao);
      }
      rethrow;
    }
  }

  void _ensureKakaoInitialized() {
    if (_kakaoInitialized) return;
    final String? key = config.kakaoNativeAppKey;
    if (key == null || key.isEmpty) {
      throw const SocialNotConfigured(SocialProvider.kakao);
    }
    KakaoSdk.init(nativeAppKey: key);
    _kakaoInitialized = true;
  }
}
