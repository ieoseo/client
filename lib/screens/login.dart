import 'package:flutter/widgets.dart';

import '../data/api/api_exception.dart';
import '../data/auth/auth_controller.dart';
import '../data/auth/social_auth.dart';
import '../theme/tokens.dart';
import '../widgets/dk_button.dart';
import '../widgets/dk_logo.dart';

/// 로그인 화면에 노출할 소셜 provider(ADR-0014).
///
/// 현재는 **이메일 우선**이라 소셜 버튼은 숨긴다(연동 코드는 유지). 소셜을 다시 노출하려면
/// 이 집합에 provider 를 추가한다(예: `SocialProvider.kakao`). Kakao 는 비즈앱 전환 후.
const Set<SocialProvider> kVisibleSocialProviders = <SocialProvider>{};

/// 로그인 / 회원가입 모드.
enum _LoginMode { login, signup }

/// 로그인 화면(이메일 가입/로그인, ADR-0014).
///
/// 이메일 가입은 Supabase `signUp`(닉네임 없음) → 가입 직후 닉네임 설정 화면([justSignedUp]).
/// 로그인은 `signInWithPassword`. 소셜은 [kVisibleSocialProviders] 가 비어 있어 숨김.
/// 성공 시 진입 전환은 main.dart 가 [AuthController.status]/[AuthController.justSignedUp] 으로 처리.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth, this.onLogin});

  /// 인증 컨트롤러. 이메일 가입/로그인·소셜 oauthSignIn 실호출에 사용.
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

/// 비밀번호 최소 길이(Supabase 기본 정책: 6자+).
const int _kMinPasswordLength = 6;

class _LoginScreenState extends State<LoginScreen> {
  _LoginMode _mode = _LoginMode.signup;

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _submitting = false;
  String? _error;

  /// 진행 중인 소셜 provider(버튼별 로딩 표시). 없으면 null.
  SocialProvider? _socialBusy;

  bool get _busy => _submitting || _socialBusy != null;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// 입력 검증. 통과하면 null, 실패하면 사용자 메시지.
  String? _validate() {
    final String email = _email.text.trim();
    final String password = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      return '이메일 형식을 확인해 주세요.';
    }
    if (password.length < _kMinPasswordLength) {
      return '비밀번호는 $_kMinPasswordLength자 이상이어야 해요.';
    }
    return null;
  }

  Future<void> _submit(bool isLogin) async {
    if (_busy) return;
    final String? invalid = _validate();
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (isLogin) {
        await widget.auth.emailSignIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await widget.auth.emailSignUp(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      // 성공: 진입 게이트(main.dart)가 상태 변화를 받아 전환한다(가입→닉네임, 로그인→main).
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Supabase 인증 예외를 사용자 메시지로 정규화(평문 그대로 노출 방지).
  String _friendlyError(Object e) {
    final String s = e.toString().toLowerCase();
    if (s.contains('already registered') || s.contains('already exists')) {
      return '이미 가입된 이메일이에요. 로그인해 주세요.';
    }
    if (s.contains('invalid login') || s.contains('credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않아요.';
    }
    return '문제가 발생했어요. 잠시 후 다시 시도해 주세요.';
  }

  /// 소셜 로그인(ADR-0014). 현재는 버튼이 숨겨져 호출되지 않지만 재노출 대비 유지.
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
    final bool isLogin = _mode == _LoginMode.login;

    final List<_SocialSpec> social =
        <_SocialSpec>[
              const _SocialSpec(
                SocialProvider.kakao,
                '카카오로 계속하기',
                Color(0xFFFEE500),
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
                isLogin ? '다시 만나서 반가워요' : '이어서 시작하기',
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
                isLogin ? '오늘 할 일이 기다리고 있어요.' : '이메일로 간편하게 시작해요.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: t.fgSubtle,
                ),
              ),
              const SizedBox(height: 28),
              DkTextInput(
                key: const ValueKey<String>('login-email'),
                placeholder: '이메일',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                enabled: !_busy,
              ),
              const SizedBox(height: 12),
              DkTextInput(
                key: const ValueKey<String>('login-password'),
                placeholder: '비밀번호',
                obscure: true,
                controller: _password,
                enabled: !_busy,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 12),
              DkButton(
                size: DkButtonSize.lg,
                full: true,
                disabled: _busy,
                onPressed: _busy ? null : () => _submit(isLogin),
                child: _submitting
                    ? const _ButtonSpinner()
                    : Text(isLogin ? '로그인' : '가입하기'),
              ),
              if (social.isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(child: Container(height: 1, color: t.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '또는',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: t.fgDisabled,
                        ),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: t.border)),
                  ],
                ),
                const SizedBox(height: 18),
                for (final _SocialSpec s in social) ...<Widget>[
                  _socialButton(s),
                  const SizedBox(height: 10),
                ],
              ],
              const SizedBox(height: 14),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      isLogin ? '아직 계정이 없나요? ' : '이미 계정이 있나요? ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: t.fgSubtle,
                      ),
                    ),
                    GestureDetector(
                      onTap: _busy
                          ? null
                          : () => setState(() {
                              _mode = isLogin
                                  ? _LoginMode.signup
                                  : _LoginMode.login;
                              _error = null;
                            }),
                      child: Text(
                        isLogin ? '회원가입' : '로그인',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: t.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

/// 제출 중 버튼 스피너. 흰색 회전 인디케이터.
class _ButtonSpinner extends StatefulWidget {
  const _ButtonSpinner();

  @override
  State<_ButtonSpinner> createState() => _ButtonSpinnerState();
}

class _ButtonSpinnerState extends State<_ButtonSpinner>
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
        child: CustomPaint(painter: _SpinnerPainter()),
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

/// 텍스트 입력. 프로토타입 `TextInput`: border 1.5, radius 12, padding 13×14,
/// focus 시 primary 테두리 + 3px primary-subtle ring.
///
/// 로그인·닉네임 설정·시트·설정 다이얼로그가 재사용하는 공용 입력 위젯이다.
class DkTextInput extends StatefulWidget {
  const DkTextInput({
    super.key,
    required this.placeholder,
    this.obscure = false,
    this.controller,
    this.keyboardType,
    this.enabled = true,
  });

  final String placeholder;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  State<DkTextInput> createState() => _DkTextInputState();
}

class _DkTextInputState extends State<DkTextInput> {
  final FocusNode _node = FocusNode();
  late final TextEditingController _controller;
  bool _ownsController = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;
    _node.addListener(() => setState(() => _focused = _node.hasFocus));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _node.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final TextStyle textStyle = TextStyle(
      fontFamily: 'Pretendard',
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: t.fg,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _focused
            ? <BoxShadow>[BoxShadow(color: t.primarySubtle, spreadRadius: 3)]
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? t.primary : t.border,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: <Widget>[
            if (_controller.text.isEmpty)
              Text(
                widget.placeholder,
                style: textStyle.copyWith(color: t.fgDisabled),
              ),
            EditableText(
              controller: _controller,
              focusNode: _node,
              style: textStyle,
              cursorColor: t.primary,
              backgroundCursorColor: t.primary,
              obscureText: widget.obscure,
              readOnly: !widget.enabled,
              keyboardType: widget.keyboardType ?? TextInputType.text,
            ),
          ],
        ),
      ),
    );
  }
}
