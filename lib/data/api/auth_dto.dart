import 'package:flutter/foundation.dart';

/// 인증된 사용자 식별 정보. `docs/05-API/auth.md` user 페이로드.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.provider,
    this.isNew = false,
  });

  /// 사용자 UUID.
  final String id;

  /// 이메일. provider(예: Kakao)가 제공하지 않으면 null(ADR-0014).
  final String? email;
  final String nickname;

  /// 가입 경로(`LOCAL`/`GOOGLE`/`KAKAO`/...).
  final String provider;

  /// 이번 `/auth/me` 요청에서 막 provisioning 된 신규 사용자인지(server 제공).
  /// true 면 진입 게이트가 닉네임 설정 화면을 먼저 띄운다. 필드 없으면 false.
  final bool isNew;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String?,
    nickname: json['nickname'] as String,
    provider: (json['provider'] as String?) ?? 'LOCAL',
    isNew: json['isNew'] as bool? ?? false,
  );

  AuthUser copyWith({String? nickname, bool? isNew}) => AuthUser(
    id: id,
    email: email,
    nickname: nickname ?? this.nickname,
    provider: provider,
    isNew: isNew ?? this.isNew,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'email': email,
    'nickname': nickname,
    'provider': provider,
    'isNew': isNew,
  };
}
