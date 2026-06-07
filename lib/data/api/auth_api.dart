import '../auth/social_auth.dart';
import 'api_client.dart';
import 'auth_dto.dart';

/// 인증 엔드포인트 호출(이슈 #32). `docs/05-API/auth.md` 계약.
///
/// signup/login/refresh 는 공개(토큰 불필요), me/logout 은 Bearer 필요.
/// 응답 envelope 언랩·오류 매핑은 [ApiClient]가 담당하므로 여기서는 DTO 변환만 한다.
class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  /// 이메일 회원가입. 201 → 세션(사용자 + 토큰).
  /// 오류: 409 `EMAIL_TAKEN`, 400 `VALIDATION_ERROR`.
  Future<AuthSession> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final dynamic data = await _client.post(
      '/auth/signup',
      body: <String, dynamic>{
        'email': email,
        'password': password,
        'nickname': nickname,
      },
      skipAuth: true,
    );
    return AuthSession.fromJson(data as Map<String, dynamic>);
  }

  /// 이메일 로그인. 200 → 세션. 오류: 401 `INVALID_CREDENTIALS`.
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final dynamic data = await _client.post(
      '/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
      skipAuth: true,
    );
    return AuthSession.fromJson(data as Map<String, dynamic>);
  }

  /// 소셜 로그인(이슈 #38). `POST /auth/oauth/{provider}`.
  ///
  /// [provider]는 `google`/`apple`/`kakao`. 본문은 [SocialToken.toRequestBody]가
  /// provider에 맞춰 `{idToken}`(google/apple) 또는 `{accessToken}`(kakao)으로 만든다.
  /// 200 → 세션(사용자 + 토큰). 오류: 401 `OAUTH_INVALID`, 409 `EMAIL_LINKED_LOCAL`.
  Future<AuthSession> oauth({
    required String provider,
    required SocialToken token,
  }) async {
    final dynamic data = await _client.post(
      '/auth/oauth/$provider',
      body: token.toRequestBody(),
      skipAuth: true,
    );
    return AuthSession.fromJson(data as Map<String, dynamic>);
  }

  /// 토큰 재발급(회전). 200 → 새 access+refresh.
  /// 오류: 401 `REFRESH_INVALID`.
  Future<AuthTokens> refresh(String refreshToken) async {
    final dynamic data = await _client.post(
      '/auth/refresh',
      body: <String, dynamic>{'refreshToken': refreshToken},
      skipAuth: true,
    );
    return AuthTokens.fromJson(data as Map<String, dynamic>);
  }

  /// 로그아웃. Bearer + (선택) refreshToken. 204.
  Future<void> logout({String? refreshToken}) async {
    await _client.post(
      '/auth/logout',
      body: refreshToken == null
          ? const <String, dynamic>{}
          : <String, dynamic>{'refreshToken': refreshToken},
    );
  }

  /// 현재 사용자. Bearer 필요. 200 → 사용자.
  Future<AuthUser> me() async {
    final dynamic data = await _client.get('/auth/me');
    return AuthUser.fromJson(data as Map<String, dynamic>);
  }

  /// 프로필(닉네임) 수정(이슈 #56). Bearer 필요. 200 → 갱신된 사용자.
  /// 오류: 400 `VALIDATION_ERROR`, 401 `UNAUTHORIZED`.
  Future<AuthUser> updateProfile({required String nickname}) async {
    final dynamic data = await _client.patch(
      '/auth/me',
      body: <String, dynamic>{'nickname': nickname},
    );
    return AuthUser.fromJson(data as Map<String, dynamic>);
  }

  /// 회원 탈퇴(이슈 #56). Bearer 필요. 204(소프트 삭제 + refresh 폐기). 이후 토큰 무효.
  Future<void> withdraw() async {
    await _client.delete('/auth/me');
  }
}
