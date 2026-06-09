# client/ — 이어서 Flutter 앱

이어서의 프론트엔드. UI는 **Claude Design 핸드오프 번들의 픽셀 재현**이다. 구현 기준은 항상 `../docs/01-디자인분석/`.

## ⚠️ 변경 시 docs 동기화 (MUST)
- UI 컴포넌트/레이아웃/수치/토큰을 바꾸면 → `../docs/01-디자인분석/화면별-스펙.md`, `디자인시스템-토큰.md` 갱신.
- 화면/플로우 추가·삭제 → `../docs/00-요구사항/화면목록.md` 갱신.
- 의존성/버전/구조 결정 → `../docs/02-아키텍처/기술스택.md` + 필요 시 `../docs/04-ADR/` 새 ADR.
- 문서 안 고친 변경은 미완성.

## 구현 기준 (단일 출처)
- **최종 IA = 4탭**: 오늘 · 플랜 · 집중 · 나 (+ 진입: 스플래시→온보딩→로그인). `화면목록.md` 참조.
- 수치(패딩·라운드·폰트·색)는 `화면별-스펙.md`의 값을 그대로 따른다. 임의로 바꾸지 말 것.
- 디자인 원본 React 구조는 **참고만**. Flutter 위젯 트리로 재구성한다.

## TDD (MUST)
- **테스트 먼저**: RED→GREEN→REFACTOR, 커버리지 80%+. [../docs/03-개발프로세스/TDD-가이드.md](../docs/03-개발프로세스/TDD-가이드.md).
- 단위(`dday`/`format`/Repository) + 위젯(공용·화면) + 골든(시각 회귀, 보조). `flutter test --coverage`.
- 시각 스캐폴드 등 예외는 PR에 사유 명시. 진행 중이던 기반 위젯은 사후 테스트 보강.

## 코드 컨벤션
- **불변(immutable) 우선**: 모델은 `@immutable` + `copyWith`. 기존 객체 변형 금지, 새 객체 반환.
- **작은 파일 다수**: feature/도메인별로 묶기. 200~400줄 권장, 800줄 상한.
- 네이밍: 위젯/타입 PascalCase, 함수/변수 camelCase, 상수 `kXxx`/UPPER, 불리언 `is/has/should/can`.
- 디자인 토큰: 색·간격·라운드·그림자는 **토큰(`DkTokens`/`DkTheme`)** 으로. 하드코딩 색 금지(디자인 명세 값은 토큰으로 정의).
- 폰트: UI는 `Pretendard`, 큰 숫자/브랜드는 `WantedSans`.
- 모션: 이징 `Cubic(0.4, 0, 0.2, 1)` 기본. 이모지 금지.

## 데이터 (ADR-0005, 이슈 #35 A-2 — events/tasks/debts 실연동)
- UI는 **`IeoseoRepository` 인터페이스**에만 의존. events/tasks/debts 는 `Future` 기반 CRUD(목록/생성/수정/삭제/완료/이월/탕감).
- 구현 2종: `MockRepository`(in-memory, 테스트·데모) / `ApiRepository`(server REST). `ApiRepository`는 `AuthController.apiClient`(Bearer+401 refresh)를 재사용한다.
- **주입**: `main.dart`가 로그인 후 `DataController(ApiRepository(auth.apiClient))`를 `MainScaffold`에 공급(테스트는 `DataController(MockRepository())` 주입).
- `DataController`(ChangeNotifier): `load()`로 events/tasks/debts 병렬 로딩, `isLoading`/`error` 상태, 쓰기는 **낙관적 업데이트 + 실패 시 롤백**(오류는 `ApiException`을 다시 던져 화면 토스트).
- DTO 매핑은 `data/api/dtos.dart`(`DkEventDto`/`DkTaskDto`/`DkDebtDto` — server enum 코드·ymd 날짜). `data/api/api_repository.dart`가 호출.
- 외부 캘린더·주간 요약·집중 통계·스트릭·주간 리뷰는 server 엔드포인트가 없어 **목 데이터(동기 읽기)** 로 유지.
- 도메인 권위는 server. 클라이언트 D-Day/포모도로 계산은 표현/데모용.
- 계약 차이(메모): server `DebtResponse`에는 `title`/`fromLabel`이 없다 → `DkDebtDto`는 제목을 비워 매핑(표시 제목은 후속에서 태스크 조인). un-complete 전용 액션이 없어 완료 취소는 PUT으로 today 복귀를 표현. 자동 이월(`/debts/{id}/auto-carry`)은 미배선.

