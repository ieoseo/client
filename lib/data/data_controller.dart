import 'package:flutter/foundation.dart';

import 'api/api_exception.dart';
import 'models.dart';
import 'repository.dart';

/// events/tasks/debts 데이터를 화면에 공급하는 컨트롤러(이슈 #35).
///
/// [IeoseoRepository] 위에 로딩/오류 상태와 낙관적 쓰기(실패 시 롤백)를 얹는다.
/// 읽기는 [load] 로 한 번에 채우고, 쓰기는 로컬을 먼저 갱신한 뒤 서버 결과로
/// 확정하거나 실패 시 스냅샷으로 되돌린다. 오류는 [ApiException] 을 다시 던져
/// 화면이 토스트로 표시하게 한다(메시지는 사용자 친화 한국어).
class DataController extends ChangeNotifier {
  DataController(this._repo);

  final IeoseoRepository _repo;

  List<DkEvent> _events = const <DkEvent>[];
  List<DkTask> _tasks = const <DkTask>[];
  List<DkDebt> _debts = const <DkDebt>[];

  bool _loading = false;
  String? _error;

  List<DkEvent> get events => _events;
  List<DkTask> get tasks => _tasks;
  List<DkDebt> get debts => _debts;

  bool get isLoading => _loading;

  /// 마지막 로드 오류 메시지(없으면 null). 재시도는 [load] 재호출.
  String? get error => _error;

  /// 목 전용 동기 읽기 패스스루(서버 엔드포인트 없는 데이터).
  IeoseoRepository get repository => _repo;

