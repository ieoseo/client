/// 인증/데이터 API 연동 설정값(이슈 #32). 시크릿 아님 — 커밋 OK.
library;

/// API base URL. **소스에 URL 을 두지 않는다**(SUPABASE_URL 과 동일 원칙) — 값은 환경별
/// env 파일에서 `--dart-define-from-file` 로 주입한다. 어떤 환경을 향할지는 **어느 파일을
/// 넘기느냐**로 갈린다:
/// - **로컬(개발)**: `client/.env.json` 의 `API_BASE_URL`(로컬 서버) — `flutter run` 이 사용.
/// - **운영(릴리스)**: `client/.env.prod.json` 의 `API_BASE_URL`(운영 도메인) — Play/CI 빌드가 사용.
///
/// 값 레퍼런스(실제 URL 예시)는 [docs/가이드/환경변수.md] 에 둔다. 미주입 시 빈 문자열이며,
/// 진입점(main.dart)의 가드가 빠르게 실패시킨다(localhost 가리키는 앱을 실수로 출시하는 사고 방지).
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// dio 연결 타임아웃. 보안 규칙(타임아웃 필수).
const Duration kConnectTimeout = Duration(seconds: 10);

/// dio 수신 타임아웃.
const Duration kReceiveTimeout = Duration(seconds: 15);

/// secure storage 키 — access 토큰.
const String kAccessTokenKey = 'dk_access_token';

/// secure storage 키 — refresh 토큰.
const String kRefreshTokenKey = 'dk_refresh_token';

/// dio 요청 extra 플래그 — 401 refresh 재시도 1회 가드.
const String kRetriedFlag = '_dk_retried';

/// dio 요청 extra 플래그 — Authorization 부착 스킵(인증 공개 엔드포인트).
const String kSkipAuthFlag = '_dk_skip_auth';
