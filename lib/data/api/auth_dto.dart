import 'package:flutter/foundation.dart';

/// 인증된 사용자 식별 정보. `docs/05-API/auth.md` user 페이로드.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.provider,
  });

  /// 사용자 UUID.
  final String id;
  final String email;
  final String nickname;

  /// 가입 경로(`LOCAL`/`GOOGLE`/...).
  final String provider;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    nickname: json['nickname'] as String,
    provider: (json['provider'] as String?) ?? 'LOCAL',
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'email': email,
    'nickname': nickname,
    'provider': provider,
  };
}

/// access/refresh 토큰 쌍. `docs/05-API/auth.md` tokens 페이로드.
///
/// 토큰 평문은 로깅하지 않는다([toString]에서 마스킹).
@immutable
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  /// access 만료까지 초(예: 1800). 없을 수 있음.
  final int? expiresIn;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    tokenType: (json['tokenType'] as String?) ?? 'Bearer',
    expiresIn: (json['expiresIn'] as num?)?.toInt(),
  );

  @override
  String toString() =>
      'AuthTokens(tokenType: $tokenType, expiresIn: $expiresIn)';
}

/// 로그인/회원가입/소셜 응답: 사용자 + 토큰.
@immutable
class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  final AuthUser user;
  final AuthTokens tokens;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
  );
}
