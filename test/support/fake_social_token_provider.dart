import 'package:ieoseo/data/auth/social_auth.dart';

/// 단위/위젯 테스트용 [SocialTokenProvider] 가짜(이슈 #38).
///
/// 네이티브 SDK 없이 소셜 흐름을 시뮬레이션한다:
/// - [token]을 지정하면 [getToken]이 그 값을 성공 반환.
/// - [cancel]이 true면 [SocialSignInCancelled]를 던짐(사용자 취소).
/// - [error]를 지정하면 그 예외를 던짐(SDK 오류).
/// 호출된 provider 목록을 [calls]에 기록한다.
class FakeSocialTokenProvider implements SocialTokenProvider {
  FakeSocialTokenProvider({
    this.token = 'social-token',
    this.cancel = false,
    this.error,
  });

  /// 성공 시 돌려줄 토큰 값.
  final String token;

  /// true면 사용자 취소([SocialSignInCancelled])를 흉내낸다.
  final bool cancel;

  /// 지정하면 이 예외를 던진다(SDK/네트워크 오류).
  final Object? error;

  /// 호출 이력(검증용).
  final List<SocialProvider> calls = <SocialProvider>[];

  @override
  Future<SocialToken> getToken(SocialProvider provider) async {
    calls.add(provider);
    if (cancel) throw SocialSignInCancelled(provider);
    if (error != null) throw error!;
    return SocialToken(provider: provider, value: token);
  }
}
