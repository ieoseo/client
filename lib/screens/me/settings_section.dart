import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/api/settings_dto.dart';
import '../../data/meta.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_badge.dart';
import '../../widgets/dk_icon.dart';
import 'settings_dialogs.dart';

/// 토글 스위치. 프로토타입 `Toggle`: 48×28 pill(on=primary), 노브 24 흰색.
class DkToggle extends StatelessWidget {
  const DkToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? t.primary : t.borderStrong,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            shape: BoxShape.circle,
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 설정 그룹(제목 + 흰 카드). 프로토타입 `SettingGroup`.
class SettingGroup extends StatelessWidget {
  const SettingGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              title!,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.38,
                color: t.fgSubtle,
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: t.borderSubtle),
              boxShadow: t.shadows.s1,
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

/// 설정 행. 프로토타입 `SettingRow`: 아이콘 칩 32 + 라벨 + value/right + chevR.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    this.icon,
    this.iconBg,
    this.iconColor,
    required this.label,
    this.value,
    this.valueColor,
    this.right,
    this.onTap,
    this.last = false,
    this.danger = false,
    this.comingSoon = false,
  });

  final String? icon;
  final Color? iconBg;
  final Color? iconColor;
  final String label;
  final String? value;

  /// [value] 텍스트 색(예: 일요일 빨강). null이면 기본 뮤트색.
  final Color? valueColor;
  final Widget? right;
  final VoidCallback? onTap;
  final bool last;
  final bool danger;

  /// 준비 중(미구현) 행이면 아이콘·라벨을 뮤트색으로 칠하고 '준비 중' 뱃지를 붙인다.
  /// 여전히 탭 가능하며, 탭 안내는 [onTap](공통 준비 중 토스트)이 처리한다.
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final Color labelColor = danger
        ? t.danger
        : comingSoon
        ? t.fgSubtle
        : t.fg;
    final Color resolvedIconColor = comingSoon
        ? t.fgDisabled
        : (iconColor ?? t.fgMuted);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: t.borderSubtle)),
        ),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: comingSoon ? t.bgSubtle : (iconBg ?? t.bgPress),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DkIcon(
                  icon!,
                  size: 18,
                  color: resolvedIconColor,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 13),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            if (comingSoon)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: DkBadge(kComingSoonBadgeLabel),
              ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  value!,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? t.fgSubtle,
                  ),
                ),
              ),
            if (right != null)
              Padding(padding: const EdgeInsets.only(left: 8), child: right!),
            if (onTap != null && right == null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: DkIcon('chevR', size: 18, color: t.fgDisabled),
              ),
          ],
        ),
      ),
    );
  }
}

