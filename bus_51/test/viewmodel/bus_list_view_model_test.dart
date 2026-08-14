import 'package:bus_51/enums/bus_enums.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/viewmodel/bus_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// 실제 StorageService와 같은 인덱스 기반 동작을 흉내내는 인메모리 페이크
class FakeStorageService implements StorageService {
  FakeStorageService({List<UserSaveModel>? items}) : items = [...?items];

  List<UserSaveModel> items;
  List<int>? lastRemovedIndices;
  int? lastUpdatedIndex;

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
  Future<void> updateBusType(int index, BusType newBusType) async {
    lastUpdatedIndex = index;
    if (index >= 0 && index < items.length) {
      items[index] = items[index].copyWith(busType: newBusType);
    }
  }

  @override
  Future<void> addUserSaveModel(UserSaveModel newUser) async => items.add(newUser);
}

UserSaveModel makeUser({
  String routeName = '51',
  int stationId = 226000060,
  BusType busType = BusType.none,
}) =>
    UserSaveModel(
      routeName: routeName,
      stationId: stationId,
      routeId: 208000017,
      staOrder: 1,
      routeTypeCd: 13,
      busType: busType,
    );

/// 시간대 무관하게 전체 모드로 시작하도록 정오로 고정
DateTime noon() => DateTime(2026, 8, 14, 12);

BusListViewModel makeViewModel(FakeStorageService storage, {DateTime Function()? clock}) =>
    BusListViewModel(storage, clock: clock ?? noon);

void main() {
  group('BusListViewModel 상태', () {
    test('저장된 노선이 없으면 Empty 상태가 된다', () {
      final vm = makeViewModel(FakeStorageService());

      expect(vm.state, isA<BusListEmpty>());
      expect(vm.hasItems, isFalse);
    });

    test('전체 모드에서는 저장된 노선 전부가 보인다', () {
      final vm = makeViewModel(FakeStorageService(items: [
        makeUser(routeName: '51', busType: BusType.work),
        makeUser(routeName: '710', stationId: 2, busType: BusType.home),
      ]));

      expect(vm.state, isA<BusListSuccess>());
      expect((vm.state as BusListSuccess).items, hasLength(2));
    });

    test('출근 모드에서는 출근 노선만 보인다', () {
      final vm = makeViewModel(FakeStorageService(items: [
        makeUser(routeName: '51', busType: BusType.work),
        makeUser(routeName: '710', stationId: 2, busType: BusType.home),
      ]));

      vm.setMode(BusMode.work);

      final state = vm.state as BusListSuccess;
      expect(state.items, hasLength(1));
      expect(state.items.first.routeName, '51');
    });

    test('저장 노선은 있지만 필터 결과가 0개면 Empty가 아니라 FilterEmpty가 된다', () {
      final vm = makeViewModel(FakeStorageService(items: [
        makeUser(busType: BusType.none),
      ]));

      vm.setMode(BusMode.work);

      expect(vm.state, isA<BusListFilterEmpty>());
      // 삭제 버튼 노출 기준은 필터와 무관해야 한다
      expect(vm.hasItems, isTrue);
    });
  });

  group('BusListViewModel 시간대별 초기 모드', () {
    test('6~10시는 출근 모드로 시작한다', () {
      final vm = makeViewModel(FakeStorageService(), clock: () => DateTime(2026, 8, 14, 7));
      expect(vm.mode, BusMode.work);
    });

    test('17~20시는 퇴근 모드로 시작한다', () {
      final vm = makeViewModel(FakeStorageService(), clock: () => DateTime(2026, 8, 14, 18));
      expect(vm.mode, BusMode.home);
    });

    test('그 외 시간은 전체 모드로 시작한다', () {
      final vm = makeViewModel(FakeStorageService(), clock: () => DateTime(2026, 8, 14, 12));
      expect(vm.mode, BusMode.all);
    });
  });

  group('BusListViewModel 선택 모드', () {
    test('선택 토글 후 선택 모드를 끄면 선택이 초기화된다', () {
      final item = makeUser();
      final vm = makeViewModel(FakeStorageService(items: [item]));

      vm.toggleSelectionMode();
      vm.toggleSelection(item);
      expect(vm.isSelected(item), isTrue);
      expect(vm.selectedCount, 1);

      vm.toggleSelectionMode();
      expect(vm.isSelectionMode, isFalse);
      expect(vm.selectedCount, 0);
    });

    test('필터된 화면에서 선택해도 전체 리스트 기준 인덱스로 삭제된다', () async {
      final workUser = makeUser(routeName: '51', stationId: 2, busType: BusType.work);
      final storage = FakeStorageService(items: [
        makeUser(routeName: '710', stationId: 1, busType: BusType.home),
        workUser, // 전체 리스트에서는 인덱스 1, 출근 필터에서는 인덱스 0
      ]);
      final vm = makeViewModel(storage);
      vm.setMode(BusMode.work);

      vm.toggleSelectionMode();
      vm.toggleSelection(workUser);
      await vm.deleteSelected();

      expect(storage.lastRemovedIndices, [1]);
      expect(storage.items, hasLength(1));
      expect(storage.items.first.routeName, '710');
      expect(vm.isSelectionMode, isFalse);
    });

    test('삭제 후에는 저장소를 다시 읽어 상태가 갱신된다', () async {
      final item = makeUser();
      final vm = makeViewModel(FakeStorageService(items: [item]));

      vm.toggleSelectionMode();
      vm.toggleSelection(item);
      await vm.deleteSelected();

      expect(vm.state, isA<BusListEmpty>());
    });
  });

  group('BusListViewModel 저장소 조작', () {
    test('deleteAll은 전부 삭제하고 Empty 상태가 된다', () {
      final vm = makeViewModel(FakeStorageService(items: [makeUser(), makeUser(stationId: 2)]));

      vm.toggleSelectionMode();
      vm.deleteAll();

      expect(vm.state, isA<BusListEmpty>());
      expect(vm.isSelectionMode, isFalse);
    });

    test('changeBusType은 전체 리스트 기준 인덱스로 타입을 변경한다', () async {
      final target = makeUser(routeName: '710', stationId: 2);
      final storage = FakeStorageService(items: [makeUser(stationId: 1), target]);
      final vm = makeViewModel(storage);

      await vm.changeBusType(target, BusType.work);

      expect(storage.lastUpdatedIndex, 1);
      expect(storage.items[1].busType, BusType.work);
      // 갱신된 리스트가 상태에 반영된다
      final state = vm.state as BusListSuccess;
      expect(state.items[1].busType, BusType.work);
    });

    test('reload는 저장소의 최신 내용을 반영한다', () {
      final storage = FakeStorageService();
      final vm = makeViewModel(storage);
      expect(vm.state, isA<BusListEmpty>());

      storage.items.add(makeUser());
      vm.reload();

      expect(vm.state, isA<BusListSuccess>());
    });
  });
}
