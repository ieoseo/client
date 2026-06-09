import 'dart:async';

import 'package:ieoseo/data/auth/social_auth.dart';
import 'package:ieoseo/data/auth/supabase_auth_gateway.dart';

/// 단위/위젯 테스트용 [SupabaseAuthGateway] 가짜(ADR-0014).
///
/// `supabase_flutter` 없이 Supabase 세션 흐름을 시뮬레이션한다:
/// - [accessToken] 초기값으로 세션 유무([hasSession])를 흉내낸다.
/// - [signInWithOAuth]은 [oauthError] 가 있으면 던지고, 없으면 세션을 만든 뒤
///   [onSignedIn] 이벤트를 발행한다(딥링크 복귀 시뮬레이션).
/// - [signUpWithEmail]/[signInWithEmail]은 [emailError] 가 있으면 던지고, 없으면 세션 생성.
/// - [refreshAccessToken]은 [refreshResult] 를 반환한다(null=실패).
/// - [signOut]은 세션을 비우고 [signedOut] 을 기록한다.
class FakeSupabaseGateway implements SupabaseAuthGateway {
  FakeSupabaseGateway({
    String? accessToken,
    this.oauthError,
    this.emailError,
    this.refreshResult,
    this.grantedAccessToken = 'supabase-access',
    // ignore: prefer_initializing_formals
  }) : _accessToken = accessToken;

  String? _accessToken;

  /// 지정하면 [signInWithOAuth] 가 이 예외를 던진다.
  final Object? oauthError;

  /// 지정하면 [signUpWithEmail]/[signInWithEmail] 이 이 예외를 던진다.
  final Object? emailError;

  /// [refreshAccessToken] 결과(null=실패).
  final String? refreshResult;

  /// 로그인 성공 후 세션 access 토큰 값.
  final String grantedAccessToken;

  /// 이메일 가입/로그인 호출 이력(검증용).
  final List<String> emailCalls = <String>[];

  /// OAuth 시작에 전달된 provider 이력(검증용).
  final List<SocialProvider> oauthCalls = <SocialProvider>[];

  /// [signOut] 호출 여부.
  bool signedOut = false;

  final StreamController<void> _signedInController =
      StreamController<void>.broadcast();

  @override
  String? get accessToken => _accessToken;

  @override
  bool get hasSession => _accessToken != null;

  @override
  Stream<void> get onSignedIn => _signedInController.stream;

  @override
  Future<void> signInWithOAuth(SocialProvider provider) async {
    oauthCalls.add(provider);
    final Object? err = oauthError;
    if (err != null) throw err;
    // 딥링크 복귀로 세션이 생긴 상황을 시뮬레이션.
    _accessToken = grantedAccessToken;
    _signedInController.add(null);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    emailCalls.add('signup:$email');
    final Object? err = emailError;
    if (err != null) throw err;
    _accessToken = grantedAccessToken;
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emailCalls.add('login:$email');
    final Object? err = emailError;
    if (err != null) throw err;
    _accessToken = grantedAccessToken;
  }

  @override
  Future<String?> refreshAccessToken() async {
    _accessToken = refreshResult;
    return refreshResult;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
    _accessToken = null;
  }

  /// 테스트 종료 시 스트림 정리(선택).
  void dispose() => _signedInController.close();
}
