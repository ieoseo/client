/// 인증/데이터 API 연동 설정값(이슈 #32). 시크릿 아님 — 커밋 OK.
library;

/// API base URL. 기본값은 **운영 백엔드**(Azure App Service)다 → 릴리스 빌드가
/// 별도 주입 없이 운영을 향한다(localhost 가리키는 앱을 실수로 출시하는 사고 방지).
/// 로컬 개발은 빌드 시 오버라이드한다:
///   flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
///   (Android 에뮬레이터는 http://10.0.2.2:8080/api/v1)
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://ieoseo-api.azurewebsites.net/api/v1',
);

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
