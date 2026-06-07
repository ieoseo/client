import 'package:flutter/foundation.dart';

/// 인앱 알림 종류. server `NotificationType`(`DDAY`/`DEBT_CREATED`/`DEBT_WARNING`/`STREAK`).
///
/// 아이콘·톤 등 표현 매핑은 client 가 이 값으로 결정한다(계약: docs/05-API/notifications.md).
enum DkNotifType { dday, debtCreated, debtWarning, streak }

/// server type 문자열 → [DkNotifType]. 알 수 없는 값은 보수적으로 [DkNotifType.dday].
DkNotifType notifTypeFromString(String s) => switch (s) {
  'DDAY' => DkNotifType.dday,
  'DEBT_CREATED' => DkNotifType.debtCreated,
  'DEBT_WARNING' => DkNotifType.debtWarning,
  'STREAK' => DkNotifType.streak,
  _ => DkNotifType.dday,
};

/// 인앱 알림 한 건(불변). server `NotificationResponse` 에 대응한다.
///
/// 파생 표현(아이콘/톤)은 화면에서 [type] 으로 매핑한다. [refId] 는 대상 리소스(선택).
@immutable
class DkNotif {
  const DkNotif({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.refId,
  });

  final String id;
  final DkNotifType type;
  final String title;
  final String body;
  final bool read;

  /// 생성 시각(ISO-8601 UTC 문자열, 예: `2026-06-04T09:00:00Z`).
  final String createdAt;

  /// 알림이 가리키는 도메인 리소스(이벤트/태스크 등) id(선택).
  final String? refId;

  DkNotif copyWith({bool? read}) => DkNotif(
    id: id,
    type: type,
    title: title,
    body: body,
    read: read ?? this.read,
    createdAt: createdAt,
    refId: refId,
  );
}

/// 문자열 필드를 안전하게 꺼낸다(null/비문자열 → null).
String? _str(Object? v) => v is String ? v : null;

/// 서버 응답 `data` ↔ [DkNotif] 매핑(이슈 #46).
abstract final class DkNotifDto {
  /// 서버 NotificationResponse `data` → [DkNotif]. 모르는 필드는 무시한다.
  static DkNotif fromJson(Map<String, dynamic> json) => DkNotif(
    id: _str(json['id']) ?? '',
    type: notifTypeFromString(_str(json['type']) ?? 'DDAY'),
    title: _str(json['title']) ?? '',
    body: _str(json['body']) ?? '',
    read: json['read'] == true,
    createdAt: _str(json['createdAt']) ?? '',
    refId: _str(json['refId']),
  );
}
