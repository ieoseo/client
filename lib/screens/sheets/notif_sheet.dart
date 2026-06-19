import 'package:flutter/widgets.dart';

import '../../data/api/notif_dto.dart';
import '../../data/notif_controller.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_badge.dart';
import '../../widgets/dk_empty.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_sheet.dart';

/// 알림 종류별 아이콘·톤 매핑(표현은 client 권한). server 는 [DkNotifType] 만 내려준다.
({String icon, DkTone tone}) _appearance(DkNotifType type) => switch (type) {
  DkNotifType.dday => (icon: 'target', tone: DkTone.primary),
  DkNotifType.debtCreated => (icon: 'carryForward', tone: DkTone.warning),
  DkNotifType.debtWarning => (icon: 'flame', tone: DkTone.danger),
  DkNotifType.streak => (icon: 'trophy', tone: DkTone.success),
};

/// 알림 목록(server 실데이터, 이슈 #46). 프로토타입 `NotifSheet`.
///
/// 안 읽은 항목은 점으로 강조하고, 항목 탭 시 [onTapItem] 으로 읽음 처리를 위임한다.
/// 항목이 없으면 빈 상태를 보인다. 시각은 `createdAt`(ISO) 을 상대 표기로 환산한다.
class NotifSheetBody extends StatelessWidget {
  const NotifSheetBody({
    super.key,
    required this.items,
    required this.onTapItem,
  });

  final List<DkNotif> items;
  final ValueChanged<DkNotif> onTapItem;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    if (items.isEmpty) {
      return const DkEmpty(
        icon: 'bell',
        title: '새 알림이 없어요',
        body: '마감·미룬 시간·스트릭 소식이 생기면 여기에서 알려드릴게요.',
      );
    }
    return Column(
      children: <Widget>[
        for (int i = 0; i < items.length; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTapItem(items[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: BoxDecoration(
                border: i < items.length - 1
                    ? Border(bottom: BorderSide(color: t.borderSubtle))
                    : null,
              ),
              child: _row(t, items[i]),
            ),
          ),
      ],
    );
  }

  Widget _row(DkTokens t, DkNotif it) {
    final ({String icon, DkTone tone}) ap = _appearance(it.type);
    final ({Color bg, Color fg}) colors = dkToneColors(t, ap.tone);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DkIcon(ap.icon, size: 19, color: colors.fg, strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                it.body,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: it.read ? FontWeight.w500 : FontWeight.w600,
                  color: it.read ? t.fgSubtle : t.fg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _relativeTime(it.createdAt),
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  color: t.fgSubtle,
                ),
              ),
            ],
          ),
        ),
        if (!it.read) ...<Widget>[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: t.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// `createdAt`(ISO-8601) 을 간단한 상대 표기로 환산한다. 파싱 실패 시 빈 문자열.
String _relativeTime(String createdAt) {
  final DateTime? at = DateTime.tryParse(createdAt);
  if (at == null) return '';
  final Duration d = DateTime.now().toUtc().difference(at.toUtc());
  if (d.inMinutes < 1) return '방금';
  if (d.inMinutes < 60) return '${d.inMinutes}분 전';
  if (d.inHours < 24) return '${d.inHours}시간 전';
  if (d.inDays < 7) return '${d.inDays}일 전';
  final DateTime local = at.toLocal();
  return '${local.month}월 ${local.day}일';
}

/// 알림 시트를 띄운다. [controller] 의 항목을 렌더하고, 항목 탭 시 읽음 처리를 위임한다.
Future<void> showNotifSheet(
  BuildContext context,
  NotifController controller, {
  ValueChanged<DkNotif>? onTapItem,
}) {
  return showDkSheet<void>(
    context,
    title: '알림',
    child: ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) => NotifSheetBody(
        items: controller.items,
        onTapItem: onTapItem ?? (DkNotif n) => controller.markRead(n.id),
      ),
    ),
  );
}
