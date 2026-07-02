import 'package:flutter/widgets.dart';
import 'package:ieoseo/theme/seed_tokens.dart';

import '../data/api/api_exception.dart';
import '../data/auth/auth_controller.dart';
import '../data/auth/social_auth.dart';
import '../theme/tokens.dart';
import '../widgets/dk_brand_mark.dart';
import '../widgets/dk_logo.dart';

/// 로그인 화면에 노출할 소셜 provider(ADR-0014, ADR-0023).
///
/// 이 집합에 있는 provider 만 로그인 버튼으로 노출한다. DayKit 핸드오프대로 카카오·Google·
/// Apple 3종을 노출한다(Apple 실동작은 Supabase Apple provider 설정이 선행 전제).
const Set<SocialProvider> kVisibleSocialProviders = <SocialProvider>{
  SocialProvider.kakao,
  SocialProvider.google,
  SocialProvider.apple,
};

/// 로그인 화면(소셜 전용, ADR-0023).
///
/// 모든 provider 는 Supabase `signInWithOAuth`(브라우저 + 딥링크) 웹 흐름이다 — 인증은
/// Supabase(web client)가 처리하므로 앱 내 client id·네이티브 SDK 불필요. 성공 시 진입
/// 전환은 main.dart 가 [AuthController.status] 로 처리한다(닉네임은 `/auth/me` provisioning).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth, this.onLogin});

  /// 인증 컨트롤러. 소셜 oauthSignIn 실호출에 사용.
  final AuthController auth;

  /// (선택) 레거시 진입 콜백. 성공 시 진입은 main.dart 가 상태 변화로 처리한다.
  final VoidCallback? onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _SocialSpec {
  const _SocialSpec(
    this.provider,
    this.label,
    this.bg,
    this.fg, {
    required this.brand,
    this.bordered = false,
  });
  final SocialProvider provider;
  final String label;
  final Color bg;
  final Color fg;

  /// 브랜드 로고 키([DkBrandMark]): 'kakao' / 'google'.
  final String brand;
  final bool bordered;
}

class _LoginScreenState extends State<LoginScreen> {
  String? _error;

  /// 진행 중인 소셜 provider(버튼별 로딩 표시). 없으면 null.
  SocialProvider? _socialBusy;

  bool get _busy => _socialBusy != null;

