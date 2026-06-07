import 'api_client.dart';
import 'notif_dto.dart';

/// 알림 목록 결과: 항목 + 안읽음 카운트(벨 점 표시용).
class NotifListResult {
  const NotifListResult({required this.items, required this.unreadCount});

  final List<DkNotif> items;
  final int unreadCount;
}

/// 알림 데이터 소스 추상화(컨트롤러가 의존). 구현은 [NotifApi](server 연동) /
/// 테스트의 가짜 소스. 도메인 권위(생성 규칙)는 server.
abstract class NotifSource {
  /// 목록 + unreadCount(server: GET /notifications).
  Future<NotifListResult> list();

  /// 단건 읽음 처리(server: PATCH /notifications/{id}/read). 갱신된 알림 반환.
  Future<DkNotif> markRead(String id);

  /// 전체 읽음 처리(server: POST /notifications/read-all). 갱신 건수 반환.
  Future<int> markAllRead();
}

/// server 알림 REST 를 호출하는 [NotifSource] 구현(이슈 #46).
///
/// 인증 헤더·envelope 언랩·401 refresh 는 [ApiClient] 가 담당하며, 오류는 ApiException.
/// OS 푸시(FCM/APNs)는 범위 외(후속) — 본 클라이언트는 인앱 알림 조회/읽음만 다룬다.
class NotifApi implements NotifSource {
  NotifApi(this._client);

  final ApiClient _client;

  Map<String, dynamic> _asMap(dynamic data) =>
      data is Map<String, dynamic> ? data : const <String, dynamic>{};

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<NotifListResult> list() async {
    final Map<String, dynamic> data = _asMap(
      await _client.get('/notifications'),
    );
    final List<DkNotif> items = _asList(
      data['items'],
    ).map(DkNotifDto.fromJson).toList(growable: false);
    final int unread = (data['unreadCount'] as num?)?.toInt() ?? 0;
    return NotifListResult(items: items, unreadCount: unread);
  }

  @override
  Future<DkNotif> markRead(String id) async {
    final dynamic data = await _client.patch('/notifications/$id/read');
    return DkNotifDto.fromJson(_asMap(data));
  }

  @override
  Future<int> markAllRead() async {
    final Map<String, dynamic> data = _asMap(
      await _client.post('/notifications/read-all'),
    );
    return (data['updated'] as num?)?.toInt() ?? 0;
  }
}
