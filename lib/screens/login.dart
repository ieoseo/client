import 'package:flutter/widgets.dart';
import 'package:ieoseo/theme/seed_tokens.dart';

import '../data/api/api_exception.dart';
import '../data/auth/auth_controller.dart';
import '../data/auth/social_auth.dart';
import '../theme/tokens.dart';
import '../widgets/dk_logo.dart';

/// 로그인 화면에 노출할 소셜 provider(ADR-0014, ADR-0023).
///
/// 이 집합에 있는 provider 만 로그인 버튼으로 노출한다. Apple 은 후속이라 제외.
const Set<SocialProvider> kVisibleSocialProviders = <SocialProvider>{
  SocialProvider.google,
  SocialProvider.kakao,
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
    this.bordered = false,
  });
  final SocialProvider provider;
  final String label;
  final Color bg;
  final Color fg;
  final bool bordered;
}

class _LoginScreenState extends State<LoginScreen> {
  String? _error;

  /// 진행 중인 소셜 provider(버튼별 로딩 표시). 없으면 null.
  SocialProvider? _socialBusy;

  bool get _busy => _socialBusy != null;

  /// 소셜 로그인(ADR-0014, ADR-0023). Supabase `signInWithOAuth`(브라우저 + 딥링크)로 위임한다.
  Future<void> _socialSignIn(SocialProvider provider) async {
    if (_busy) return;
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
                '카카오로 계속하기',
                SeedSource.kakao,
                Color(0xFF191600),
              ),
              _SocialSpec(
                SocialProvider.google,
                'Google로 계속하기',
                t.bg,
                t.fg,
                bordered: true,
              ),
            ]
            .where(
              (_SocialSpec s) => kVisibleSocialProviders.contains(s.provider),
            )
            .toList();

    return Container(
      color: t.bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 52),
              const Align(
                alignment: Alignment.centerLeft,
                child: DkLogo(size: 42),
              ),
              const SizedBox(height: 26),
              Text(
                '이어서 시작하기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.78,
                  color: t.fgStrong,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '소셜 계정으로 간편하게 시작해요.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: t.fgSubtle,
                ),
              ),
              const SizedBox(height: 28),
              if (_error != null) ...<Widget>[
                _ErrorBanner(message: _error!),
                const SizedBox(height: 12),
              ],
              for (final _SocialSpec s in social) ...<Widget>[
                _socialButton(s),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(_SocialSpec s) {
    final DkTokens t = DkTheme.of(context);
    final bool isBusy = _socialBusy == s.provider;
    return GestureDetector(
      key: ValueKey<String>('social-${s.provider.wireName}'),
      onTap: _busy ? null : () => _socialSignIn(s.provider),
      child: Opacity(
        opacity: _busy && !isBusy ? 0.5 : 1,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: s.bg,
            borderRadius: BorderRadius.circular(14),
            border: s.bordered ? Border.all(color: t.border, width: 1.5) : null,
          ),
          child: isBusy
              ? _SocialSpinner(color: s.fg)
              : Text(
                  s.label,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: s.fg,
                  ),
                ),
        ),
      ),
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