  @override
  void initState() {
    super.initState();
    // 딥링크 복귀 provisioning 실패(#156)는 버튼 핸들러 밖(컨트롤러 스트림)에서 발생하므로
    // 컨트롤러를 구독해 authError 를 배너로 반영한다.
    widget.auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  /// 로컬 오류(버튼 직접 실패) 우선, 없으면 컨트롤러의 out-of-band provisioning 오류(#156).
  String? get _bannerError => _error ?? widget.auth.authError;

  /// 소셜 로그인(ADR-0014, ADR-0023). Supabase `signInWithOAuth`(브라우저 + 딥링크)로 위임한다.
  Future<void> _socialSignIn(SocialProvider provider) async {
    if (_busy) return;
    widget.auth.clearAuthError();
    setState(() {
      _socialBusy = provider;
      _error = null;
    });
    try {
      await widget.auth.oauthSignIn(provider);
    } on SocialSignInCancelled {
      // 사용자 취소 — 무시.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '소셜 로그인에 실패했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _socialBusy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);

    final List<_SocialSpec> social =
        <_SocialSpec>[
              const _SocialSpec(
                SocialProvider.kakao,
                '카카오로 시작하기',
                SeedSource.kakao,
                Color(0xFF191600),
                brand: 'kakao',
              ),
              _SocialSpec(
                SocialProvider.google,
                'Google로 시작하기',
                t.bg,
                t.fg,
                brand: 'google',
                bordered: true,
              ),
              const _SocialSpec(
                SocialProvider.apple,
                'Apple로 시작하기',
                Color(0xFF000000),
                Color(0xFFFFFFFF),
                brand: 'apple',
              ),
            ]
            .where(
              (_SocialSpec s) => kVisibleSocialProviders.contains(s.provider),
            )
            .toList();

    return Container(
      color: t.bg,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(child: Center(child: _Hero())),
                      if (_bannerError != null) ...<Widget>[
                        _ErrorBanner(message: _bannerError!),
                        const SizedBox(height: 12),
                      ],
                      for (int i = 0; i < social.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(height: 10),
                        _socialButton(social[i]),
                      ],
                      const SizedBox(height: 18),
                      const _LegalNote(),
                      const SizedBox(height: 34),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _socialButton(_SocialSpec s) {
    final DkTokens t = DkTheme.of(context);
    final bool isBusy = _socialBusy == s.provider;
    // 디자인(DayKit): 글리프는 좌측 18 절대 위치, 라벨/진행문구는 버튼 중앙.
    return GestureDetector(
      key: ValueKey<String>('social-${s.provider.wireName}'),
      onTap: _busy ? null : () => _socialSignIn(s.provider),
      child: Opacity(
        opacity: _busy && !isBusy ? 0.5 : 1,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: s.bg,
            borderRadius: BorderRadius.circular(15),
            border: s.bordered ? Border.all(color: t.border, width: 1.5) : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Text(
                isBusy ? '연결 중…' : s.label,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.155,
                  color: s.fg,
                ),
              ),
              PositionedDirectional(
                start: 18,
                top: 0,
                bottom: 0,
                child: Center(
                  child: isBusy
                      ? _SocialSpinner(color: s.fg)
                      // 버튼 배경 위에 글리프만(박스/테두리 없이) — 무신사식 자연스러운 배치.
                      // 단색 글리프(apple·kakao)는 버튼 전경색으로 틴트, google 은 멀티컬러.
                      : DkBrandMark(
                          brand: s.brand,
                          size: 22,
                          framed: false,
                          glyphColor: s.fg,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 로그인 히어로 브랜드 블록. 로고 + 카피를 중앙 정렬한다(DayKit 핸드오프).
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const DkLogo(size: 56),
        const SizedBox(height: 22),
        Text(
          '오늘을 이어서,\n매일을 끝까지',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.75,
            height: 1.3,
            color: t.fgStrong,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'D-Day · 할 일 · 집중을 하나로.\n3초 만에 시작해요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            height: 1.55,
            color: t.fgSubtle,
          ),
        ),
      ],
    );
  }
}

/// 약관·개인정보처리방침 동의 고지(DayKit 핸드오프). 강조어는 fgMuted.
class _LegalNote extends StatelessWidget {
  const _LegalNote();

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final TextStyle base = TextStyle(
      fontFamily: 'Pretendard',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.6,
      color: t.fgSubtle,
    );
    final TextStyle emphasis = base.copyWith(
      fontWeight: FontWeight.w600,
      color: t.fgMuted,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: <InlineSpan>[
          const TextSpan(text: '로그인 시 '),
          TextSpan(text: '이용약관', style: emphasis),
          const TextSpan(text: '과 '),
          TextSpan(text: '개인정보처리방침', style: emphasis),
          const TextSpan(text: '에\n동의하는 것으로 간주됩니다.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// 인증 오류 안내 배너. danger-subtle 배경 + danger 텍스트.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.dangerSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: t.danger,
        ),
      ),
    );
  }
}

/// 소셜 버튼 진행 중 스피너(이슈 #38). 버튼 전경색([color])으로 회전한다.
class _SocialSpinner extends StatefulWidget {
  const _SocialSpinner({required this.color});

  final Color color;

  @override
  State<_SocialSpinner> createState() => _SocialSpinnerState();
}

class _SocialSpinnerState extends State<_SocialSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: RotationTransition(
        turns: _c,
        child: CustomPaint(painter: _SpinnerPainter(color: widget.color)),
      ),
    );
  }
}

/// 부분 호 스피너. 기본 흰색, [color]로 색을 지정할 수 있다.
class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({this.color = const Color(0xFFFFFFFF)});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final Rect rect = Offset.zero & size;
    canvas.drawArc(rect.deflate(2), -1.57, 4.71, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) =>
      oldDelegate.color != color;
}
