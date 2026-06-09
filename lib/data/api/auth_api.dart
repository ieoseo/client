import 'api_client.dart';
import 'auth_dto.dart';

/// 인증 엔드포인트 호출(ADR-0014). `docs/05-API/auth.md` 계약.
///
/// 인증은 Supabase Auth 다 — 로그인·토큰 발급/갱신은 client `supabase_flutter` 와
/// Supabase 가 담당하고, server 는 JWKS 로 JWT 를 **검증만** 한다. 따라서 server 에는
/// 토큰 발급 엔드포인트(signup/login/oauth/refresh/logout)가 없다. 여기서는 인증된
/// 사용자 조회·프로필 수정·탈퇴(모두 Bearer 필요)만 호출한다.
class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  /// 현재 사용자. Bearer(Supabase JWT) 필요. 200 → 사용자(최초 호출 시 server provisioning).
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

  /// 회원 탈퇴(이슈 #56). Bearer 필요. 204(소프트 삭제). 이후 Supabase 로그아웃은 호출부에서.
  Future<void> withdraw() async {
    await _client.delete('/auth/me');
  }
}