  /// events/tasks/debts 를 병렬로 로드한다. 실패 시 [error] 를 채운다.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final List<dynamic> results = await Future.wait(<Future<dynamic>>[
        _repo.events(),
        _repo.tasks(),
        _repo.debts(),
      ]);
      _events = results[0] as List<DkEvent>;
      _tasks = results[1] as List<DkTask>;
      _debts = results[2] as List<DkDebt>;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e, stack) {
      // 원본 예외·스택을 삼키지 않고 남긴다(C4) — 사용자엔 친화 메시지만 노출.
      _error = '데이터를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
      debugPrint('DataController.load 실패: $e');
      debugPrint('$stack');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Tasks ───────────────────────────────────────────────

  /// 완료 토글. 낙관적으로 상태를 바꾸고, 실패 시 스냅샷으로 롤백 후 재던짐.
  Future<void> toggleComplete(DkTask task) async {
    final List<DkTask> snapshot = _tasks;
    final bool willBeDone = task.state != DkTaskState.done;
    _replaceTask(
      task.copyWith(state: willBeDone ? DkTaskState.done : DkTaskState.today),
    );
    try {
      final DkTask server = await _repo.toggleComplete(task);
      _replaceTask(server);
    } on Exception {
      _tasks = snapshot;
      notifyListeners();
      rethrow;
    }
  }

  /// 태스크 생성. 성공 시 목록 끝에 추가한다.
  Future<DkTask> createTask(DkTask draft) async {
    final DkTask created = await _repo.createTask(draft);
    _tasks = <DkTask>[..._tasks, created];
    notifyListeners();
    return created;
  }

  /// 태스크 수정.
  Future<DkTask> updateTask(DkTask task) async {
    final DkTask updated = await _repo.updateTask(task);
    _replaceTask(updated);
    return updated;
  }

  /// 태스크 삭제. 낙관적으로 제거 후 실패 시 롤백.
  Future<void> deleteTask(String id) async {
    final List<DkTask> snapshot = _tasks;
    _tasks = _tasks.where((DkTask t) => t.id != id).toList();
    notifyListeners();
    try {
      await _repo.deleteTask(id);
    } on Exception {
      _tasks = snapshot;
      notifyListeners();
      rethrow;
    }
  }

  /// 수동 이월(날짜 옮기기).
  Future<DkTask> carryTask(String id, {required String toDate}) async {
    final DkTask carried = await _repo.carryTask(id, toDate: toDate);
    _replaceTask(carried);
    return carried;
  }

  // ── Events ──────────────────────────────────────────────

  Future<DkEvent> createEvent(DkEvent draft) async {
    final DkEvent created = await _repo.createEvent(draft);
    _events = <DkEvent>[..._events, created];
    notifyListeners();
    return created;
  }

  Future<DkEvent> updateEvent(DkEvent event) async {
    final DkEvent updated = await _repo.updateEvent(event);
    _events = _events
        .map((DkEvent e) => e.id == updated.id ? updated : e)
        .toList();
    notifyListeners();
    return updated;
  }

  Future<void> deleteEvent(String id) async {
    final List<DkEvent> snapshot = _events;
    _events = _events.where((DkEvent e) => e.id != id).toList();
    notifyListeners();
    try {
      await _repo.deleteEvent(id);
    } on Exception {
      _events = snapshot;
      notifyListeners();
      rethrow;
    }
  }

  /// 이벤트 종료(완료) 처리. 자동 삭제 대신 유저 명시 액션(FRD 5.1).
  Future<DkEvent> completeEvent(String id) => _setEventCompleted(id, true);

  /// 종료 취소(재개).
  Future<DkEvent> reopenEvent(String id) => _setEventCompleted(id, false);

  Future<DkEvent> _setEventCompleted(String id, bool completed) async {
    final List<DkEvent> snapshot = _events;
    // 낙관적 업데이트 후 server 응답으로 교체, 실패 시 롤백.
    _events = _events
        .map((DkEvent e) => e.id == id ? e.copyWith(completed: completed) : e)
        .toList();
    notifyListeners();
    try {
      final DkEvent updated = completed
          ? await _repo.completeEvent(id)
          : await _repo.reopenEvent(id);
      _events = _events
          .map((DkEvent e) => e.id == updated.id ? updated : e)
          .toList();
      notifyListeners();
      return updated;
    } on Exception {
      _events = snapshot;
      notifyListeners();
      rethrow;
    }
  }

  // ── Debts ───────────────────────────────────────────────

  Future<DkDebt> carryDebt(String id, {required String toDate}) async {
    final DkDebt updated = await _repo.carryDebt(id, toDate: toDate);
    _replaceDebt(updated);
    return updated;
  }

  /// 자동 이월(가장 여유 있는 날로 server 가 배정). 낙관적으로 assigned 를 표시하고
  /// 응답으로 확정하되, 실패 시 스냅샷으로 롤백한다(F6 — 실패가 'assigned' 로 굳지 않게).
  Future<DkDebt> autoCarryDebt(String id) async {
    final List<DkDebt> snapshot = _debts;
    _debts = _debts
        .map(
          (DkDebt d) =>
              d.id == id ? d.copyWith(status: DkDebtStatus.assigned) : d,
        )
        .toList();
    notifyListeners();
    try {
      final DkDebt updated = await _repo.autoCarryDebt(id);
      _replaceDebt(updated);
      return updated;
    } on Exception {
      _debts = snapshot;
      notifyListeners();
      rethrow;
    }
  }

  /// 탕감(내려놓기). 낙관적으로 목록에서 숨기고 실패 시 롤백.
  Future<void> abandonDebt(String id) async {
    final List<DkDebt> snapshot = _debts;
    _debts = _debts.where((DkDebt d) => d.id != id).toList();
    notifyListeners();
    try {
      await _repo.abandonDebt(id);
    } on Exception {
      _debts = snapshot;
      notifyListeners();
      rethrow;
    }
  }

  void _replaceTask(DkTask next) {
    _tasks = _tasks.map((DkTask t) => t.id == next.id ? next : t).toList();
    notifyListeners();
  }

  void _replaceDebt(DkDebt next) {
    _debts = _debts.map((DkDebt d) => d.id == next.id ? next : d).toList();
    notifyListeners();
  }
}
