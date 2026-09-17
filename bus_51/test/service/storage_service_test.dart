import 'dart:convert';

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
  String routeDestName = '수원역',
}) =>
    UserSaveModel(
      routeName: '51',
      stationId: stationId,
      routeId: routeId,
      staOrder: staOrder,
      routeTypeCd: 13,
      stationName: '정류장$staOrder',
      routeDestName: routeDestName,
    );

void main() {
  late SharedPreferencesWithCache prefs;
  late StorageService storage;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    storage = StorageService(prefs);
  });

  group('StorageService', () {
    test('저장한 적 없으면 빈 리스트를 반환한다', () {
      expect(storage.loadUserModelList(), isEmpty);
    });

    test('저장 후 로드하면 동일한 모델이 복원된다 (JSON 라운드트립)', () async {
      final user = makeUser();
      await storage.addUserSaveModel(user);

      final loaded = storage.loadUserModelList();
      expect(loaded, hasLength(1));
      expect(loaded.first, user);
    });

    test('정류장+노선+순서가 모두 같으면 중복 추가되지 않는다', () async {
      await storage.addUserSaveModel(makeUser());
      await storage.addUserSaveModel(makeUser());
      expect(storage.loadUserModelList(), hasLength(1));

      // 같은 노선이라도 탑승 정류장(순서)이 다르면 별개 항목 (반대 방향 저장)
      await storage.addUserSaveModel(makeUser(staOrder: 20, routeDestName: '사당역'));
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

    test('deleteUserData 후에는 빈 리스트를 반환한다', () async {
      await storage.addUserSaveModel(makeUser());
      storage.deleteUserData();
      expect(storage.loadUserModelList(), isEmpty);
    });

    test('필드 구성이 다른 구버전 저장 데이터는 크래시 없이 빈 리스트로 취급한다', () async {
      // stationName/routeDestName 없이 busType이 있던 시절의 포맷
      const legacy = [
        {
          'routeName': '51',
          'stationId': 226000060,
          'routeId': 208000017,
          'staOrder': 1,
          'routeTypeCd': 13,
          'busType': 'work',
        },
      ];
      await prefs.setString('user_save_data', jsonEncode(legacy));

      expect(storage.loadUserModelList(), isEmpty);

      // 이후 새로 저장하면 구버전 데이터는 덮어써진다
      await storage.addUserSaveModel(makeUser());
      expect(storage.loadUserModelList(), hasLength(1));
    });
  });
}
