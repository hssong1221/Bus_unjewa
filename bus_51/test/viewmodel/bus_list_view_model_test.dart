import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:bus_51/viewmodel/bus_list_view_model.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// 실제 StorageService와 같은 인덱스 기반 동작을 흉내내는 인메모리 페이크
class FakeStorageService implements StorageService {
  FakeStorageService({List<UserSaveModel>? items}) : items = [...?items];

  List<UserSaveModel> items;
  List<int>? lastRemovedIndices;

  @override
  List<UserSaveModel> loadUserModelList() => [...items];

  @override
  void deleteUserData() => items.clear();

  @override
  Future<void> removeItems(List<int> indices) async {
    lastRemovedIndices = indices;
    final sorted = indices.toList()..sort((a, b) => b.compareTo(a));
    for (final index in sorted) {
      if (index >= 0 && index < items.length) items.removeAt(index);
    }
  }

  @override
  Future<void> addUserSaveModel(UserSaveModel newUser) async => items.add(newUser);

  @override
  Future<void> saveUserModelList(List<UserSaveModel> users) async => items = [...users];
}

UserSaveModel makeUser({
  String routeName = '51',
  int stationId = 226000060,
  int routeId = 208000017,
  int staOrder = 1,
  String routeDestName = '수원역',
}) =>
    UserSaveModel(
      routeName: routeName,
      stationId: stationId,
      routeId: routeId,
      staOrder: staOrder,
      routeTypeCd: 13,
      stationName: '정류장1',
      routeDestName: routeDestName,
    );

/// 정류장 ID 별로 그 정류장에 오고 있는 버스 목록을 돌려주는 도착 정보 페이크.
/// 등록되지 않은 정류장은 빈 목록(전부 운행 없음), [failingStationIds] 는 API 오류
class FakeBusArrivalRepository implements BusArrivalRepository {
  FakeBusArrivalRepository({Map<int, List<BusArrivalModel>>? arrivals, Set<int>? failingStationIds})
      : arrivals = {...?arrivals},
        failingStationIds = {...?failingStationIds};

  final Map<int, List<BusArrivalModel>> arrivals;
  final Set<int> failingStationIds;

  /// 정류장 단위 조회 횟수
  int callCount = 0;

  @override
  Future<List<BusArrivalModel>> getArrivalsAtStation({required String stationId}) async {
    callCount++;
    final id = int.parse(stationId);
    if (failingStationIds.contains(id)) throw ApiException(message: '서버 오류');
    return arrivals[id] ?? const [];
  }

  /// 노선 단위 조회는 상세 화면용이라 리스트 VM 은 부르지 않는다
  @override
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) =>
      throw UnimplementedError();
}

/// routeId·staOrder 기본값은 [makeUser] 와 같아서 한 카드에 그대로 매칭된다
BusArrivalModel makeArrival({
  String sec = '332',
  String min = '5',
  String locationNo = '3',
  String routeId = '208000017',
  String staOrder = '1',
}) =>
    BusArrivalModel(
      predictTime1: min,
      predictTime2: '',
      predictTimeSec1: sec,
      predictTimeSec2: '',
      locationNo1: locationNo,
      locationNo2: '',
      stationNm1: '앞정류장',
      stationNm2: '',
      flag: 'PASS',
      routeDestName: '수원역',
      routeId: routeId,
      stationId: '226000060',
      staOrder: staOrder,
    );

/// 도착 조회를 쓰지 않는 테스트는 저장소만 넘긴다.
/// pause/resume 을 검증하는 fakeAsync 테스트는 [now] 에 `async.getClock(...).now` 를 넣어 가짜 시간을 흐르게 한다
BusListViewModel makeVm(StorageService storage, {BusArrivalRepository? repo, DateTime Function()? now}) =>
    BusListViewModel(storage, repo ?? FakeBusArrivalRepository(), now: now);
