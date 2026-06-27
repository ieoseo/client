import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform;
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

  /// 세션 토큰 재발급(401 재시도용). 성공 시 새 access, 실패 시 null.
  Future<String?> refreshAccessToken();

  /// 로그아웃 — Supabase 세션 종료(로컬 토큰 폐기).
  Future<void> signOut();

  /// 현재 사용자에 연동된 provider 이름 집합(예: {'email','google','kakao'}). 세션 없으면 빈 집합.
  Set<String> get linkedProviders;

  /// 사용자 정보(연동 identity 포함) 변경 통지. 연동 추가(linkOAuth) 완료 시 발행될 수 있다.
  Stream<void> get onUserUpdated;

  /// 현재 계정에 소셜 provider 를 추가 연동(`linkIdentity`, 브라우저 + 딥링크).
  /// 완료는 비동기다 — [onUserUpdated] 로 통지된다. Supabase 'Manual Linking' 활성 필요.
  Future<void> linkOAuth(SocialProvider provider);

  /// 연동된 소셜 provider 를 해제(`unlinkIdentity`). 연동 안 됐거나 마지막 identity 면 예외.
  Future<void> unlinkOAuth(SocialProvider provider);

  /// 서버에서 최신 사용자(연동 identity 포함)를 다시 읽어 로컬 세션을 갱신한다.
  Future<void> reloadUser();
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

  /// provider → (Supabase OAuthProvider, 요청 scope). Kakao 는 닉네임만 요청
  /// (account_email 은 KOE205 회피, server email nullable).
  (OAuthProvider, String?) _oauthSpec(SocialProvider provider) =>
      switch (provider) {
        SocialProvider.google => (OAuthProvider.google, null),
        SocialProvider.kakao => (OAuthProvider.kakao, 'profile_nickname'),
        SocialProvider.apple => (OAuthProvider.apple, null),
      };

  @override
  Future<void> signInWithOAuth(SocialProvider provider) async {
    final (OAuthProvider oauth, String? scopes) = _oauthSpec(provider);
    await _auth.signInWithOAuth(
      oauth,
      redirectTo: kSupabaseRedirectUri,
      scopes: scopes,
      authScreenLaunchMode: _authLaunchMode,
    );
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

  @override
  Set<String> get linkedProviders =>
      _authOrNull?.currentUser?.identities
          ?.map((UserIdentity i) => i.provider)
          .toSet() ??
      const <String>{};

  @override
  Stream<void> get onUserUpdated {
    final GoTrueClient? auth = _authOrNull;
    if (auth == null) return const Stream<void>.empty();
    return auth.onAuthStateChange
        .where((AuthState data) => data.event == AuthChangeEvent.userUpdated)
        .map((_) {});
  }

  @override
  Future<void> linkOAuth(SocialProvider provider) async {
    final (OAuthProvider oauth, String? scopes) = _oauthSpec(provider);
    await _auth.linkIdentity(
      oauth,
      redirectTo: kSupabaseRedirectUri,
      scopes: scopes,
      authScreenLaunchMode: _authLaunchMode,
    );
  }

  @override
  Future<void> unlinkOAuth(SocialProvider provider) async {
    final String name = provider.wireName;
    final List<UserIdentity> identities =
        _auth.currentUser?.identities ?? const <UserIdentity>[];
    final Iterable<UserIdentity> matches = identities.where(
      (UserIdentity i) => i.provider == name,
    );
    if (matches.isEmpty) {
      throw StateError('연동되지 않은 계정이에요.');
    }
    await _auth.unlinkIdentity(matches.first);
    await reloadUser();
  }

  @override
  Future<void> reloadUser() async {
    try {
      await _auth.refreshSession();
    } on Exception catch (e) {
      // 세션 갱신 실패는 무시(다음 요청 401 처리에 위임). AuthException 뿐 아니라
      // 네트워크 예외(SocketException·타임아웃 등)까지 흡수해, 호출부(onUserUpdated·
      // unlinkOAuth)의 스트림 구독이 끊기지 않게 한다.
      debugPrint('Supabase reloadUser(refreshSession) 실패(흡수): $e');
    }
  }
}
