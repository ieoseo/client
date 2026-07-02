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
    // 연동 추가(linkIdentity) 등 사용자 갱신 시 최신 identity 를 반영한다.
    _userUpdatedSub = _gateway.onUserUpdated.listen((_) => _onUserUpdated());
  }

  final SupabaseAuthGateway _gateway;
  late final ApiClient _client;
  late final AuthApi _api;
  StreamSubscription<void>? _signInSub;
  StreamSubscription<void>? _userUpdatedSub;

  /// 동시 provisioning(중복 `/auth/me`) 방지 가드.
  bool _provisioning = false;

  /// 인증 헤더·401 refresh 가 붙은 공유 [ApiClient]. 데이터 레이어가 재사용(이슈 #35).
  ApiClient get apiClient => _client;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  String? _authError;

  /// 현재 진입 상태.
  AuthStatus get status => _status;

  /// 현재 인증 사용자(미인증이면 null).
  AuthUser? get user => _user;

  /// 최근 로그인/provisioning 실패 안내(없으면 null). 로그인 화면이 배너로 노출한다(#156).
  /// OAuth 딥링크 복귀 후 `/auth/me` 가 실패하면 무음으로 로그인 화면에 되돌아오던 문제를
  /// 이 메시지로 드러낸다. 새 로그인 시도 시 [clearAuthError] 로 비운다.
  String? get authError => _authError;

  /// 로그인 화면이 새 시도를 시작할 때 이전 에러 안내를 지운다.
  void clearAuthError() {
    if (_authError == null) return;
    _authError = null;
    notifyListeners();
  }

  /// 인증된 상태인지.
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// 외부 OAuth 복귀 후 server `/auth/me` provisioning 이 진행 중인지.
  /// 진입 게이트가 이 동안 로그인 화면 대신 로딩을 띄워 깜빡임을 막는다.
  bool get isAuthenticating => _provisioning;

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

  /// 현재 계정에 연동된 provider 이름 집합(예: {'email','google','kakao'}).
  Set<String> get linkedProviders => _gateway.linkedProviders;

  /// 소셜 계정 추가 연동(`linkIdentity`, 브라우저 + 딥링크). 완료는 [onUserUpdated] →
  /// [_onUserUpdated] 가 반영한다. 실패는 [Exception] 전파(UI 표시).
  Future<void> linkAccount(SocialProvider provider) =>
      _gateway.linkOAuth(provider);

  /// 소셜 계정 연동 해제(`unlinkIdentity`). 성공 시 최신 identity 로 갱신·알림.
  /// 마지막 identity 해제 등은 게이트웨이가 예외로 막는다(UI 표시).
  Future<void> unlinkAccount(SocialProvider provider) async {
    await _gateway.unlinkOAuth(provider);
    notifyListeners();
  }

  /// OAuth 딥링크 복귀로 세션이 생긴 뒤 server provisioning(이미 인증/진행 중이면 무시).
  Future<void> _onExternalSignIn() async {
    if (_status == AuthStatus.authenticated || _provisioning) return;
    try {
      await _provisionAndAuthenticate();
    } on ApiException catch (e) {
      // 세션은 생겼지만 me 실패 = "인증 후 로그인 화면 복귀"(#156). 무음 대신 안내를 세운다.
      await _failExternalSignIn('로그인은 됐지만 계정 확인에 실패했어요. 잠시 후 다시 시도해 주세요.', e);
    } catch (e, stack) {
      // ApiException 이 아닌 예외(네트워크 raw·파싱 등)도 흡수해 구독이 끊기지 않게 한다.
      // 무음 흡수는 원인을 감추므로(#156) 로그는 남기되 화면 안내도 세운다.
      debugPrint('OAuth 복귀 provisioning 실패: $e');
      debugPrint('$stack');
      await _failExternalSignIn('로그인 처리 중 문제가 생겼어요. 다시 시도해 주세요.', e);
    }
  }

  /// 딥링크 복귀 provisioning 실패 처리: 매달린 세션을 정리(반쪽 상태 방지)하고
  /// 안내를 세운 뒤 미인증으로 확정한다(로그인 화면이 배너로 노출).
  Future<void> _failExternalSignIn(String message, Object error) async {
    try {
      await _gateway.signOut();
    } on Object catch (e) {
      debugPrint('실패 정리(signOut) 중 오류(무시): $e');
    }
    _authError = message;
    _setUnauthenticated();
  }

  /// 사용자 갱신(연동 추가 등) 통지 시 최신 identity 를 로컬에 반영하고 알린다.
  Future<void> _onUserUpdated() async {
    try {
      await _gateway.reloadUser();
    } catch (e, stack) {
      // reloadUser 실패가 onUserUpdated 구독을 끊지 않게 흡수한다(다음 갱신 이벤트 보존).
      debugPrint('사용자 갱신(reloadUser) 실패(흡수): $e');
      debugPrint('$stack');
    }
    notifyListeners();
  }

  /// 현재 세션으로 `/auth/me` 를 조회해 인증 상태로 전환한다(중복 방지 가드).
  Future<void> _provisionAndAuthenticate() async {
    if (_provisioning) return;
    _provisioning = true;
    notifyListeners(); // provisioning 시작 → 게이트가 로딩 표시(로그인 화면 깜빡임 방지)
    try {
      final AuthUser me = await _api.me();
      _setAuthenticated(me);
    } finally {
      final bool stillNotAuthenticated = _status != AuthStatus.authenticated;
      _provisioning = false;
      // 실패(예외)로 인증되지 않았으면 게이트가 로딩을 해제하도록 알린다.
      if (stillNotAuthenticated) notifyListeners();
    }
  }

  /// 프로필(닉네임) 수정(이슈 #56). 성공 시 [user] 를 갱신하고 알림.
  Future<void> updateProfile({required String nickname}) async {
    final AuthUser updated = await _api.updateProfile(nickname: nickname);
    _user = updated;
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
    _userUpdatedSub?.cancel();
    super.dispose();
  }

  void _setAuthenticated(AuthUser user) {
    _user = user;
    _status = AuthStatus.authenticated;
    _authError = null;
    notifyListeners();
  }

  void _setUnauthenticated() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
