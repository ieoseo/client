import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/api/api_config.dart';
import 'data/api/api_repository.dart';
import 'data/api/notif_api.dart';
import 'data/api/settings_api.dart';
import 'data/auth/auth_controller.dart';
import 'data/auth/supabase_config.dart';
import 'data/data_controller.dart';
import 'data/notif_controller.dart';
import 'data/settings_controller.dart';
import 'observability/sentry_config.dart';
import 'screens/login.dart';
import 'screens/main_scaffold.dart';
import 'screens/auth_loading.dart';
import 'screens/onboarding.dart';
import 'screens/splash.dart';
import 'theme/tokens.dart';
import 'theme/tweak_store.dart';
import 'theme/tweaks.dart';

/// 앱 진입점. Sentry DSN(`--dart-define=SENTRY_DSN`)이 설정돼 있으면 Sentry 로 감싸
/// 미처리 예외를 보고하고, 미설정이면 곧장 앱을 띄운다(외부 전송 0, ADR-0011).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 인증은 Supabase Auth(ADR-0014) — 세션·토큰을 supabase_flutter 가 관리한다.
  // anonKey 는 --dart-define=SUPABASE_ANON_KEY 로 주입(미주입 시 초기화 실패).
  final SupabaseConfig supa = SupabaseConfig.fromEnvironment();
  // assert 는 release 빌드에서 제거되므로 런타임 가드로 빠르게 실패한다 — 미설정 시
  // 빈 값으로 Supabase.initialize 가 호출돼 모호하게 크래시하는 것을 막는다.
  if (!supa.isConfigured) {
    throw StateError(
      'SUPABASE_URL·SUPABASE_ANON_KEY 가 필요합니다. '
      '--dart-define-from-file=.env.json 로 실행하세요(.env.json.example 참조).',
    );
  }
  // API base URL 도 env 주입(소스에 URL 하드코딩 금지) — 미주입이면 잘못된 서버를
  // 향하지 않도록 빠르게 실패한다. 로컬은 .env.json, 운영은 .env.prod.json.
  if (apiBaseUrl.isEmpty) {
    throw StateError(
      'API_BASE_URL 가 필요합니다. 로컬은 .env.json, 운영은 .env.prod.json 으로 '
      '--dart-define-from-file 주입하세요(docs/가이드/환경변수.md).',
    );
  }
  // anonKey: 레거시 anon(public) 키 사용. publishable 키로 전환 시 교체.
  // ignore: deprecated_member_use
  await Supabase.initialize(url: supa.url, anonKey: supa.anonKey);

  final SentryConfig sentry = SentryConfig.fromEnvironment();
  if (!sentry.isEnabled) {
    runApp(const IeoseoApp());
    return;
  }

  await SentryFlutter.init(
    (options) => _applySentryOptions(options, sentry),
    appRunner: () => runApp(const IeoseoApp()),
  );
}

/// Sentry 초기화 옵션을 [config] 값으로 채운다(main 의 init 콜백에서 호출).
void _applySentryOptions(SentryFlutterOptions options, SentryConfig config) {
  options.dsn = config.dsn;
  options.environment = config.environment;
  options.tracesSampleRate = config.tracesSampleRate;
}

/// 앱 진입 단계(인증 전 화면 흐름). main 진입 여부는 [AuthController.status]가 결정.
enum AppPhase { splash, onboarding, auth }

/// 이어서 루트. `DkTheme`로 토큰을 내려보내고 진입 게이트로 화면을 라우팅한다.
///
/// 부팅 시 저장 토큰 복원([AuthController.tryRestore])을 시도한다. 복원 성공이면
/// 스플래시 직후 곧장 main, 아니면 splash→onboarding→인증 화면으로 진행한다.
/// 데이터(events/tasks/debts)는 [ApiRepository]로 server 실연동(이슈 #35).
class IeoseoApp extends StatefulWidget {
  const IeoseoApp({
    super.key,
    AuthController? auth,
    DataController? data,
    NotifController? notif,
    SettingsController? settings,
  }) : _injectedAuth = auth,
       _injectedData = data,
       _injectedNotif = notif,
       _injectedSettings = settings;

  /// 테스트 주입용 인증 컨트롤러. 미지정 시 기본 컨트롤러를 만든다.
  final AuthController? _injectedAuth;

  /// 테스트 주입용 데이터 컨트롤러. 미지정 시 ApiRepository 기반으로 만든다.
  final DataController? _injectedData;

  /// 테스트 주입용 알림 컨트롤러. 미지정 시 NotifApi 기반으로 만든다.
  final NotifController? _injectedNotif;

  /// 테스트 주입용 설정 컨트롤러. 미지정 시 SettingsApi 기반으로 만든다.
  final SettingsController? _injectedSettings;

  @override
  State<IeoseoApp> createState() => _IeoseoAppState();
}

class _IeoseoAppState extends State<IeoseoApp> {
  TweakSettings _tweaks = const TweakSettings();
  final TweakStore _tweakStore = const TweakStore();
  AppPhase _phase = AppPhase.splash;

