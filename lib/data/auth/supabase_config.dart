/// 소셜 OAuth(Kakao 등) 로그인 후 앱으로 되돌아오는 딥링크(ADR-0014).
///
/// Supabase 대시보드 Authentication → URL Configuration → Redirect URLs 에 동일 값을
/// 등록해야 하고, Android `AndroidManifest.xml` 의 intent-filter(scheme=`app.ieoseo`,
/// host=`login-callback`)가 이 링크를 받는다.
const String kSupabaseRedirectUri = 'app.ieoseo://login-callback';

/// Supabase 클라이언트 초기화 설정(ADR-0014).
///
/// 인증은 Supabase Auth 다 — client `supabase_flutter` 가 로그인·세션·토큰을 담당하고,
/// server 는 Supabase JWKS 로 JWT 를 검증만 한다. 여기 값은 앱 시작 시
/// `Supabase.initialize` 에 주입한다.
///
/// - [url]: 프로젝트 URL(`https://<ref>.supabase.co`). 공개값.
/// - [anonKey]: anon(public) 키. RLS 로 보호되는 공개 키 — `--dart-define` 으로 주입한다.
///
/// 실행 예:
///   flutter run --dart-define=SUPABASE_ANON_KEY=`anon-key` \
///     --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  /// 설정(`.env.json` 의 dart-define)에서 구성값을 읽는다. 하드코딩 기본값 없음 —
  /// 소스가 특정 프로젝트에 묶이거나 설정 누락 시 모르게 운영에 붙는 사고를 막는다.
  /// 둘 다 `.env.json`(로컬)·CI dart-define(릴리스)으로 주입한다.
  factory SupabaseConfig.fromEnvironment() {
    const String url = String.fromEnvironment('SUPABASE_URL');
    const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    return SupabaseConfig(url: url, anonKey: anonKey);
  }

  /// 초기화 가능한 구성인지(url·anonKey 모두 비어있지 않은지).
  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
