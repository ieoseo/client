import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/auth_api.dart';
import '../api/auth_dto.dart';
import 'social_auth.dart';
import 'token_storage.dart';

/// 인증 진입 상태(이슈 #32).
enum AuthStatus {
  /// 부팅 직후 — 저장 토큰 복원 시도 중(스플래시/대기).
  unknown,

  /// 유효 세션 — main 진입.
  authenticated,

  /// 세션 없음 — 인증 화면.
  unauthenticated,
}

/// 인증 상태 + 토큰 보관/복원을 한곳에서 관리하는 컨트롤러(이슈 #32).
///
/// `AuthRepository`(signup/login/logout/currentUser/tryRestore) 역할과
/// `ChangeNotifier` 상태를 겸한다. UI는 [status]/[user]를 구독하고,
/// 진입 게이트(main.dart)는 [tryRestore]로 저장 토큰을 복원한다.
///
/// 토큰 평문은 로깅하지 않는다.
class AuthController extends ChangeNotifier {
  AuthController({
    TokenStorage? storage,
    AuthApi? api,
    ApiClient? client,
    this.social,
  }) : _storage = storage ?? TokenStorage() {
    _client =
        client ??
        ApiClient(
          accessTokenReader: _storage.readAccess,
          tokenRefresher: _refreshAccess,
        );
    _api = api ?? AuthApi(_client);
  }

  final TokenStorage _storage;
  late final ApiClient _client;
  late final AuthApi _api;

  /// 소셜 토큰 획득 추상화(이슈 #38). 주입되지 않으면 [oauthSignIn]은
  /// [StateError]를 던진다(소셜 미구성 환경 방어).
  final SocialTokenProvider? social;

  /// 인증 헤더·401 refresh 가 붙은 공유 [ApiClient]. 데이터 레이어
  /// (ApiRepository)가 같은 클라이언트를 재사용하도록 노출(이슈 #35).
  ApiClient get apiClient => _client;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;

  /// 현재 진입 상태.
  AuthStatus get status => _status;

  /// 현재 인증 사용자(미인증이면 null).
  AuthUser? get user => _user;

  /// 인증된 상태인지.
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// 401 재시도용 access 토큰 재발급. 성공 시 새 access 반환, 실패 시 세션 폐기.
  Future<String?> _refreshAccess() async {
    final String? refresh = await _storage.readRefresh();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final AuthTokens tokens = await _api.refresh(refresh);
      await _storage.save(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens.accessToken;
    } on ApiException {
      // refresh 폐기/만료 → 로컬 토큰 정리. 상태 전환은 호출 흐름에서 처리.
      await _storage.clear();
      return null;
    }
  }

  /// 저장 토큰으로 세션 복원 시도. 진입 게이트에서 호출.
  /// 성공 → [AuthStatus.authenticated], 실패 → [AuthStatus.unauthenticated].
  Future<void> tryRestore() async {
    final bool hasSession = await _storage.hasSession();
    if (!hasSession) {
      _setUnauthenticated();
      return;
    }
    try {
      final AuthUser me = await _api.me();
      _setAuthenticated(me);
    } on ApiException {
      // me 401 → 인터셉터가 refresh를 1회 시도. 그래도 실패면 여기로 온다.
      await _storage.clear();
      _setUnauthenticated();
    }
  }

  /// 이메일 회원가입. 성공 시 토큰 저장 + 인증 상태 전환.
  /// 실패는 [ApiException]을 그대로 던진다(UI가 메시지 표시).
  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final AuthSession session = await _api.signup(
      email: email,
      password: password,
      nickname: nickname,
    );
    await _persist(session);
  }

  /// 이메일 로그인. 성공 시 토큰 저장 + 인증 상태 전환.
  Future<void> login({required String email, required String password}) async {
    final AuthSession session = await _api.login(
      email: email,
      password: password,
    );
    await _persist(session);
  }

  /// 소셜 로그인(이슈 #38). provider SDK로 토큰을 얻어 서버에 교환한다.
  ///
  /// 흐름: [SocialTokenProvider.getToken] → [AuthApi.oauth] → 세션 저장 + 인증 전환.
  /// - 사용자가 SDK 흐름을 취소하면 [SocialSignInCancelled]를 그대로 던진다
  ///   (UI는 조용히 무시 — 오류 토스트 금지).
  /// - 서버/네트워크 실패는 [ApiException]을 그대로 던진다(UI가 메시지 표시).
  Future<void> oauthSignIn(SocialProvider provider) async {
    final SocialTokenProvider? tokenProvider = social;
    if (tokenProvider == null) {
      throw StateError('SocialTokenProvider 가 주입되지 않았어요.');
    }
    // 취소(SocialSignInCancelled)·SDK 오류는 호출부로 그대로 전파한다.
    final SocialToken token = await tokenProvider.getToken(provider);
    final AuthSession session = await _api.oauth(
      provider: provider.wireName,
      token: token,
    );
    await _persist(session);
  }

  /// 프로필(닉네임) 수정(이슈 #56). 성공 시 [user] 를 갱신하고 알림.
  /// 실패는 [ApiException] 을 그대로 던진다(UI가 메시지 표시).
  Future<void> updateProfile({required String nickname}) async {
    final AuthUser updated = await _api.updateProfile(nickname: nickname);
    _user = updated;
    notifyListeners();
  }

  /// 회원 탈퇴(이슈 #56). 서버 탈퇴(소프트 삭제 + refresh 폐기) 후 로컬 세션을 정리하고
  /// 미인증으로 전환한다(→ 인증 화면). 서버 실패는 [ApiException] 으로 던지며, 이때 로컬 세션은
  /// 유지된다(사용자가 재시도 가능). 성공 후에는 토큰을 삭제한다.
  Future<void> withdraw() async {
    await _api.withdraw();
    await _storage.clear();
    _setUnauthenticated();
  }

  /// 로그아웃. 서버 폐기 시도 후 로컬 토큰 삭제 + 미인증 전환.
  /// 서버 호출 실패(네트워크 등)여도 로컬 세션은 반드시 정리한다.
  Future<void> logout() async {
    final String? refresh = await _storage.readRefresh();
    try {
      await _api.logout(refreshToken: refresh);
    } on ApiException {
      // 서버 폐기 실패는 무시 — 로컬 세션은 아래에서 정리.
    }
    await _storage.clear();
    _setUnauthenticated();
  }

  Future<void> _persist(AuthSession session) async {
    await _storage.save(
      accessToken: session.tokens.accessToken,
      refreshToken: session.tokens.refreshToken,
    );
    _setAuthenticated(session.user);
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