## 인증 (Supabase Auth — 소셜 전용, ADR-0014)
- **이메일 + 소셜**: 이메일 가입/로그인(Supabase `signUp`/`signInWithPassword`)과 소셜(**Kakao·Google**, Apple 후속). 로그인·세션·토큰은 `supabase_flutter` 가 담당하고, server 는 Supabase JWT 를 JWKS 로 **검증만** 한다(토큰 발급 엔드포인트 없음).
- **소셜은 전부 웹 OAuth(ADR-0014)**: `signInWithOAuth(provider, redirectTo: app.ieoseo://login-callback)`(브라우저 + 딥링크) → 복귀 시 `onAuthStateChange(signedIn)` → server `/auth/me` provisioning. **인증은 Supabase(web client)가 처리** → 앱 내 client id·네이티브 SDK(google_sign_in 등) 불필요. (Google 네이티브 idToken 방식을 쓰려면 Android/iOS OAuth 클라이언트가 필요해 채택 안 함.)
- **이메일 가입 직후**: 닉네임이 없으므로 `NicknameSetupScreen` 으로 닉네임을 받아 `/auth/me`(PATCH) 저장(`justSignedUp`).
- `data/auth/`: `SupabaseAuthGateway`(supabase_flutter 추상화 — 토큰/`signInWithOAuth`/이메일/refresh/signOut/onSignedIn, 테스트는 가짜 주입), `AuthController`(ChangeNotifier — oauthSignIn/emailSignUp/emailSignIn/tryRestore/updateProfile/withdraw/logout + `AuthStatus`), `social_auth.dart`(`SocialProvider` 표시용 enum), `supabase_config.dart`(URL/anonKey + `kSupabaseRedirectUri`).
- `data/api/`: `ApiClient`(dio 래퍼 — baseUrl·타임아웃·envelope 언랩·`ApiException`·Bearer(Supabase 세션 토큰)·401 시 `refreshSession` 1회 재시도), `AuthApi`(**me/updateProfile/withdraw** 만), DTO `AuthUser`(`email` 은 **nullable** — Kakao 등 미제공 가능).
- 진입 게이트(`main.dart`): `Supabase.initialize` 후 부팅 시 `tryRestore`(Supabase 세션 → `/auth/me`) → 유효하면 main, 아니면 splash→onboarding→로그인. 로그아웃은 `signOut`.
- 설정: `.env.json`(dart-define-from-file) — `SUPABASE_URL`·`SUPABASE_ANON_KEY`(필수), `API_BASE_URL`(에뮬레이터 `http://10.0.2.2:8080/api/v1`). 하드코딩 기본값 없음. 딥링크 복귀 scheme `app.ieoseo://login-callback` 은 Android `AndroidManifest.xml`(intent-filter)·iOS `Info.plist`(CFBundleURLTypes scheme `app.ieoseo`)·Supabase 대시보드 Redirect URLs 에 동일하게 등록(셋 다 일치해야 복귀 동작). 네이티브 SDK scheme(google_sign_in·kakao)은 미사용이라 제거.
- 보안: 세션은 supabase_flutter 가 보관(평문 로깅 금지), dio 타임아웃 필수. 계약: `../docs/05-API/auth.md`.

## 제안 구조 (구현 착수 시)
```
lib/
├── theme/      # DkTokens, DkTheme, TweakSettings
├── data/       # 불변 모델, repository(추상+mock), 도메인 헬퍼(dday/format)
├── widgets/    # 공용 컴포넌트(Btn/Badge/Ring/Segmented/Card/TabBar/Sheet/Toast...)
├── parts/      # AppHeader/TaskRow/DdayHero/MetricBar
└── screens/    # today/plan/focus/me/review/calendar/task/settings/onboard/calc + sheets
```

## 실행
- 설정값은 **`.env.json`**(dart-define-from-file)으로 관리한다. 최초 1회: `cp .env.json.example .env.json` 후 값 채움(**필수**: `SUPABASE_URL`·`SUPABASE_ANON_KEY`, `API_BASE_URL` 에뮬레이터=`http://10.0.2.2:8080/api/v1`). `.env.json` 은 gitignore. 미설정 시 `main` 의 assert 로 빠르게 실패한다(특정 프로젝트 URL 을 소스에 하드코딩하지 않음).
- `flutter pub get` → `flutter run --dart-define-from-file=.env.json` (IntelliJ 는 Run config 의 Additional run args 에 동일 플래그).
- 분석/포맷: `flutter analyze`, `dart format .`
- 테스트: `flutter test` (유틸/도메인·위젯; 시각은 골든/스크린샷 보조).

## 릴리스 빌드 (Play)
- **API base**: 기본값이 운영(Azure App Service)이라 별도 주입 없이 운영을 향한다. 로컬은 `--dart-define=API_BASE_URL=http://localhost:8080/api/v1` 로 오버라이드.
- **서명**: `cd android && cp key.properties.example key.properties` → `keytool` 로 업로드 keystore 생성 후 경로·비번 기입(미커밋). key.properties 없으면 debug 키 폴백(빌드는 됨).
- **앱 아이콘**: `assets/icon/ieoseo-icon-1024.png` → `dart run flutter_launcher_icons` 로 생성. 표시 이름 "이어서".
- **빌드**: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` (Play 업로드).
- ⚠️ **ARM macOS 도커로는 Android AOT 릴리스 빌드 불가**(엔진 크로스컴파일러 부재) — 네이티브 Flutter 설치 또는 CI(x64)에서 빌드한다.
