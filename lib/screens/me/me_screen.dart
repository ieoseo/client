import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../data/api/auth_dto.dart';
import '../../data/api/settings_dto.dart';
import '../../data/auth/social_auth.dart';
import '../../data/models.dart';
import '../../parts/app_header.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_button.dart';
import '../../widgets/dk_feedback.dart';
import '../../widgets/dk_icon.dart';
import 'linked_accounts_section.dart';
import 'settings_dialogs.dart';
import 'settings_section.dart';

/// 나 탭. 프로토타입 `MeScreen`.
///
/// 프로필 + 통계 타일 3 + 이번 주 돌아보기(ink) + 임베디드 설정.
class MeScreen extends StatelessWidget {
  const MeScreen({
    super.key,
    required this.user,
    required this.summary,
    required this.streak,
    required this.focusStats,
    required this.settings,
    required this.dark,
    required this.onToggleDark,
    required this.onBell,
    required this.onOpenCalc,
    required this.onOpenReview,
    required this.onOpenCalendar,
    required this.onStub,
    required this.onLogout,
    required this.onUpdateProfile,
    required this.onSaveSettings,
    required this.onWithdraw,
    this.unread = 0,
    this.linkedProviders = const <String>{},
    this.onLinkAccount,
    this.onUnlinkAccount,
  });

  /// 현재 인증 사용자(프로필 표시·수정 대상, 이슈 #56).
  final AuthUser user;
  final DkWeekSummary summary;
  final int streak;
  final DkFocusStats focusStats;

  /// 현재 사용자 설정(서버 연동, 이슈 #56).
  final DkSettings settings;
  final bool dark;

  /// 안 읽은 알림 수(헤더 벨 점 표시용, 이슈 #46).
  final int unread;
  final ValueChanged<bool> onToggleDark;
  final VoidCallback onBell;
  final VoidCallback onOpenCalc;
  final VoidCallback onOpenReview;

  /// 캘린더 연동 화면 열기(나>설정>캘린더 연동, 이슈 #59).
  final VoidCallback onOpenCalendar;
  final VoidCallback onStub;

  /// 로그아웃 콜백(토큰 삭제 + 인증 화면 복귀).
  final VoidCallback onLogout;

  /// 프로필(닉네임) 저장 콜백(서버 PATCH). 실패는 호출부에서 토스트 처리.
  final Future<void> Function(String nickname) onUpdateProfile;

  /// 설정 저장 콜백(낙관적 PUT). 다음 설정 스냅샷을 받는다.
  final ValueChanged<DkSettings> onSaveSettings;

  /// 회원 탈퇴 확정 콜백(2단계 확인 통과 후 DELETE → 로그아웃).
  final Future<void> Function() onWithdraw;

  /// 현재 연동된 provider 이름 집합(예: {'email','google','kakao'}, 이슈 #10).
  final Set<String> linkedProviders;

  /// 소셜 계정 연결 콜백(linkIdentity). null 이면 연동 섹션을 숨긴다.
  final Future<void> Function(SocialProvider provider)? onLinkAccount;

