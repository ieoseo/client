import 'package:ieoseo/data/api/api_exception.dart';
import 'package:ieoseo/data/data_controller.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/data/repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// 지정한 태스크에서 항상 실패하는 repository(롤백 검증용).
class _FailingRepository extends MockRepository {
  _FailingRepository({super.tasks});

  bool failNext = false;

  @override
  Future<DkTask> toggleComplete(DkTask task) {
    if (failNext) {
      throw ApiException.network();
    }
    return super.toggleComplete(task);
  }
}

/// load 에서 항상 던지는 repository.
class _ThrowingRepo extends MockRepository {
  @override
  Future<List<DkTask>> tasks({String? date}) =>
      Future<List<DkTask>>.error(ApiException.timeout());
}

/// autoCarryDebt 가 항상 (비동기로) 실패하는 repository(낙관·롤백 검증용, F6).
/// 실제 네트워크처럼 await 시점에 던지도록 async 로 둔다(동기 throw 면 낙관 단계 관찰 불가).
class _FailingAutoCarryRepo extends MockRepository {
  @override
  Future<DkDebt> autoCarryDebt(String id) async => throw ApiException.network();
}

const DkTask _t1 = DkTask(
  id: 't1',
  title: '알고리즘',
  mins: 60,
  date: '2026-06-04',
  state: DkTaskState.today,
  category: '공부',
);

void main() {
  group('load', () {
    test('초기엔 loading, 성공 후 데이터·idle', () async {
      final DataController c = DataController(
        MockRepository(
          tasks: <DkTask>[_t1],
          events: <DkEvent>[],
          debts: <DkDebt>[],
        ),
      );

      final Future<void> pending = c.load();
      expect(c.isLoading, isTrue);
      await pending;

      expect(c.isLoading, isFalse);
      expect(c.error, isNull);
      expect(c.tasks, hasLength(1));
      expect(c.tasks.single.id, 't1');
    });

    test('실패하면 error 메시지를 노출한다', () async {
      final DataController c = DataController(_ThrowingRepo());

      await c.load();

      expect(c.error, isNotNull);
      expect(c.isLoading, isFalse);
    });
  });

  group('toggleComplete 낙관적 업데이트', () {
    test('성공: 즉시 done 반영 후 서버 결과로 확정', () async {
      final DataController c = DataController(
        MockRepository(
          tasks: <DkTask>[_t1],
          events: <DkEvent>[],
          debts: <DkDebt>[],
        ),
      );
      await c.load();

      await c.toggleComplete(_t1);

      expect(c.tasks.single.state, DkTaskState.done);
    });

    test('실패: 롤백되어 원래 상태 유지', () async {
      final _FailingRepository repo = _FailingRepository(tasks: <DkTask>[_t1]);
      final DataController c = DataController(repo);
      await c.load();
      repo.failNext = true;

      await expectLater(c.toggleComplete(_t1), throwsA(isA<ApiException>()));

      expect(c.tasks.single.state, DkTaskState.today);
    });
  });

  group('createTask', () {
    test('성공하면 목록에 추가된다', () async {
      final DataController c = DataController(
        MockRepository(
          tasks: <DkTask>[],
          events: <DkEvent>[],
          debts: <DkDebt>[],
        ),
      );
      await c.load();

      await c.createTask(
        const DkTask(
          id: '',
          title: '새 할 일',
          mins: 30,
          date: '2026-06-04',
          state: DkTaskState.pending,
          category: '공부',
        ),
      );

      expect(c.tasks, hasLength(1));
      expect(c.tasks.single.title, '새 할 일');
    });
  });

  group('autoCarryDebt (F6 낙관·롤백)', () {
    test('낙관적으로 assigned 표시 후 실패 시 원래 상태로 롤백한다', () async {
      final DataController c = DataController(_FailingAutoCarryRepo());
      await c.load();
      final DkDebt target = c.debts.firstWhere(
        (DkDebt d) => d.status != DkDebtStatus.assigned,
      );
      final DkDebtStatus original = target.status;

      // 동기 prefix 에서 낙관적으로 assigned 가 반영된다(await 전).
      final Future<DkDebt> future = c.autoCarryDebt(target.id);
      expect(
        c.debts.firstWhere((DkDebt d) => d.id == target.id).status,
        DkDebtStatus.assigned,
      );

      await expectLater(future, throwsA(isA<ApiException>()));

      // 실패 → 원래 상태로 롤백(화면이 'assigned' 로 영구히 남지 않음).
      expect(
        c.debts.firstWhere((DkDebt d) => d.id == target.id).status,
        original,
      );
    });
  });
}
