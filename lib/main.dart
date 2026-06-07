import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'data/api/api_repository.dart';
import 'data/api/notif_api.dart';
import 'data/api/settings_api.dart';
import 'data/auth/auth_controller.dart';
import 'data/auth/auth_sdk_token_provider.dart';
import 'data/data_controller.dart';
import 'data/notif_controller.dart';
import 'data/settings_controller.dart';
import 'observability/sentry_config.dart';
import 'screens/login.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding.dart';
import 'screens/splash.dart';
import 'theme/tokens.dart';
import 'theme/tweaks.dart';

/// 앱 진입점. Sentry DSN(`--dart-define=SENTRY_DSN`)이 설정돼 있으면 Sentry 로 감싸
/// 미처리 예외를 보고하고, 미설정이면 곧장 앱을 띄운다(외부 전송 0, ADR-0011).
Future<void> main() async {
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
  AppPhase _phase = AppPhase.splash;

  late final AuthController _auth;
  late final DataController _data;
  late final NotifController _notif;
  late final SettingsController _settings;

  @override
  void initState() {
    super.initState();
    _auth =
        widget._injectedAuth ??
        AuthController(
          // 소셜 로그인 SDK 토큰 획득(이슈 #38). 키는 --dart-define 으로 주입.
          social: AuthSdkTokenProvider(
            config: SocialAuthConfig.fromEnvironment(),
          ),
        );
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
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => setState(() {});

  void _setTweaks(TweakSettings next) => setState(() => _tweaks = next);

  @override
  Widget build(BuildContext context) {
    final DkTokens tokens = DkTokens.build(_tweaks);

    return MaterialApp(
      title: '이어서',
      debugShowCheckedModeBanner: false,
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
      );
      return Container(color: tokens.page, child: body);
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
