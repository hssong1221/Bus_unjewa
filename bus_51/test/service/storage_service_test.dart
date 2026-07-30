import 'package:bus_51/enums/bus_enums.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

UserSaveModel makeUser({
  int stationId = 226000060,
  int routeId = 208000017,
  int staOrder = 1,
  BusType busType = BusType.none,
}) =>
    UserSaveModel(
      routeName: '51',
      stationId: stationId,
      routeId: routeId,
      staOrder: staOrder,
      routeTypeCd: 13,
      busType: busType,
    );

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    storage = StorageService(prefs);
  });

  group('StorageService', () {
    test('저장한 적 없으면 빈 리스트를 반환한다', () {
      expect(storage.loadUserModelList(), isEmpty);
    });

    test('저장 후 로드하면 동일한 모델이 복원된다 (JSON 라운드트립)', () async {
      final user = makeUser(busType: BusType.work);
      await storage.addUserSaveModel(user);

      final loaded = storage.loadUserModelList();
      expect(loaded, hasLength(1));
      expect(loaded.first, user);
    });

    test('정류장+노선+순서+버스타입이 모두 같으면 중복 추가되지 않는다', () async {
      await storage.addUserSaveModel(makeUser());
      await storage.addUserSaveModel(makeUser());
      expect(storage.loadUserModelList(), hasLength(1));

      // busType만 달라도 별개 항목으로 추가된다
      await storage.addUserSaveModel(makeUser(busType: BusType.work));
      expect(storage.loadUserModelList(), hasLength(2));
    });

    test('removeItems는 선택한 인덱스들을 삭제한다', () async {
      await storage.addUserSaveModel(makeUser(stationId: 1));
      await storage.addUserSaveModel(makeUser(stationId: 2));
      await storage.addUserSaveModel(makeUser(stationId: 3));

      await storage.removeItems([0, 2]);

      final loaded = storage.loadUserModelList();
      expect(loaded, hasLength(1));
      expect(loaded.first.stationId, 2);
    });

    test('updateBusType은 해당 인덱스의 버스타입만 변경한다', () async {
      await storage.addUserSaveModel(makeUser(stationId: 1));
      await storage.addUserSaveModel(makeUser(stationId: 2));

      await storage.updateBusType(1, BusType.home);

      final loaded = storage.loadUserModelList();
      expect(loaded[0].busType, BusType.none);
      expect(loaded[1].busType, BusType.home);
    });

    test('deleteUserData 후에는 빈 리스트를 반환한다', () async {
      await storage.addUserSaveModel(makeUser());
      storage.deleteUserData();
      expect(storage.loadUserModelList(), isEmpty);
    });
  });
}