  /// 소셜 계정 연결 해제 콜백(unlinkIdentity).
  final Future<void> Function(SocialProvider provider)? onUnlinkAccount;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final int pct = summary.planned == 0
        ? 0
        : (summary.done / summary.planned * 100).round();

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        AppHeader(
          title: '프로필',
          subtitle: '기록과 설정',
          unread: unread,
          onBell: onBell,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _profile(context, t),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  _statTile(
                    t,
                    icon: 'flame',
                    iconBg: t.warningSubtle,
                    iconColor: t.warningFg,
                    fill: true,
                    value: streak.toDouble(),
                    suffix: '일',
                    label: '연속 달성',
                  ),
                  const SizedBox(width: 10),
                  _statTile(
                    t,
                    icon: 'chart',
                    iconBg: t.successSubtle,
                    iconColor: t.successFg,
                    value: pct.toDouble(),
                    suffix: '%',
                    label: '주간 실행률',
                  ),
                  const SizedBox(width: 10),
                  _statTile(
                    t,
                    icon: 'focus',
                    iconBg: t.primarySubtle,
                    iconColor: t.primary,
                    value: focusStats.todaySessions.toDouble(),
                    suffix: '회',
                    label: '오늘 집중',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _reviewEntry(t),
              const SizedBox(height: 16),
              // 구독 일정 관리: 정기결제 구독 일정을 모아 보는 향후 기능의 진입점.
              // 아직 화면/데이터가 없어 탭 시 통합 준비 중 안내 토스트만 띄운다.
              SettingGroup(
                children: <Widget>[
                  SettingRow(
                    icon: 'repeat',
                    label: '구독 일정 관리',
                    last: true,
                    comingSoon: true,
                    onTap: onStub,
                  ),
                ],
              ),
              if (onLinkAccount != null && onUnlinkAccount != null) ...<Widget>[
                const SizedBox(height: 16),
                LinkedAccountsSection(
                  linkedProviders: linkedProviders,
                  onLink: onLinkAccount!,
                  onUnlink: onUnlinkAccount!,
                ),
              ],
            ],
          ),
        ),
        SettingsSection(
          dark: dark,
          onToggleDark: onToggleDark,
          settings: settings,
          onSaveSettings: onSaveSettings,
          onOpenCalc: onOpenCalc,
          onOpenCalendar: onOpenCalendar,
          onStub: onStub,
          onLogout: onLogout,
          onWithdraw: onWithdraw,
        ),
        // 프로필 탭은 FAB 가 없어 큰 하단 여백이 필요 없다(탭바와의 빈 공간 축소).
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _profile(BuildContext context, DkTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Row(
        children: <Widget>[
          // 아바타: 중립 인물 placeholder(배경사진 설정의 향후 진입점). '준비 중' 배지는
          // 빼고, 탭하면 통합 준비 중 안내 토스트([onStub])만 띄운다.
          GestureDetector(
            key: const ValueKey<String>('profile-avatar'),
            behavior: HitTestBehavior.opaque,
            onTap: onStub,
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: t.primary.withValues(alpha: 0.38),
                    offset: const Offset(0, 6),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const DkIcon(
                'user',
                size: 30,
                color: Color(0xFFFFFFFF),
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.nickname,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: t.fgStrong,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  user.email ?? '이메일 미등록',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    color: t.fgSubtle,
                  ),
                ),
              ],
            ),
          ),
          DkButton(
            size: DkButtonSize.sm,
            variant: DkButtonVariant.outline,
            onPressed: () => showProfileEditSheet(
              context,
              initialNickname: user.nickname,
              onSubmit: onUpdateProfile,
            ),
            child: const Text('프로필 수정'),
          ),
        ],
      ),
    );
  }

  Widget _statTile(
    DkTokens t, {
    required String icon,
    required Color iconBg,
    required Color iconColor,
    required double value,
    required String suffix,
    required String label,
    bool fill = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.borderSubtle),
          boxShadow: t.shadows.s1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: DkIcon(
                icon,
                size: 19,
                color: iconColor,
                strokeWidth: 1.95,
                fill: fill ? iconColor : null,
              ),
            ),
            const SizedBox(height: 8),
            DkCountUp(
              value: value,
              suffix: suffix,
              style: TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.66,
                color: t.fgStrong,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: t.fgSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewEntry(DkTokens t) {
    return GestureDetector(
      onTap: onOpenReview,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.radius),
        child: Container(
          decoration: BoxDecoration(
            color: t.ink,
            borderRadius: BorderRadius.circular(t.radius),
            boxShadow: t.shadows.s2,
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -40,
                right: -20,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: t.primary.withValues(alpha: 0.24),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x24FFFFFF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const DkIcon(
                        'chart',
                        size: 22,
                        color: Color(0xFFFFFFFF),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '이번 주 돌아보기',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.31,
                              color: t.onInk,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '완료율·요일별 실행·카테고리 분포를 한눈에',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: t.onInkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DkIcon('chevR', size: 20, color: t.onInkMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