/// 임베디드 설정 섹션(나 탭 하단). 프로토타입 `SettingsScreen`(embedded).
///
/// 미룬 시간·포모도로·완료음·주간 시작은 서버 설정([DkSettings], 이슈 #56)을 표시하고,
/// 변경 시 [onSaveSettings] 로 낙관적 저장한다. 다크 모드는 로컬 테마([dark]/[onToggleDark]).
/// 회원 탈퇴는 2단계 확인 후 [onWithdraw].
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.dark,
    required this.onToggleDark,
    required this.settings,
    required this.onSaveSettings,
    required this.onOpenCalendar,
    required this.onStub,
    required this.onLogout,
    required this.onWithdraw,
  });

  final bool dark;
  final ValueChanged<bool> onToggleDark;

  /// 현재 사용자 설정(서버 연동). 토글/값 표시의 단일 출처.
  final DkSettings settings;

  /// 설정 변경 저장(낙관적 PUT). 다음 설정 스냅샷을 받는다.
  final ValueChanged<DkSettings> onSaveSettings;

  /// 캘린더 연동 화면 열기(이슈 #59).
  final VoidCallback onOpenCalendar;

  /// 미구현 행 탭 시(알림 설정 등) 호출.
  final VoidCallback onStub;

  /// 로그아웃 행 탭 시 호출(토큰 삭제 + 인증 화면 복귀).
  final VoidCallback onLogout;

  /// 회원 탈퇴 확정 시 호출(2단계 확인 통과 후).
  final Future<void> Function() onWithdraw;

  String _deadlineLabel(int hour) =>
      hour == 0 ? '자정 (00:00)' : '${hour.toString().padLeft(2, '0')}:00';

  String _maxLabel(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (m == 0) return '$h시간';
    return '$h시간 $m분';
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final DkSettings s = settings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SettingGroup(
            title: '미룬 시간',
            children: <Widget>[
              SettingRow(
                icon: 'clock',
                label: '하루 마감 시각',
                value: _deadlineLabel(s.dayDeadlineHour),
                onTap: () async {
                  final int? hour = await showDeadlineHourPicker(
                    context,
                    current: s.dayDeadlineHour,
                  );
                  if (hour != null && hour != s.dayDeadlineHour) {
                    onSaveSettings(s.copyWith(dayDeadlineHour: hour));
                  }
                },
              ),
              SettingRow(
                icon: 'repeat',
                label: '자동 옮기기',
                right: DkToggle(
                  value: s.autoCarry,
                  onChanged: (bool v) =>
                      onSaveSettings(s.copyWith(autoCarry: v)),
                ),
              ),
              SettingRow(
                icon: 'calendar',
                label: '주간 시작 요일',
                // 드롭다운(탭→선택 피커). 기본 월요일, 일요일은 빨간색 강조.
                value: s.weekStart == 'SUN' ? '일요일' : '월요일',
                valueColor: s.weekStart == 'SUN' ? t.danger : null,
                onTap: () async {
                  final String? v = await showWeekStartPicker(
                    context,
                    current: s.weekStart,
                  );
                  if (v != null && v != s.weekStart) {
                    onSaveSettings(s.copyWith(weekStart: v));
                  }
                },
              ),
              SettingRow(
                icon: 'carryForward',
                iconBg: t.warningSubtle,
                iconColor: t.warningFg,
                label: '하루 최대 예약 시간',
                value: _maxLabel(s.maxDailyMinutes),
                last: true,
                onTap: () async {
                  final int? minutes = await showMaxMinutesPicker(
                    context,
                    current: s.maxDailyMinutes,
                  );
                  if (minutes != null && minutes != s.maxDailyMinutes) {
                    onSaveSettings(s.copyWith(maxDailyMinutes: minutes));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingGroup(
            title: '연동 · 알림',
            children: <Widget>[
              SettingRow(
                icon: 'calendar',
                label: '캘린더 연동',
                onTap: onOpenCalendar,
              ),
              SettingRow(
                icon: 'bell',
                label: '알림 설정',
                comingSoon: true,
                onTap: onStub,
              ),
              SettingRow(
                icon: dark ? 'moon' : 'sun',
                label: '다크 모드',
                last: true,
                right: DkToggle(value: dark, onChanged: onToggleDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingGroup(
            children: <Widget>[
              SettingRow(icon: 'logout', label: '로그아웃', onTap: onLogout),
              SettingRow(
                icon: 'trash',
                iconColor: t.danger,
                label: '회원 탈퇴',
                danger: true,
                last: true,
                onTap: () => confirmWithdraw(context, onWithdraw),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Center(child: _AppVersionLabel()),
        ],
      ),
    );
  }
}

/// 앱 버전 라벨(`이어서 v{version}`). 버전은 빌드 메타([PackageInfo])에서 읽는다.
/// 아직 로드되지 않았거나 조회 실패 시 "이어서"만 표기한다(하드코딩 버전 없음).
class _AppVersionLabel extends StatefulWidget {
  const _AppVersionLabel();

  @override
  State<_AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<_AppVersionLabel> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = info.version);
    } catch (_) {
      // 플랫폼 채널이 없는 환경(테스트 등)에서는 버전 없이 표기.
    }
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final String label = _version == null ? '이어서' : '이어서 v$_version';
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: t.fgDisabled,
      ),
    );
  }
}
