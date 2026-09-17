import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:bus_51/viewmodel/favorite_setting_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBusRouteStationRepository implements BusRouteStationRepository {
  FakeBusRouteStationRepository({this.stations = const [], this.exception, this.failingRouteIds = const {}});

  List<BusRouteStationModel> stations;
  ApiException? exception;

  /// 이 노선 id 만 실패시킨다 (다중 노선 중 일부 실패 시나리오)
  Set<String> failingRouteIds;

  @override
  Future<List<BusRouteStationModel>> getStationsOnRoute({required String routeId}) async {
    if (exception != null || failingRouteIds.contains(routeId)) {
      throw exception ?? ApiException(message: '서버 오류');
    }
    return stations;
  }
}

class FakeStorageService implements StorageService {
  final List<UserSaveModel> saved = [];

  @override
  Future<void> addUserSaveModel(UserSaveModel newUser) async {
    saved.add(newUser);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

BusRouteModel makeRoute({String staOrder = '3', String routeId = '208000017', String routeName = '51'}) =>
    BusRouteModel(
      regionName: '수원',
      routeDestId: '0',
      routeDestName: '수원역',
      routeId: routeId,
      routeName: routeName,
      routeTypeCd: '13',
      routeTypeName: '일반형시내버스',
      staOrder: staOrder,
    );

BusRouteStationModel makeStation(int seq) => BusRouteStationModel(
      centerYn: 'N',
      districtCd: '2',
      mobileNo: '0$seq',
      regionName: '수원',
      stationId: '22600000$seq',
      stationName: '정류장$seq',
      x: '127.0',
      y: '37.2',
      adminName: '수원시',
      stationSeq: '$seq',
      turnSeq: '0',
      turnYn: 'N',
    );

List<BusRouteStationModel> makeStations(int count) => [for (int i = 1; i <= count; i++) makeStation(i)];

void main() {
  group('FavoriteSettingViewModel', () {
    test('routes 가 비어 있으면(잘못된 진입) 저장 불가', () async {
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(),
        FakeStorageService(),
        routes: const [],
      );

      await vm.init();

      expect(vm.canSave, isFalse);
    });

    test('조회 성공: staOrder 기준 탑승 정류장과 종점까지의 타임라인이 준비된다', () async {
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(stations: makeStations(10)),
        FakeStorageService(),
        routes: [makeRoute(staOrder: '3')],
      );

      await vm.init();

      final state = vm.stateAt(0);
      expect(state, isA<FavoriteSettingReady>());
      state as FavoriteSettingReady;
      expect(state.curStation.stationSeq, '3');
      expect(state.timelineStations, hasLength(8)); // 3번째부터 10번째까지
      expect(vm.canSave, isTrue);
    });

    test('staOrder가 정류장 목록 범위를 벗어나면 에러 상태 (RangeError 크래시 방지)', () async {
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(stations: makeStations(5)),
        FakeStorageService(),
        routes: [makeRoute(staOrder: '99')],
      );

      await vm.init();

      expect(vm.stateAt(0), isA<FavoriteSettingError>());
      expect(vm.canSave, isFalse);
    });

    test('정류장 목록이 비어있으면 에러 상태', () async {
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(stations: []),
        FakeStorageService(),
        routes: [makeRoute()],
      );

      await vm.init();

      expect(vm.stateAt(0), isA<FavoriteSettingError>());
    });

    test('ApiException 발생 시 에러 상태, retry 성공 시 복구된다', () async {
      final repo = FakeBusRouteStationRepository(exception: ApiException(message: '서버 오류'));
      final vm = FavoriteSettingViewModel(repo, FakeStorageService(), routes: [makeRoute()]);

      await vm.init();
      expect(vm.stateAt(0), isA<FavoriteSettingError>());

      repo.exception = null;
      repo.stations = makeStations(5);
      await vm.retry(0);

      expect(vm.stateAt(0), isA<FavoriteSettingReady>());
    });

    test('다중 노선: 하나만 실패하면 그 카드만 에러, 저장 불가. 그 카드 retry 후 저장 가능', () async {
      final repo = FakeBusRouteStationRepository(stations: makeStations(10), failingRouteIds: {'B'});
      final vm = FavoriteSettingViewModel(
        repo,
        FakeStorageService(),
        routes: [makeRoute(routeId: 'A'), makeRoute(routeId: 'B'), makeRoute(routeId: 'C')],
      );

      await vm.init();

      expect(vm.stateAt(0), isA<FavoriteSettingReady>());
      expect(vm.stateAt(1), isA<FavoriteSettingError>());
      expect(vm.stateAt(2), isA<FavoriteSettingReady>());
      expect(vm.canSave, isFalse);

      repo.failingRouteIds = {};
      await vm.retry(1);

      expect(vm.stateAt(1), isA<FavoriteSettingReady>());
      expect(vm.canSave, isTrue);
    });

    test('save: 탑승 정류장명과 종점명을 포함한 UserSaveModel이 저장된다', () async {
      final storage = FakeStorageService();
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(stations: makeStations(10)),
        storage,
        routes: [makeRoute(staOrder: '3')],
      );
      await vm.init();

      final saved = await vm.save();

      expect(saved, isTrue);
      expect(storage.saved, hasLength(1));
      final model = storage.saved.single;
      expect(model.routeName, '51');
      expect(model.routeId, 208000017);
      expect(model.staOrder, 3);
      // 리스트 카드에서 방향을 구분하는 데 쓰이는 두 필드
      expect(model.stationName, '정류장3');
      expect(model.routeDestName, '수원역');
    });

    test('save: 다중 노선이면 체크한 순서대로 전부 저장된다', () async {
      final storage = FakeStorageService();
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(stations: makeStations(10)),
        storage,
        routes: [
          makeRoute(routeId: '1', routeName: '7770', staOrder: '2'),
          makeRoute(routeId: '2', routeName: '5000', staOrder: '4'),
          makeRoute(routeId: '3', routeName: '11-1', staOrder: '6'),
        ],
      );
      await vm.init();

      final saved = await vm.save();

      expect(saved, isTrue);
      expect(storage.saved.map((m) => m.routeName), ['7770', '5000', '11-1']);
      expect(storage.saved.map((m) => m.staOrder), [2, 4, 6]);
      expect(storage.saved.map((m) => m.stationName), ['정류장2', '정류장4', '정류장6']);
    });

    test('save: 준비 전(로딩/에러)에는 저장되지 않는다', () async {
      final storage = FakeStorageService();
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(exception: ApiException(message: '서버 오류')),
        storage,
        routes: [makeRoute()],
      );
      await vm.init();

      final saved = await vm.save();

      expect(saved, isFalse);
      expect(storage.saved, isEmpty);
    });

    test('save: 숫자 파싱이 불가능한 값이면 아무것도 저장하지 않고 해당 카드만 에러 상태가 된다', () async {
      final storage = FakeStorageService();
      const badStation = BusRouteStationModel(
        centerYn: 'N',
        districtCd: '2',
        mobileNo: '01',
        regionName: '수원',
        stationId: '', // 파싱 불가
        stationName: '정류장1',
        x: '127.0',
        y: '37.2',
        adminName: '수원시',
        stationSeq: '1',
        turnSeq: '0',
        turnYn: 'N',
      );
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(stations: [badStation]),
        storage,
        routes: [makeRoute(staOrder: '1')],
      );
      await vm.init();

      final saved = await vm.save();

      expect(saved, isFalse);
      expect(storage.saved, isEmpty);
      expect(vm.stateAt(0), isA<FavoriteSettingError>());
    });
  });
}
