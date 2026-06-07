import 'package:flutter/widgets.dart';

import '../../data/format.dart';
import '../../data/meta.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_badge.dart';
import '../../widgets/dk_button.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_section.dart';

/// 캘린더 연동 설정 서브화면(나>설정>캘린더 연동, 이슈 #59 / FRD 4.12).
///
/// 노출 provider([kVisibleCalendarProviders], MVP=Google만)별 연결 상태·마지막 동기화를
/// 보여주고, 연결/수동 동기화/연결 해제를 제공한다. 미연결이면 안내 문구를 띄운다. 동기화/연결/
/// 해제 실제 수행은 상위 컨트롤러 콜백에 위임한다(낙관 갱신·토스트는 상위 책임). Apple·Notion 은
/// 연동 코드는 유지하되 화면에서만 숨긴다(이슈 #67).
class CalendarSyncScreen extends StatelessWidget {
  const CalendarSyncScreen({
    super.key,
    required this.connections,
    required this.syncing,
    required this.onBack,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSync,
  });

  /// provider 별 연결 상태(미연결 provider 는 [DkConnectionStatus.none]).
  final List<DkCalendarConnection> connections;

  /// 동기화 진행 중 여부(버튼 비활성·라벨용).
  final bool syncing;

  final VoidCallback onBack;

  /// provider 연결(토큰 등록). 상위가 소셜 토큰 재사용/수동 입력을 처리한다.
  final ValueChanged<DkSource> onConnect;

  /// provider 연결 해제.
  final ValueChanged<DkSource> onDisconnect;

  /// 전체 수동 동기화.
  final VoidCallback onSync;

  DkCalendarConnection _forSource(DkSource s) => connections.firstWhere(
    (DkCalendarConnection c) => c.source == s,
    orElse: () => DkCalendarConnection.disconnected(s),
  );

  bool get _anyConnected =>
      connections.any((DkCalendarConnection c) => c.isConnected);

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        _header(t),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!_anyConnected) _emptyHint(t),
              if (!_anyConnected) const SizedBox(height: 18),
              const DkSectionHead(title: '캘린더 제공자'),
              const SizedBox(height: 8),
              for (
                int i = 0;
                i < kVisibleCalendarProviders.length;
                i++
              ) ...<Widget>[
                if (i > 0) const SizedBox(height: 8),
                _providerCard(t, _forSource(kVisibleCalendarProviders[i])),
              ],
              const SizedBox(height: 18),
              DkButton(
                variant: DkButtonVariant.outline,
                full: true,
                disabled: !_anyConnected || syncing,
                onPressed: _anyConnected && !syncing ? onSync : null,
                leading: DkIcon('repeat', size: 18, color: t.fg),
                child: Text(syncing ? '동기화 중…' : '지금 동기화'),
              ),
              const SizedBox(height: 16),
              Text(
                '외부 일정은 읽기 전용으로 표시돼요. 토큰이 만료되면 다시 연결해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12.5,
                  height: 1.6,
                  color: t.fgSubtle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyHint(DkTokens t) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: t.primarySubtle,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: <Widget>[
        DkIcon('calendar', size: 20, color: t.primary, strokeWidth: 2),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '연결된 캘린더가 없어요. 제공자를 연결하면 외부 일정을 한 화면에서 볼 수 있어요.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: t.primary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _providerCard(DkTokens t, DkCalendarConnection conn) {
    final DkSourceMeta meta = sourceMeta(conn.source);
    final bool connected = conn.isConnected;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderSubtle),
        boxShadow: t.shadows.s1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: meta.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      meta.label,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(conn),
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12.5,
                        color: t.fgSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              DkBadge(_statusLabel(conn.status), tone: _tone(conn.status)),
            ],
          ),
          const SizedBox(height: 12),
          if (connected)
            DkButton(
              variant: DkButtonVariant.ghost,
              size: DkButtonSize.sm,
              full: true,
              onPressed: () => onDisconnect(conn.source),
              child: const Text('연결 해제'),
            )
          else
            DkButton(
              variant: DkButtonVariant.subtle,
              size: DkButtonSize.sm,
              full: true,
              onPressed: () => onConnect(conn.source),
              child: const Text('연결하기'),
            ),
        ],
      ),
    );
  }

  String _subtitle(DkCalendarConnection conn) {
    if (!conn.isConnected) return '연결되지 않음';
    final String? at = conn.lastSyncedAt;
    if (at == null) return '아직 동기화 안 함';
    return '마지막 동기화 ${_syncedLabel(at)}';
  }

  /// ISO-8601 Instant → 'YYYY. MM. DD' 표시(시각 생략). 파싱 실패 시 원문.
  String _syncedLabel(String iso) {
    final DateTime? dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return fmtDate(ymd(dt.toLocal()));
  }

  String _statusLabel(DkConnectionStatus s) => switch (s) {
    DkConnectionStatus.connected => '연결됨',
    DkConnectionStatus.syncFailed => '동기화 실패',
    DkConnectionStatus.none => '미연결',
  };

  DkTone _tone(DkConnectionStatus s) => switch (s) {
    DkConnectionStatus.connected => DkTone.success,
    DkConnectionStatus.syncFailed => DkTone.danger,
    DkConnectionStatus.none => DkTone.neutral,
  };

  Widget _header(DkTokens t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 58, 16, 8),
    child: Row(
      children: <Widget>[
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.bgPress,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DkIcon('chevL', size: 22, color: t.fg),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '캘린더 연동',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.66,
            color: t.fgStrong,
          ),
        ),
      ],
    ),
  );
}
