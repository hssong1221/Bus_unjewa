import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/viewmodel/bus_list_view_model.dart';
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
}

UserSaveModel makeUser({
  String routeName = '51',
  int stationId = 226000060,
  String routeDestName = '수원역',
}) =>
    UserSaveModel(
      routeName: routeName,
      stationId: stationId,
      routeId: 208000017,
      staOrder: 1,
      routeTypeCd: 13,
      stationName: '정류장1',
      routeDestName: routeDestName,
    );

void main() {
  group('BusListViewModel 상태', () {
    test('저장된 노선이 없으면 Empty 상태가 된다', () {
      final vm = BusListViewModel(FakeStorageService());

      expect(vm.state, isA<BusListEmpty>());
      expect(vm.hasItems, isFalse);
    });

    test('저장된 노선 전부가 저장 순서대로 보인다', () {
      final vm = BusListViewModel(FakeStorageService(items: [
        makeUser(routeName: '51'),
        makeUser(routeName: '710', stationId: 2),
      ]));

      final state = vm.state as BusListSuccess;
      expect(state.items, hasLength(2));
      expect(state.items.map((e) => e.routeName), ['51', '710']);
      expect(vm.hasItems, isTrue);
    });

    test('같은 노선이라도 방향(종점)이 다르면 별개 항목으로 보인다', () {
      final vm = BusListViewModel(FakeStorageService(items: [
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
      final vm = BusListViewModel(FakeStorageService(items: [item]));

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
      final vm = BusListViewModel(storage);

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
      final vm = BusListViewModel(FakeStorageService(items: [item]));

      vm.toggleSelectionMode();
      vm.toggleSelection(item);
      await vm.deleteSelected();

      expect(vm.state, isA<BusListEmpty>());
    });
  });

  group('BusListViewModel 저장소 조작', () {
    test('deleteAll은 전부 삭제하고 Empty 상태가 된다', () {
      final vm = BusListViewModel(FakeStorageService(items: [makeUser(), makeUser(stationId: 2)]));

      vm.toggleSelectionMode();
      vm.deleteAll();

      expect(vm.state, isA<BusListEmpty>());
      expect(vm.isSelectionMode, isFalse);
    });

    test('reload는 저장소의 최신 내용을 반영한다', () {
      final storage = FakeStorageService();
      final vm = BusListViewModel(storage);
      expect(vm.state, isA<BusListEmpty>());

      storage.items.add(makeUser());
      vm.reload();

      expect(vm.state, isA<BusListSuccess>());
    });
  });
}
