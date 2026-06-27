import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';
import '../../widgets/dk_alert.dart';
import '../../widgets/dk_button.dart';
import '../../widgets/dk_sheet.dart';
import '../sheets/sheet_fields.dart';

/// 계정/설정 다이얼로그 모음(이슈 #56) — 프로필 수정·값 선택·2단계 탈퇴 확인.
///
/// 모두 [DkSheet] 모션으로 띄운다. 값 선택은 옵션 칩에서 고르면 즉시 닫히며 결과를 반환한다.

/// 프로필 수정 시트. [initialNickname] 로 시작해 1~20자 닉네임을 입력받아 [onSubmit] 한다.
/// 저장은 비동기(서버 PATCH)이며, 진행 중에는 버튼이 비활성화된다.
Future<void> showProfileEditSheet(
  BuildContext context, {
  required String initialNickname,
  required Future<void> Function(String nickname) onSubmit,
}) {
  return showDkSheet<void>(
    context,
    title: '프로필 수정',
    child: _ProfileEditForm(initial: initialNickname, onSubmit: onSubmit),
  );
}

class _ProfileEditForm extends StatefulWidget {
  const _ProfileEditForm({required this.initial, required this.onSubmit});

  final String initial;
  final Future<void> Function(String nickname) onSubmit;

  @override
  State<_ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<_ProfileEditForm> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String next = _controller.text.trim();
    if (next.isEmpty || next.length > 20 || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(next);
      if (mounted) Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '닉네임',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.fgSubtle,
            ),
          ),
        ),
        DkTextInput(controller: _controller, placeholder: '닉네임 (1~20자)'),
        const SizedBox(height: 16),
        DkButton(
          full: true,
          size: DkButtonSize.lg,
          disabled: _saving,
          onPressed: _submit,
          child: Text(_saving ? '저장 중…' : '저장'),
        ),
      ],
    );
  }
}

/// 하루 마감 시각(0~23시) 선택. 선택한 시(hour)를 반환, 취소면 null.
Future<int?> showDeadlineHourPicker(
  BuildContext context, {
  required int current,
}) {
  const List<int> hours = <int>[0, 6, 7, 8, 22, 23];
  return _showOptionPicker<int>(
    context,
    title: '하루 마감 시각',
    current: current,
    options: <_Option<int>>[
      for (final int h in hours)
        _Option<int>(
          h,
          h == 0 ? '자정 (00:00)' : '${h.toString().padLeft(2, '0')}:00',
        ),
    ],
  );
}

/// 하루 최대 예약 시간(분) 선택. 선택한 분을 반환, 취소면 null.
Future<int?> showMaxMinutesPicker(
  BuildContext context, {
  required int current,
}) {
  const List<int> presets = <int>[240, 360, 480, 600, 720];
  return _showOptionPicker<int>(
    context,
    title: '하루 최대 예약 시간',
    current: current,
    options: <_Option<int>>[
      for (final int m in presets) _Option<int>(m, '${m ~/ 60}시간'),
    ],
  );
}

/// 주간 시작 요일 선택(월/일). 일요일은 빨간색으로 강조한다. 'MON'/'SUN' 반환, 취소면 null.
Future<String?> showWeekStartPicker(
  BuildContext context, {
  required String current,
}) {
  final DkTokens t = DkTheme.of(context);
  return _showOptionPicker<String>(
    context,
    title: '주간 시작 요일',
    current: current,
    options: <_Option<String>>[
      const _Option<String>('MON', '월요일'),
      _Option<String>('SUN', '일요일', color: t.danger),
    ],
  );
}

/// 분 단위 값(포모도로 등) 선택. 선택한 분을 반환, 취소면 null.
Future<int?> showMinutePicker(
  BuildContext context, {
  required String title,
  required int current,
  required List<int> options,
}) {
  return _showOptionPicker<int>(
    context,
    title: title,
    current: current,
    options: <_Option<int>>[
      for (final int m in options) _Option<int>(m, '$m분'),
    ],
  );
}

/// 회원 탈퇴 2단계 확인(이슈 #56). 1단계 안내 → 2단계 최종 확인 → 통과 시 [onConfirm].
/// 어느 단계든 취소하면 아무 일도 하지 않는다.
Future<void> confirmWithdraw(
  BuildContext context,
  Future<void> Function() onConfirm,
) async {
  final bool? first = await _showConfirm(
    context,
    title: '회원 탈퇴',
    body: '탈퇴하면 계정이 비활성화되고 로그인할 수 없어요. 계속할까요?',
    confirmLabel: '계속',
  );
  if (first != true || !context.mounted) return;

  final bool? second = await _showConfirm(
    context,
    title: '정말 탈퇴할까요?',
    body: '이 작업은 되돌릴 수 없어요. 탈퇴를 확정하려면 아래 버튼을 눌러 주세요.',
    confirmLabel: '탈퇴하기',
    destructive: true,
  );
  if (second != true) return;

  await onConfirm();
}

/// 소셜 계정 연결 해제 확인(이슈 #10). 확인하면 true, 취소면 false.
/// 해제는 즉시 Supabase `unlinkIdentity` 로 반영되므로 **중앙 Alert(취소/확인)** 로
/// 명시적 확인을 받는다 — '확인' 을 눌러야만 해제된다.
Future<bool> confirmUnlinkAccount(BuildContext context, String label) =>
    showDkConfirmAlert(
      context,
      title: '$label 연결 해제',
      body: '$label 계정 연결을 해제할까요? 해제 후에는 이 계정으로 로그인할 수 없어요.',
      confirmLabel: '확인',
      destructive: true,
    );

// --- 내부 헬퍼 ---

class _Option<T> {
  const _Option(this.value, this.label, {this.color});
  final T value;
  final String label;

  /// 라벨 강조색(선택 여부와 무관, 예: 일요일 빨강). null이면 기본 톤.
  final Color? color;
}

Future<T?> _showOptionPicker<T>(
  BuildContext context, {
  required String title,
  required T current,
  required List<_Option<T>> options,
}) {
  return showDkSheet<T>(
    context,
    title: title,
    child: Builder(
      builder: (BuildContext context) {
        final DkTokens t = DkTheme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final _Option<T> opt in options)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(opt.value),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: opt.value == current ? t.primarySubtle : t.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: opt.value == current ? t.primary : t.borderSubtle,
                      width: opt.value == current ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      // 옵션 강조색(예: 일요일 빨강)이 있으면 선택 여부와 무관하게 우선.
                      color:
                          opt.color ??
                          (opt.value == current ? t.primary : t.fg),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

Future<bool?> _showConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDkSheet<bool>(
    context,
    title: title,
    child: Builder(
      builder: (BuildContext context) {
        final DkTokens t = DkTheme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              body,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14.5,
                height: 1.45,
                color: t.fgSubtle,
              ),
            ),
            const SizedBox(height: 18),
            DkButton(
              full: true,
              size: DkButtonSize.lg,
              variant: destructive
                  ? DkButtonVariant.danger
                  : DkButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
            const SizedBox(height: 8),
            DkButton(
              full: true,
              size: DkButtonSize.lg,
              variant: DkButtonVariant.subtle,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
          ],
        );
      },
    ),
  );
}
