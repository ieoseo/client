import 'package:flutter/foundation.dart';

import 'api/api_exception.dart';
import 'api/notif_api.dart';
import 'api/notif_dto.dart';

/// 인앱 알림 상태 컨트롤러(이슈 #46).
///
/// [NotifSource] 위에 목록·안읽음 카운트·로딩/오류 상태를 얹는다. 벨 점은 [unreadCount]>0
/// 으로 표시하고, 시트 열람/항목 탭 시 [markRead]/[markAllRead] 로 읽음 처리한다. 읽음 처리는
/// 낙관적으로 로컬을 먼저 갱신하고 실패 시 스냅샷으로 롤백한다. OS 푸시는 범위 외(후속).
class NotifController extends ChangeNotifier {
  NotifController(this._source);

  final NotifSource _source;

  List<DkNotif> _items = const <DkNotif>[];
  int _unreadCount = 0;
  bool _loading = false;
  String? _error;

  List<DkNotif> get items => _items;
  int get unreadCount => _unreadCount;
  bool get isLoading => _loading;
  String? get error => _error;

  /// 목록 + unreadCount 를 로드한다. 실패 시 [error] 를 채우고 목록을 비운다.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final NotifListResult result = await _source.list();
      _items = result.items;
      _unreadCount = result.unreadCount;
    } on ApiException catch (e) {
      _error = e.message;
      _items = const <DkNotif>[];
      _unreadCount = 0;
    } catch (_) {
      _error = '알림을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
      _items = const <DkNotif>[];
      _unreadCount = 0;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 단건 읽음 처리. 이미 읽었으면 아무 일도 하지 않는다. 실패 시 롤백.
  Future<void> markRead(String id) async {
    final int index = _items.indexWhere((DkNotif n) => n.id == id);
    if (index < 0 || _items[index].read) return;

    final List<DkNotif> snapshot = _items;
    final int unreadSnapshot = _unreadCount;
    _items = <DkNotif>[
      for (final DkNotif n in _items) n.id == id ? n.copyWith(read: true) : n,
    ];
    _unreadCount = (_unreadCount - 1).clamp(0, _items.length);
    notifyListeners();

    try {
      await _source.markRead(id);
    } on ApiException {
      _items = snapshot;
      _unreadCount = unreadSnapshot;
      notifyListeners();
      rethrow;
    }
  }

  /// 전체 읽음 처리. 실패 시 롤백.
  Future<void> markAllRead() async {
    if (_unreadCount == 0) return;

    final List<DkNotif> snapshot = _items;
    final int unreadSnapshot = _unreadCount;
    _items = <DkNotif>[for (final DkNotif n in _items) n.copyWith(read: true)];
    _unreadCount = 0;
    notifyListeners();

    try {
      await _source.markAllRead();
    } on ApiException {
      _items = snapshot;
      _unreadCount = unreadSnapshot;
      notifyListeners();
      rethrow;
    }
  }
}
