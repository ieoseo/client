import 'package:flutter/widgets.dart';

import '../data/auth/nickname_suggester.dart';
import '../theme/tokens.dart';
import '../widgets/dk_button.dart';
import '../widgets/dk_logo.dart';
import 'sheets/sheet_fields.dart';

/// 신규 가입 직후 닉네임 설정 화면(모든 provider 공통).
///
/// 진입 게이트가 `AuthUser.isNew` 일 때 main 대신 이 화면을 띄운다(필수 단계).
/// 랜덤 제안(형용사+동물)을 초깃값으로 채워두고, 사용자는 그대로 쓰거나 바꿀 수 있다.
/// "나중에 변경 가능"을 안내한다(프로필에서 수정).
class NicknameSetupScreen extends StatefulWidget {
  const NicknameSetupScreen({super.key, required this.onSubmit});

  /// 닉네임 확정 시 호출(서버 PATCH `/auth/me`). 성공하면 게이트가 main 으로 전환한다.
  final Future<void> Function(String nickname) onSubmit;

  @override
  State<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends State<NicknameSetupScreen> {
  static const int _maxLength = 20;

  late final TextEditingController _controller = TextEditingController(
    text: suggestNickname(),
  );
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // 입력 변화 시 '시작하기' 버튼 활성/비활성을 갱신한다(DkTextInput 은 onChanged 미제공).
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  bool get _valid {
    final String v = _controller.text.trim();
    return v.isNotEmpty && v.length <= _maxLength;
  }

  void _regenerate() {
    setState(() => _controller.text = suggestNickname());
  }

  Future<void> _submit() async {
    if (!_valid || _saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSubmit(_controller.text.trim());
      // 성공 시 게이트(AuthController.user.isNew=false)가 main 으로 전환한다.
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Container(
      color: t.page,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              const DkLogo(size: 40),
              const Spacer(),
              Text(
                '닉네임을 정해주세요',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.03 * 24,
                  color: t.fgStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '이어서에서 사용할 이름이에요. 추천 닉네임을 그대로 쓰거나 바꿔도 좋아요.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14.5,
                  height: 1.5,
                  color: t.fgSubtle,
                ),
              ),
              const SizedBox(height: 20),
              DkTextInput(
                controller: _controller,
                placeholder: '닉네임 (1~$_maxLength자)',
              ),
              const SizedBox(height: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _saving ? null : _regenerate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '🎲 다른 닉네임 추천',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: t.primary,
                    ),
                  ),
                ),
              ),
              if (_failed) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  '닉네임 저장에 실패했어요. 잠시 후 다시 시도해 주세요.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12.5,
                    color: t.danger,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '닉네임은 나중에 프로필에서 언제든 바꿀 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12.5,
                  color: t.fgMuted,
                ),
              ),
              const SizedBox(height: 12),
              DkButton(
                full: true,
                size: DkButtonSize.lg,
                onPressed: _valid && !_saving ? _submit : null,
                child: Text(_saving ? '저장 중…' : '시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
