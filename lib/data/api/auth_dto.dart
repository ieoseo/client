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

  /// 이메일. provider(예: Kakao)가 제공하지 않으면 null(ADR-0014).
  final String? email;
  final String nickname;

  /// 가입 경로(`LOCAL`/`GOOGLE`/`KAKAO`/...).
  final String provider;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String?,
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
