import 'package:flutter/widgets.dart';

import '../../data/auth/social_auth.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_brand_mark.dart';
import '../../widgets/dk_button.dart';
import 'settings_dialogs.dart';

/// 나 탭 '연동 계정' 섹션(이슈 #10, ADR-0014).
///
/// 현재 연동된 provider(Email/Google/Kakao)를 보여주고, 소셜 계정을 연결([onLink],
/// `linkIdentity`)·해제([onUnlink], `unlinkIdentity`)한다. 이메일은 비밀번호 identity 라
/// 표시만 하고 해제 버튼을 두지 않는다. 마지막 1개 identity 는 해제 버튼을 숨긴다(잠금 방지).
///
/// Supabase 대시보드 'Manual Linking' 활성화가 전제다. 연결은 브라우저+딥링크 비동기 흐름이라
/// 완료는 AuthController 의 onUserUpdated 가 반영한다(이 위젯은 시작만 트리거).
class LinkedAccountsSection extends StatefulWidget {
  const LinkedAccountsSection({
    super.key,
    required this.linkedProviders,
    required this.onLink,
    required this.onUnlink,
  });

  /// 연동된 provider 이름 집합(예: {'email','google','kakao'}).
  final Set<String> linkedProviders;
  final Future<void> Function(SocialProvider provider) onLink;
  final Future<void> Function(SocialProvider provider) onUnlink;

  /// 관리 가능한 소셜 provider(카카오·Google·Apple).
  static const List<SocialProvider> manageable = <SocialProvider>[
    SocialProvider.google,
    SocialProvider.kakao,
    SocialProvider.apple,
  ];

  @override
  State<LinkedAccountsSection> createState() => _LinkedAccountsSectionState();
}

class _LinkedAccountsSectionState extends State<LinkedAccountsSection> {
  SocialProvider? _busy;
  String? _error;

  bool _isLinked(SocialProvider p) =>
      widget.linkedProviders.contains(p.wireName);

  /// 마지막 남은 identity 면 해제 불가(계정 잠금 방지).
  bool get _canUnlinkAny => widget.linkedProviders.length > 1;

  /// 해제는 확인 시트를 거친 뒤에만 실제로 진행한다(실수 방지).
  Future<void> _confirmAndUnlink(SocialProvider provider) async {
    if (_busy != null) return;
    final bool ok = await confirmUnlinkAccount(context, _brand(provider));
    if (!ok || !mounted) return;
    await _run(provider, widget.onUnlink);
  }

  Future<void> _run(
    SocialProvider provider,
    Future<void> Function(SocialProvider) action,
  ) async {
    if (_busy != null) return;
    setState(() {
      _busy = provider;
      _error = null;
    });
    try {
      await action(provider);
    } on SocialSignInCancelled {
      // 사용자 취소 — 무시.
    } catch (_) {
      if (mounted) {
        setState(() => _error = '계정 연동 처리에 실패했어요. 잠시 후 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '연동 계정',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: t.fgStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '로그인에 사용할 소셜 계정을 연결하거나 해제할 수 있어요.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              color: t.fgMuted,
            ),
          ),
          const SizedBox(height: 14),
          for (final SocialProvider p in LinkedAccountsSection.manageable) ...[
            _providerRow(t, p),
            if (p != LinkedAccountsSection.manageable.last)
              const SizedBox(height: 10),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12.5,
                color: t.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _providerRow(DkTokens t, SocialProvider p) {
    final bool linked = _isLinked(p);
    final bool busy = _busy == p;
    final String label = _brand(p);

    final Widget action;
    if (busy) {
      action = _statusChip(t, '처리 중…');
    } else if (linked) {
      action = _canUnlinkAny
          ? DkButton(
              size: DkButtonSize.sm,
              variant: DkButtonVariant.outline,
              onPressed: () => _confirmAndUnlink(p),
              child: const Text('연결 해제'),
            )
          : _statusChip(t, '연결됨');
    } else {
      action = DkButton(
        size: DkButtonSize.sm,
        variant: DkButtonVariant.subtle,
        onPressed: () => _run(p, widget.onLink),
        child: const Text('연결'),
      );
    }

    return _row(
      t,
      label: label,
      mark: DkBrandMark(brand: p.wireName, size: 36),
      trailing: action,
    );
  }

  Widget _row(
    DkTokens t, {
    required String label,
    required Widget mark,
    required Widget trailing,
  }) {
    return Row(
      children: <Widget>[
        mark,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: t.fg,
            ),
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _statusChip(DkTokens t, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.bgSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: t.fgMuted,
        ),
      ),
    );
  }

  /// provider → 표시명.
  String _brand(SocialProvider p) => switch (p) {
    SocialProvider.google => 'Google',
    SocialProvider.kakao => '카카오',
    SocialProvider.apple => 'Apple',
  };
}