void main() {
  group('BusListViewModel 상태', () {
    test('저장된 노선이 없으면 Empty 상태가 된다', () {
      final vm = makeVm(FakeStorageService());

      expect(vm.state, isA<BusListEmpty>());
      expect(vm.hasItems, isFalse);
    });

    test('저장된 노선 전부가 저장 순서대로 보인다', () {
      final vm = makeVm(FakeStorageService(items: [
        makeUser(routeName: '51'),
        makeUser(routeName: '710', stationId: 2),
      ]));

      final state = vm.state as BusListSuccess;
      expect(state.items, hasLength(2));
      expect(state.items.map((e) => e.routeName), ['51', '710']);
      expect(vm.hasItems, isTrue);
    });

    test('같은 노선이라도 방향(종점)이 다르면 별개 항목으로 보인다', () {
      final vm = makeVm(FakeStorageService(items: [
        makeUser(routeName: '7770', stationId: 1, routeDestName: '사당역'),
        makeUser(routeName: '7770', stationId: 2, routeDestName: '수원역'),
      ]));

      final state = vm.state as BusListSuccess;
      expect(state.items, hasLength(2));
      expect(state.items.map((e) => e.routeDestName), ['사당역', '수원역']);
    });
  });

  group('BusListViewModel 선택 모드', () {
    test('선택 토글 후 선택 모드를 끄면 선택이 초기화된다', () {
      final item = makeUser();
      final vm = makeVm(FakeStorageService(items: [item]));

      vm.toggleSelectionMode();
      vm.toggleSelection(item);
      expect(vm.isSelected(item), isTrue);
      expect(vm.selectedCount, 1);

      vm.toggleSelectionMode();
      expect(vm.isSelectionMode, isFalse);
      expect(vm.selectedCount, 0);
    });

    test('선택 삭제는 전체 리스트 기준 인덱스로 저장소에 전달된다', () async {
      final target = makeUser(routeName: '51', stationId: 2);
      final storage = FakeStorageService(items: [
        makeUser(routeName: '710', stationId: 1),
        target, // 인덱스 1
      ]);
      final vm = makeVm(storage);

      vm.toggleSelectionMode();
      vm.toggleSelection(target);
      await vm.deleteSelected();

      expect(storage.lastRemovedIndices, [1]);
      expect(storage.items, hasLength(1));
      expect(storage.items.first.routeName, '710');
      expect(vm.isSelectionMode, isFalse);
    });

    test('삭제 후에는 저장소를 다시 읽어 상태가 갱신된다', () async {
      final item = makeUser();
      final vm = makeVm(FakeStorageService(items: [item]));

      vm.toggleSelectionMode();
      vm.toggleSelection(item);
      await vm.deleteSelected();

      expect(vm.state, isA<BusListEmpty>());
    });
  });

  group('BusListViewModel 저장소 조작', () {
    test('deleteAll은 전부 삭제하고 Empty 상태가 된다', () {
      final vm = makeVm(FakeStorageService(items: [makeUser(), makeUser(stationId: 2)]));

      vm.toggleSelectionMode();
      vm.deleteAll();

      expect(vm.state, isA<BusListEmpty>());
      expect(vm.isSelectionMode, isFalse);
    });

    test('reload는 저장소의 최신 내용을 반영한다', () {
      final storage = FakeStorageService();
      final vm = makeVm(storage);
      expect(vm.state, isA<BusListEmpty>());

      storage.items.add(makeUser());
      vm.reload();

      expect(vm.state, isA<BusListSuccess>());
    });
  });

  group('BusListViewModel 순서 변경', () {
    test('move 는 카드를 옮기고 바뀐 순서를 바로 저장한다', () async {
      final a = makeUser(routeName: 'A', stationId: 1);
      final b = makeUser(routeName: 'B', stationId: 2);
      final c = makeUser(routeName: 'C', stationId: 3);
      final storage = FakeStorageService(items: [a, b, c]);
      final vm = makeVm(storage);

      // 첫 카드를 맨 아래로
      await vm.move(0, 2);
      expect((vm.state as BusListSuccess).items.map((e) => e.routeName), ['B', 'C', 'A']);
      expect(storage.items.map((e) => e.routeName), ['B', 'C', 'A']);

      // 맨 아래 카드를 맨 위로
      await vm.move(2, 0);
      expect(storage.items.map((e) => e.routeName), ['A', 'B', 'C']);

      // 제자리 드롭은 아무것도 안 한다
      await vm.move(1, 1);
      expect(storage.items.map((e) => e.routeName), ['A', 'B', 'C']);
    });
  });

  group('BusListViewModel 카드별 도착 정보', () {
    test('조회 전에는 로딩, 응답이 오면 카드마다 남은 초·정거장 수가 들어간다', () async {
      final a = makeUser(stationId: 1);
      final b = makeUser(stationId: 2);
      final vm = makeVm(
        FakeStorageService(items: [a, b]),
        repo: FakeBusArrivalRepository(arrivals: {1: [makeArrival(sec: '332', locationNo: '3')]}),
      );

      expect(vm.arrivalOf(a), isA<BusCardLoading>());

      await vm.loadArrivals();

      final arriving = vm.arrivalOf(a) as BusCardArriving;
      expect(arriving.remainingSeconds, 332);
      expect(arriving.locationNo, '3');
      // 등록되지 않은 정류장은 운행 없음
      expect(vm.arrivalOf(b), isA<BusCardNotOperating>());

      vm.dispose();
    });

    test('초 단위가 비어 오면 분 단위로 폴백한다', () async {
      final a = makeUser(stationId: 1);
      final vm = makeVm(
        FakeStorageService(items: [a]),
        repo: FakeBusArrivalRepository(arrivals: {1: [makeArrival(sec: '', min: '5')]}),
      );

      await vm.loadArrivals();

      expect((vm.arrivalOf(a) as BusCardArriving).remainingSeconds, 300);
      vm.dispose();
    });

    test('한 카드가 실패해도 다른 카드는 정상이고, retry 는 그 카드의 정류장만 다시 조회한다', () async {
      final ok = makeUser(stationId: 1);
      final bad = makeUser(stationId: 2);
      final repo = FakeBusArrivalRepository(arrivals: {1: [makeArrival()]}, failingStationIds: {2});
      final vm = makeVm(FakeStorageService(items: [ok, bad]), repo: repo);

      await vm.loadArrivals();
      expect(vm.arrivalOf(ok), isA<BusCardArriving>());
      expect(vm.arrivalOf(bad), isA<BusCardError>());
      expect(repo.callCount, 2);

      // 서버가 복구된 뒤 재시도
      repo.failingStationIds.clear();
      repo.arrivals[2] = [makeArrival(sec: '60')];
      await vm.retry(bad);

      expect((vm.arrivalOf(bad) as BusCardArriving).remainingSeconds, 60);
      expect(repo.callCount, 3);
      vm.dispose();
    });

    test('카운트다운은 1초마다 줄고 0에서 멈추며, 2분마다 전부 재조회한다', () {
      fakeAsync((async) {
        final a = makeUser(stationId: 1);
        final b = makeUser(stationId: 2);
        final repo = FakeBusArrivalRepository(arrivals: {1: [makeArrival(sec: '10')], 2: [makeArrival(sec: '400')]});
        final vm = makeVm(FakeStorageService(items: [a, b]), repo: repo);

        vm.loadArrivals();
        async.flushMicrotasks();
        expect(repo.callCount, 2);

        async.elapse(const Duration(seconds: 1));
        expect((vm.arrivalOf(a) as BusCardArriving).remainingSeconds, 9);
        expect((vm.arrivalOf(b) as BusCardArriving).remainingSeconds, 399);

        async.elapse(const Duration(seconds: 20));
        expect((vm.arrivalOf(a) as BusCardArriving).remainingSeconds, 0);
        expect((vm.arrivalOf(b) as BusCardArriving).remainingSeconds, 379);

        async.elapse(const Duration(seconds: 99)); // 총 120초
        expect(repo.callCount, 4);

        vm.dispose();
      });
    });

    test('pause 하면 갱신·카운트다운이 멈추고, 오래 지나서 resume 하면 다시 조회한다', () {
      fakeAsync((async) {
        final a = makeUser(stationId: 1);
        final repo = FakeBusArrivalRepository(arrivals: {1: [makeArrival(sec: '300')]});
        final vm = makeVm(FakeStorageService(items: [a]), repo: repo, now: async.getClock(DateTime(2026, 9, 7)).now);

        vm.loadArrivals();
        async.flushMicrotasks();
        vm.pause();

        async.elapse(const Duration(minutes: 3));
        expect((vm.arrivalOf(a) as BusCardArriving).remainingSeconds, 300);
        expect(repo.callCount, 1);

        vm.resume();
        async.flushMicrotasks();
        expect(repo.callCount, 2);
        async.elapse(const Duration(seconds: 1));
        expect((vm.arrivalOf(a) as BusCardArriving).remainingSeconds, 299);

        vm.dispose();
      });
    });

    test('reload 로 사라진 카드의 도착 정보는 버리고, 새 카드는 로딩으로 시작한다', () async {
      final a = makeUser(stationId: 1);
      final b = makeUser(stationId: 2);
      final storage = FakeStorageService(items: [a]);
      final vm = makeVm(storage, repo: FakeBusArrivalRepository(arrivals: {1: [makeArrival()], 2: [makeArrival()]}));

      await vm.loadArrivals();
      storage.items = [b];
      vm.reload();

      expect(vm.arrivalOf(b), isA<BusCardLoading>());

      await vm.resume();
      expect(vm.arrivalOf(b), isA<BusCardArriving>());
      vm.dispose();
    });
  });

  group('BusListViewModel 정류장 단위 조회', () {
    test('같은 정류장의 노선들은 API 한 번으로 전부 갱신되고, 응답에 없는 노선은 운행 없음', () async {
      final a = makeUser(stationId: 1, routeId: 10);
      final b = makeUser(stationId: 1, routeId: 20);
      final c = makeUser(stationId: 1, routeId: 30);
      final repo = FakeBusArrivalRepository(arrivals: {
        1: [makeArrival(routeId: '10', sec: '100'), makeArrival(routeId: '20', sec: '200')],
      });
      final vm = makeVm(FakeStorageService(items: [a, b, c]), repo: repo);

      await vm.loadArrivals();

      expect(repo.callCount, 1);
      expect((vm.arrivalOf(a) as BusCardArriving).remainingSeconds, 100);
      expect((vm.arrivalOf(b) as BusCardArriving).remainingSeconds, 200);
      expect(vm.arrivalOf(c), isA<BusCardNotOperating>());
      vm.dispose();
    });

    test('정류장이 다르면 정류장 수만큼만 조회한다', () async {
      final items = [makeUser(stationId: 1, routeId: 10), makeUser(stationId: 1, routeId: 20), makeUser(stationId: 2)];
      final repo = FakeBusArrivalRepository();
      final vm = makeVm(FakeStorageService(items: items), repo: repo);

      await vm.loadArrivals();

      expect(repo.callCount, 2);
      vm.dispose();
    });

    test('같은 노선이 정류장을 두 번 지나면(순환) staOrder 로 구분한다', () async {
      final first = makeUser(stationId: 1, routeId: 10, staOrder: 3);
      final second = makeUser(stationId: 1, routeId: 10, staOrder: 27);
      final repo = FakeBusArrivalRepository(arrivals: {
        1: [
          makeArrival(routeId: '10', staOrder: '3', sec: '100'),
          makeArrival(routeId: '10', staOrder: '27', sec: '900'),
        ],
      });
      final vm = makeVm(FakeStorageService(items: [first, second]), repo: repo);

      await vm.loadArrivals();

      expect((vm.arrivalOf(first) as BusCardArriving).remainingSeconds, 100);
      expect((vm.arrivalOf(second) as BusCardArriving).remainingSeconds, 900);
      vm.dispose();
    });

    test('정류장 조회가 실패하면 그 정류장의 카드가 모두 오류이고 다른 정류장은 정상이다', () async {
      final a = makeUser(stationId: 1, routeId: 10);
      final b = makeUser(stationId: 1, routeId: 20);
      final c = makeUser(stationId: 2);
      final repo = FakeBusArrivalRepository(arrivals: {2: [makeArrival()]}, failingStationIds: {1});
      final vm = makeVm(FakeStorageService(items: [a, b, c]), repo: repo);

      await vm.loadArrivals();

      expect(vm.arrivalOf(a), isA<BusCardError>());
      expect(vm.arrivalOf(b), isA<BusCardError>());
      expect(vm.arrivalOf(c), isA<BusCardArriving>());
      expect(repo.callCount, 2);
      vm.dispose();
    });
  });

  group('BusListViewModel 돌아왔을 때 재조회 생략', () {
    test('마지막 조회가 30초 안이면 resume 은 다시 받지 않고, 멈춰 있던 카운트다운만 흐른 시간만큼 당긴다', () {
      fakeAsync((async) {
        final a = makeUser(stationId: 1);
        final repo = FakeBusArrivalRepository(arrivals: {1: [makeArrival(sec: '300')]});
        final vm = makeVm(FakeStorageService(items: [a]), repo: repo, now: async.getClock(DateTime(2026, 9, 7)).now);

        vm.loadArrivals();
        async.flushMicrotasks();
        expect(repo.callCount, 1);

        // 5초 뒤 상세로 이동해 20초 머묾 (카운트다운은 멈춰 있다)
        async.elapse(const Duration(seconds: 5));
        vm.pause();
        async.elapse(const Duration(seconds: 20));
        expect((vm.arrivalOf(a) as BusCardArriving).remainingSeconds, 295);

        vm.resume();
        async.flushMicrotasks();
        expect(repo.callCount, 1); // 조회 25초 뒤 → 다시 받지 않음
        expect((vm.arrivalOf(a) as BusCardArriving).remainingSeconds, 275); // 멈춰 있던 20초를 당김

        // 카운트다운과 2분 갱신 타이머는 다시 돈다
        async.elapse(const Duration(seconds: 1));
        expect((vm.arrivalOf(a) as BusCardArriving).remainingSeconds, 274);
        async.elapse(const Duration(seconds: 119));
        expect(repo.callCount, 2);

        vm.dispose();
      });
    });

    test('마지막 조회가 30초를 넘었으면 resume 은 다시 받는다', () {
      fakeAsync((async) {
        final a = makeUser(stationId: 1);
        final repo = FakeBusArrivalRepository(arrivals: {1: [makeArrival(sec: '300')]});
        final vm = makeVm(FakeStorageService(items: [a]), repo: repo, now: async.getClock(DateTime(2026, 9, 7)).now);

        vm.loadArrivals();
        async.flushMicrotasks();
        vm.pause();
        async.elapse(const Duration(seconds: 31));

        vm.resume();
        async.flushMicrotasks();

        expect(repo.callCount, 2);
        vm.dispose();
      });
    });

    test('30초 안이어도 결과가 없는 카드가 있으면(노선 추가 직후) 다시 받는다', () {
      fakeAsync((async) {
        final a = makeUser(stationId: 1);
        final b = makeUser(stationId: 2);
        final storage = FakeStorageService(items: [a]);
        final repo = FakeBusArrivalRepository(arrivals: {1: [makeArrival()], 2: [makeArrival()]});
        final vm = makeVm(storage, repo: repo, now: async.getClock(DateTime(2026, 9, 7)).now);

        vm.loadArrivals();
        async.flushMicrotasks();
        expect(repo.callCount, 1);

        vm.pause();
        async.elapse(const Duration(seconds: 10));
        storage.items = [a, b];
        vm.reload();
        vm.resume();
        async.flushMicrotasks();

        expect(repo.callCount, 3); // 정류장 2개를 전부 다시 조회
        expect(vm.arrivalOf(b), isA<BusCardArriving>());
        vm.dispose();
      });
    });
  });
}
