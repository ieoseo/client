import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'social_auth.dart';
import 'supabase_config.dart';

/// Supabase 인증 세션 게이트웨이(ADR-0014).
///
/// 서버는 Supabase JWT 를 JWKS 로 **검증만** 한다. client 는 Supabase 가 발급·보관·갱신하는
/// 세션 토큰을 들고 서버 API 에 Bearer 로 보낸다. 이 추상화 뒤로 `supabase_flutter` 호출을
/// 감춰, 단위 테스트가 가짜 구현을 주입해 네이티브/네트워크 없이 검증할 수 있게 한다.
///
/// 토큰 평문은 로깅하지 않는다.
abstract class SupabaseAuthGateway {
  /// 현재 세션 access 토큰(없으면 null). 서버 요청 Bearer 에 쓴다.
  String? get accessToken;

  /// 복원 가능한 세션이 있는지(부팅 시 supabase_flutter 가 자동 복원한 세션 포함).
  bool get hasSession;

  /// 외부 OAuth(Kakao 등) 딥링크 복귀로 세션이 생성된 순간을 알린다.
  /// AuthController 가 구독해 server `/auth/me` provisioning 을 수행한다.
  Stream<void> get onSignedIn;

  /// 소셜 OAuth(Google/Kakao 등) 브라우저 흐름을 시작한다(`signInWithOAuth`).
  /// 인증은 Supabase(web client)가 처리하고 앱은 딥링크로 복귀한다 — 앱 내 client id 불필요.
  /// 세션 완성은 비동기다 — 완료는 [onSignedIn] 으로 통지된다(ADR-0014).
  Future<void> signInWithOAuth(SocialProvider provider);

  /// 이메일+비밀번호 회원가입(`signUp`). Confirm email OFF 면 즉시 세션이 생긴다.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });

  /// 이메일+비밀번호 로그인(`signInWithPassword`).
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// 세션 토큰 재발급(401 재시도용). 성공 시 새 access, 실패 시 null.
  Future<String?> refreshAccessToken();

  /// 로그아웃 — Supabase 세션 종료(로컬 토큰 폐기).
  Future<void> signOut();
}

/// `supabase_flutter` 기반 실제 구현.
///
/// [Supabase.instance] 접근은 메서드 호출 시점으로 지연한다(생성자에서 초기화 전
/// 인스턴스를 건드리지 않도록). 단위 테스트는 [auth] 를 주입한다.
class SupabaseAuthGatewayImpl implements SupabaseAuthGateway {
  SupabaseAuthGatewayImpl({GoTrueClient? auth}) : _injected = auth;

  final GoTrueClient? _injected;

  /// Supabase 가 초기화되지 않았으면(예: 서버 없이 UI 점검하는 main_dev) null 을 돌려준다.
  /// 생성자에서 [onSignedIn] 구독 등 읽기 접근이 크래시 나지 않도록 방어한다.
  GoTrueClient? get _authOrNull {
    final GoTrueClient? injected = _injected;
    if (injected != null) return injected;
    try {
      return Supabase.instance.client.auth;
    } catch (_) {
      return null;
    }
  }

  GoTrueClient get _auth =>
      _authOrNull ?? (throw StateError('Supabase 가 초기화되지 않았어요.'));

  @override
  String? get accessToken => _authOrNull?.currentSession?.accessToken;

  @override
  bool get hasSession => _authOrNull?.currentSession != null;

  @override
  Stream<void> get onSignedIn {
    final GoTrueClient? auth = _authOrNull;
    if (auth == null) return const Stream<void>.empty();
    return auth.onAuthStateChange
        .where((AuthState data) => data.event == AuthChangeEvent.signedIn)
        .map((_) {});
  }

  /// 인증 브라우저 런치 모드. iOS 는 in-app SFSafariViewController 가 딥링크 복귀 후
  /// 자동으로 닫히지 않아 빈 브라우저가 남으므로(supabase_flutter 가 closeInAppWebView 미호출)
  /// 외부 브라우저로 연다. Android 는 Custom Tab(platformDefault)이 리다이렉트 시 자동으로
  /// 닫히므로 기본을 유지한다.
  LaunchMode get _authLaunchMode => defaultTargetPlatform == TargetPlatform.iOS
      ? LaunchMode.externalApplication
      : LaunchMode.platformDefault;

  @override
  Future<void> signInWithOAuth(SocialProvider provider) async {
    // Kakao 는 닉네임만 요청(account_email 은 KOE205 회피, server email nullable).
    final (OAuthProvider oauth, String? scopes) = switch (provider) {
      SocialProvider.google => (OAuthProvider.google, null),
      SocialProvider.kakao => (OAuthProvider.kakao, 'profile_nickname'),
      SocialProvider.apple => (OAuthProvider.apple, null),
    };
    await _auth.signInWithOAuth(
      oauth,
      redirectTo: kSupabaseRedirectUri,
      scopes: scopes,
      authScreenLaunchMode: _authLaunchMode,
    );
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<String?> refreshAccessToken() async {
    try {
      final AuthResponse res = await _auth.refreshSession();
      return res.session?.accessToken;
    } on AuthException {
      return null;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
