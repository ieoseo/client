// 서버 없이 전체 화면을 직접 점검하기 위한 개발 전용 진입점.
//
// 실행: flutter run -t lib/main_dev.dart
//
// 운영 진입점(main.dart)과 분리돼 있고, 운영/인증 코드는 전혀 건드리지 않는다.
// 데이터는 MockRepository(인메모리), 알림/설정은 빈 목 소스를 주입한다.
// 런처에서 진입 화면(스플래시·온보딩·로그인)과 메인 앱(4탭 + 하위 화면 전부)을
// 서버 없이 오갈 수 있다. 로그인 "제출"만 서버가 필요하므로 그 버튼은 동작하지
// 않지만, 화면 UI 자체는 그대로 점검할 수 있다.
import 'package:flutter/material.dart';

import 'data/api/auth_dto.dart';
import 'data/api/notif_api.dart';
import 'data/api/notif_dto.dart';
import 'data/api/settings_api.dart';
import 'data/api/settings_dto.dart';
import 'data/auth/auth_controller.dart';
import 'data/data_controller.dart';
import 'data/notif_controller.dart';
import 'data/repository.dart';
import 'data/settings_controller.dart';
import 'screens/login.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding.dart';
import 'screens/splash.dart';
import 'theme/tokens.dart';
import 'theme/tweaks.dart';

void main() => runApp(const DevApp());

/// 점검용 더미 사용자(인증 게이트를 통과한 메인 화면에 주입).
const AuthUser _demoUser = AuthUser(
  id: 'dev-1',
  email: 'dev@ieoseo.app',
  nickname: '점검',
  provider: 'LOCAL',
);

/// 알림 없는 인메모리 소스(서버 미연동 점검용).
class _EmptyNotifSource implements NotifSource {
  @override
  Future<NotifListResult> list() async =>
      const NotifListResult(items: <DkNotif>[], unreadCount: 0);

  @override
  Future<DkNotif> markRead(String id) => throw UnimplementedError();

  @override
  Future<int> markAllRead() async => 0;
}

/// 기본값을 돌려주는 인메모리 설정 소스(서버 미연동 점검용).
class _FakeSettingsSource implements SettingsSource {
  @override
  Future<DkSettings> get() async => const DkSettings();

  @override
  Future<DkSettings> put(DkSettings settings) async => settings;
}

/// 개발 런처 루트. 토큰을 모든 라우트에 내려보내고(다크 토글 포함) 화면을 라우팅한다.
class DevApp extends StatefulWidget {
  const DevApp({super.key});

  @override
  State<DevApp> createState() => _DevAppState();
}

class _DevAppState extends State<DevApp> {
  TweakSettings _tweaks = const TweakSettings();

  void _toggleDark(bool v) =>
      setState(() => _tweaks = _tweaks.copyWith(dark: v));

  @override
  Widget build(BuildContext context) {
    final DkTokens tokens = DkTokens.build(_tweaks);

    return MaterialApp(
      title: '이어서 (DEV)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: tokens.page,
        fontFamily: 'Pretendard',
      ),
      // builder 로 감싸 push 된 라우트까지 동일한 토큰/텍스트 스타일을 받게 한다.
      builder: (BuildContext context, Widget? child) => DkTheme(
        tokens: tokens,
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: tokens.baseFontSize,
            color: tokens.fg,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: _DevLauncher(dark: _tweaks.dark, onToggleDark: _toggleDark),
    );
  }
}

/// 점검할 화면을 고르는 런처. 각 항목은 새 라우트로 푸시되어 독립적으로 열린다.
class _DevLauncher extends StatelessWidget {
  const _DevLauncher({required this.dark, required this.onToggleDark});

  final bool dark;
  final ValueChanged<bool> onToggleDark;

  void _open(BuildContext context, Widget Function() build) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => build()));
  }

  /// 메인 셸(4탭 + 하위 화면 전부)을 목 컨트롤러로 구성한다.
  Widget _mainApp() => MainScaffold(
    controller: DataController(MockRepository()),
    notif: NotifController(_EmptyNotifSource()),
    settings: SettingsController(_FakeSettingsSource()),
    user: _demoUser,
    dark: dark,
    onToggleDark: onToggleDark,
    onLogout: () {},
    onUpdateProfile: (_) async {},
    onWithdraw: () async {},
  );

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);

    final List<(String, String, Widget Function())> entries =
        <(String, String, Widget Function())>[
          ('메인 앱', '오늘·플랜·집중·나 + 하위 화면 전부 (서버 없음)', _mainApp),
          ('스플래시', '진입 1단계', () => SplashScreen(onDone: () {})),
          ('온보딩', '진입 2단계', () => OnboardingScreen(onDone: () {})),
          (
            '로그인',
            '진입 3단계 (UI 점검용 · 제출은 서버 필요)',
            () => LoginScreen(auth: AuthController()),
          ),
        ];

    return Scaffold(
      backgroundColor: t.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '화면 점검 (DEV)',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: t.fg,
                      ),
                    ),
                  ),
                  Text('다크', style: TextStyle(color: t.fgMuted, fontSize: 13)),
                  const SizedBox(width: 6),
                  Switch(value: dark, onChanged: onToggleDark),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '서버 없이 목 데이터로 동작합니다.',
                style: TextStyle(color: t.fgMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int i) {
                    final (String title, String desc, Widget Function() build) =
                        entries[i];
                    return _LauncherTile(
                      title: title,
                      desc: desc,
                      onTap: () => _open(context, build),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 런처의 단일 항목 카드.
class _LauncherTile extends StatelessWidget {
  const _LauncherTile({
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Material(
      color: t.bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: t.fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(fontSize: 13, color: t.fgMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.fgMuted),
            ],
          ),
        ),
      ),
    );
  }
}
