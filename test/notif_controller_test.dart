import 'package:ieoseo/data/api/api_exception.dart';
import 'package:ieoseo/data/api/notif_api.dart';
import 'package:ieoseo/data/api/notif_dto.dart';
import 'package:ieoseo/data/notif_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// 인메모리 가짜 알림 소스(컨트롤러 단위 테스트용).
class _FakeNotifSource implements NotifSource {
  _FakeNotifSource(this._items);

  List<DkNotif> _items;
  bool throwOnList = false;
  int markAllCalls = 0;

  @override
  Future<NotifListResult> list() async {
    if (throwOnList) throw ApiException.network();
    final int unread = _items.where((DkNotif n) => !n.read).length;
    return NotifListResult(items: _items, unreadCount: unread);
  }

  @override
  Future<DkNotif> markRead(String id) async {
    final DkNotif read = _items
        .firstWhere((DkNotif n) => n.id == id)
        .copyWith(read: true);
    _items = _items.map((DkNotif n) => n.id == id ? read : n).toList();
    return read;
  }

  @override
  Future<int> markAllRead() async {
    markAllCalls++;
    final int unread = _items.where((DkNotif n) => !n.read).length;
    _items = _items.map((DkNotif n) => n.copyWith(read: true)).toList();
    return unread;
  }
}

DkNotif _notif(
  String id, {
  bool read = false,
  DkNotifType type = DkNotifType.dday,
}) => DkNotif(
  id: id,
  type: type,
  title: '토익 시험',
  body: '토익 시험이 3일 남았어요',
  read: read,
  createdAt: '2026-06-04T09:00:00Z',
);

void main() {
  test('load 는 목록과 unreadCount 를 채운다', () async {
    final NotifController c = NotifController(
      _FakeNotifSource(<DkNotif>[_notif('n-1'), _notif('n-2', read: true)]),
    );

    await c.load();

    expect(c.items, hasLength(2));
    expect(c.unreadCount, 1);
    expect(c.error, isNull);
  });

  test('load 실패 시 error 를 노출하고 목록은 비운다', () async {
    final _FakeNotifSource src = _FakeNotifSource(<DkNotif>[_notif('n-1')]);
    src.throwOnList = true;
    final NotifController c = NotifController(src);

    await c.load();

    expect(c.error, isNotNull);
    expect(c.items, isEmpty);
  });

  test('markRead 는 해당 항목을 읽음으로 바꾸고 unreadCount 를 줄인다', () async {
    final NotifController c = NotifController(
      _FakeNotifSource(<DkNotif>[_notif('n-1'), _notif('n-2')]),
    );
    await c.load();
    expect(c.unreadCount, 2);

    await c.markRead('n-1');

    expect(c.items.firstWhere((DkNotif n) => n.id == 'n-1').read, isTrue);
    expect(c.unreadCount, 1);
  });

  test('이미 읽은 항목 markRead 는 unreadCount 를 더 줄이지 않는다', () async {
    final NotifController c = NotifController(
      _FakeNotifSource(<DkNotif>[_notif('n-1', read: true)]),
    );
    await c.load();
    expect(c.unreadCount, 0);

    await c.markRead('n-1');

    expect(c.unreadCount, 0);
  });

  test('markAllRead 는 모든 항목을 읽음으로 바꾸고 unreadCount 를 0 으로 만든다', () async {
    final _FakeNotifSource src = _FakeNotifSource(<DkNotif>[
      _notif('n-1'),
      _notif('n-2'),
    ]);
    final NotifController c = NotifController(src);
    await c.load();

    await c.markAllRead();

    expect(c.unreadCount, 0);
    expect(c.items.every((DkNotif n) => n.read), isTrue);
    expect(src.markAllCalls, 1);
  });
}