  late final AuthController _auth;
  late final DataController _data;
  late final NotifController _notif;
  late final SettingsController _settings;

  @override
  void initState() {
    super.initState();
    // 소셜은 Supabase signInWithOAuth(웹 흐름)로 처리한다 — 앱 내 SDK/클라이언트 불필요(ADR-0014).
    _auth = widget._injectedAuth ?? AuthController();
    // 데이터 레이어는 인증 클라이언트(Bearer + refresh)를 재사용한다.
    _data =
        widget._injectedData ?? DataController(ApiRepository(_auth.apiClient));
    // 알림 레이어도 같은 인증 클라이언트를 재사용한다(이슈 #46).
    _notif =
        widget._injectedNotif ?? NotifController(NotifApi(_auth.apiClient));
    // 설정 레이어도 같은 인증 클라이언트를 재사용한다(이슈 #56).
    _settings =
        widget._injectedSettings ??
        SettingsController(SettingsApi(_auth.apiClient));
    _auth.addListener(_onAuthChanged);
    // 저장 토큰 복원 시도(결과는 status로 반영, _onAuthChanged가 수신).
    _auth.tryRestore();
    // 저장된 화면 설정(다크모드 등)을 복원한다 — 앱 재시작에도 유지.
    unawaited(_loadTweaks());
  }

  /// 로컬에 저장된 [TweakSettings](다크모드 포함)를 읽어 반영한다.
  Future<void> _loadTweaks() async {
    final TweakSettings loaded = await _tweakStore.load();
    if (mounted) setState(() => _tweaks = loaded);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => setState(() {});

  void _setTweaks(TweakSettings next) {
    setState(() => _tweaks = next);
    // 변경 즉시 로컬에 저장 — 다음 실행에 복원된다(다크모드 초기화 버그 해소).
    unawaited(_tweakStore.save(next));
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens tokens = DkTokens.build(_tweaks);

    return MaterialApp(
      title: '이어서',
      debugShowCheckedModeBanner: false,
      // Supabase OAuth 콜백 딥링크(app.ieoseo://login-callback?code=...)는 Navigator
      // 전환이 필요 없다 — 세션 완성은 supabase_flutter + AuthController.onSignedIn 이
      // 처리한다. 자동 딥링크가 이를 named route 로 열려다 "route generator 없음"으로
      // 크래시하는 것을 흡수하되, 첫 프레임에 곧장 pop 해 home 입력을 막지 않는다
      // (modal barrier 가 남으면 화면이 안 눌린다).
      onGenerateRoute: (RouteSettings settings) => PageRouteBuilder<void>(
        settings: settings,
        opaque: false,
        barrierDismissible: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (BuildContext context, _, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final NavigatorState nav = Navigator.of(context);
            if (nav.canPop()) nav.pop();
          });
          return const SizedBox.shrink();
        },
      ),
      theme: ThemeData(
        scaffoldBackgroundColor: tokens.page,
        fontFamily: 'Pretendard',
      ),
      home: DkTheme(
        tokens: tokens,
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: tokens.baseFontSize,
            color: tokens.fg,
          ),
          child: _buildPhase(tokens),
        ),
      ),
    );
  }

  Widget _buildPhase(DkTokens tokens) {
    final Widget body;

    // 인증되면 진입 흐름과 무관하게 main으로 전환(로그인/복원 공통 게이트).
    if (_auth.status == AuthStatus.authenticated && _auth.user != null) {
      body = MainScaffold(
        controller: _data,
        notif: _notif,
        settings: _settings,
        user: _auth.user!,
        dark: _tweaks.dark,
        onToggleDark: (bool v) => _setTweaks(_tweaks.copyWith(dark: v)),
        onLogout: _auth.logout,
        onUpdateProfile: (String nickname) =>
            _auth.updateProfile(nickname: nickname),
        onWithdraw: _auth.withdraw,
        linkedProviders: _auth.linkedProviders,
        onLinkAccount: _auth.linkAccount,
        onUnlinkAccount: _auth.unlinkAccount,
      );
      return Container(color: tokens.page, child: body);
    }

    // 외부 OAuth 복귀 후 server provisioning(`/auth/me`) 중에는 로그인 화면을 다시
    // 보여주지 않고 브랜드 로딩을 띄운다 — 브라우저 → (로고+안내) → home 의 자연스러운 전환.
    if (_auth.isAuthenticating) {
      return const AuthLoadingView();
    }

    switch (_phase) {
      case AppPhase.splash:
        body = SplashScreen(
          onDone: () => setState(() => _phase = AppPhase.onboarding),
        );
      case AppPhase.onboarding:
        body = OnboardingScreen(
          onDone: () => setState(() => _phase = AppPhase.auth),
        );
      case AppPhase.auth:
        // 이메일·소셜 모두 _auth 로 실호출. 성공 시 status 변화로 main 전환.
        body = LoginScreen(auth: _auth);
    }

    return Container(color: tokens.page, child: body);
  }
}
