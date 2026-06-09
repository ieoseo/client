import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/auth_api.dart';
import '../api/auth_dto.dart';
import 'social_auth.dart';
import 'supabase_auth_gateway.dart';

/// 인증 진입 상태(이슈 #32).
enum AuthStatus {
  /// 부팅 직후 — 세션 복원 시도 중(스플래시/대기).
  unknown,

  /// 유효 세션 — main 진입.
  authenticated,

  /// 세션 없음 — 인증 화면.
  unauthenticated,
}

/// 인증 상태 + 세션 복원을 관리하는 컨트롤러(이슈 #32, ADR-0014).
///
/// 인증은 Supabase Auth 다 — 로그인·세션·토큰은 [SupabaseAuthGateway] 뒤의
/// `supabase_flutter` 가 담당하고, server 는 그 JWT 를 JWKS 로 검증만 한다. 이 컨트롤러는
/// 소셜 로그인 후 server `/auth/me` 로 사용자 provisioning 을 받아 [status]/[user] 를 노출한다.
///
/// 두 가지 로그인 경로:
/// - **Google**: 네이티브 idToken → `signInWithIdToken`(동기 세션) → 즉시 `/auth/me`.
/// - **Kakao**: `signInWithOAuth`(브라우저 + 딥링크, 비동기) → 복귀 시 [SupabaseAuthGateway.onSignedIn]
///   이벤트로 `/auth/me`.
///
/// 토큰 평문은 로깅하지 않는다.
class AuthController extends ChangeNotifier {
  AuthController({
    SupabaseAuthGateway? gateway,
    AuthApi? api,
    ApiClient? client,
  }) : _gateway = gateway ?? SupabaseAuthGatewayImpl() {
    _client =
        client ??
        ApiClient(
          accessTokenReader: () async => _gateway.accessToken,
          tokenRefresher: _gateway.refreshAccessToken,
        );
    _api = api ?? AuthApi(_client);
    // OAuth(딥링크) 복귀로 세션이 생기면 server provisioning 을 수행한다.
    _signInSub = _gateway.onSignedIn.listen((_) => _onExternalSignIn());
  }

  final SupabaseAuthGateway _gateway;
  late final ApiClient _client;
  late final AuthApi _api;
  StreamSubscription<void>? _signInSub;

  /// 동시 provisioning(중복 `/auth/me`) 방지 가드.
  bool _provisioning = false;

  /// 직전에 이메일 회원가입을 했는지(가입 직후 닉네임 설정 화면을 띄우는 신호).
  /// 닉네임 저장([updateProfile]) 성공 시 해제된다.
  bool _justSignedUp = false;
  bool get justSignedUp => _justSignedUp;

  /// 인증 헤더·401 refresh 가 붙은 공유 [ApiClient]. 데이터 레이어가 재사용(이슈 #35).
  ApiClient get apiClient => _client;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;

  /// 현재 진입 상태.
  AuthStatus get status => _status;

  /// 현재 인증 사용자(미인증이면 null).
  AuthUser? get user => _user;

  /// 인증된 상태인지.
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Supabase 세션으로 복원 시도. 진입 게이트(main.dart)에서 호출.
  /// 세션이 있으면 server `/auth/me` 로 사용자를 확인한다.
  Future<void> tryRestore() async {
    if (!_gateway.hasSession) {
      _setUnauthenticated();
      return;
    }
    try {
      final AuthUser me = await _api.me();
      _setAuthenticated(me);
    } on ApiException {
      await _gateway.signOut();
      _setUnauthenticated();
    }
  }

  /// 소셜 로그인(ADR-0014). 모든 provider 가 Supabase `signInWithOAuth`(브라우저 + 딥링크)
  /// 웹 흐름이다 — 인증은 Supabase(web client)가 처리하므로 앱 내 client id·네이티브 SDK 불필요.
  /// 이 호출은 브라우저를 띄우고 곧장 반환하며, 완료는 [onSignedIn] → [_onExternalSignIn] 에서
  /// `/auth/me` provisioning 으로 처리된다. 실패는 [Exception] 전파(UI 표시).
  Future<void> oauthSignIn(SocialProvider provider) =>
      _gateway.signInWithOAuth(provider);

  /// 이메일 회원가입(ADR-0014). Supabase `signUp`(Confirm email OFF → 즉시 세션) →
  /// server `/auth/me` provisioning. 성공 시 [justSignedUp] 이 true 가 되어 진입 게이트가
  /// 닉네임 설정 화면을 띄운다. 실패는 [AuthException]/[Exception] 전파(UI 표시).
  Future<void> emailSignUp({
    required String email,
    required String password,
  }) async {
    _justSignedUp = true;
    try {
      await _gateway.signUpWithEmail(email: email, password: password);
      await _provisionAndAuthenticate();
    } catch (_) {
      _justSignedUp = false;
      rethrow;
    }
  }

  /// 이메일 로그인. Supabase `signInWithPassword` → `/auth/me`. 닉네임 화면 없이 main.
  Future<void> emailSignIn({
    required String email,
    required String password,
  }) async {
    await _gateway.signInWithEmail(email: email, password: password);
    await _provisionAndAuthenticate();
  }

  /// OAuth 딥링크 복귀로 세션이 생긴 뒤 server provisioning(이미 인증/진행 중이면 무시).
  Future<void> _onExternalSignIn() async {
    if (_status == AuthStatus.authenticated || _provisioning) return;
    try {
      await _provisionAndAuthenticate();
    } on ApiException {
      // 복귀 직후 me 실패 — 미인증 유지(화면이 재시도).
    }
  }

  /// 현재 세션으로 `/auth/me` 를 조회해 인증 상태로 전환한다(중복 방지 가드).
  Future<void> _provisionAndAuthenticate() async {
    if (_provisioning) return;
    _provisioning = true;
    try {
      final AuthUser me = await _api.me();
      _setAuthenticated(me);
    } finally {
      _provisioning = false;
    }
  }

  /// 프로필(닉네임) 수정(이슈 #56). 성공 시 [user] 를 갱신하고 알림.
  Future<void> updateProfile({required String nickname}) async {
    final AuthUser updated = await _api.updateProfile(nickname: nickname);
    _user = updated;
    _justSignedUp = false; // 닉네임 설정 완료 → 가입 직후 플래그 해제.
    notifyListeners();
  }

  /// 회원 탈퇴(이슈 #56). server 탈퇴 후 Supabase 로그아웃 + 미인증 전환.
  Future<void> withdraw() async {
    await _api.withdraw();
    await _gateway.signOut();
    _setUnauthenticated();
  }

  /// 로그아웃. Supabase 세션 종료 + 미인증 전환.
  Future<void> logout() async {
    await _gateway.signOut();
    _setUnauthenticated();
  }

  @override
  void dispose() {
    _signInSub?.cancel();
    super.dispose();
  }

  void _setAuthenticated(AuthUser user) {
    _user = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void _setUnauthenticated() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
