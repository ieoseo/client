import 'package:flutter/widgets.dart';

import '../data/api/api_exception.dart';
import '../data/auth/auth_controller.dart';
import '../theme/tokens.dart';
import '../widgets/dk_button.dart';
import '../widgets/dk_logo.dart';
import 'login.dart' show DkTextInput;

/// 닉네임 최대 길이(서버 정책과 동일).
const int _kNicknameMaxLength = 20;

/// 이메일 회원가입 직후 닉네임을 정하는 화면(ADR-0014).
///
/// Supabase 가입은 닉네임을 받지 않으므로, 가입 직후 이 화면에서 받아
/// server `/auth/me`(PATCH)로 저장한다([AuthController.updateProfile]).
/// 성공하면 [AuthController.justSignedUp] 이 false 가 되어 진입 게이트가 main 으로 전환한다.
class NicknameSetupScreen extends StatefulWidget {
  const NicknameSetupScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends State<NicknameSetupScreen> {
  final TextEditingController _nickname = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  String? _validate() {
    final String value = _nickname.text.trim();
    if (value.isEmpty) return '닉네임을 입력해 주세요.';
    if (value.length > _kNicknameMaxLength) {
      return '닉네임은 $_kNicknameMaxLength자 이하여야 해요.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
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
      await widget.auth.updateProfile(nickname: _nickname.text.trim());
      // 성공: justSignedUp=false → main.dart 가 main 으로 전환.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '문제가 발생했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
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
                '닉네임을 정해주세요',
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
                '이어서에서 보여질 이름이에요. 나중에 바꿀 수 있어요.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: t.fgSubtle,
                ),
              ),
              const SizedBox(height: 28),
              DkTextInput(
                key: const ValueKey<String>('nickname-input'),
                placeholder: '닉네임',
                controller: _nickname,
                enabled: !_submitting,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: t.dangerSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: t.danger,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DkButton(
                size: DkButtonSize.lg,
                full: true,
                disabled: _submitting,
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '저장 중...' : '시작하기'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
