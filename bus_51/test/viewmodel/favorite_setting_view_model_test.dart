import 'package:bus_51/enums/bus_enums.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:bus_51/viewmodel/favorite_setting_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBusRouteStationRepository implements BusRouteStationRepository {
  FakeBusRouteStationRepository({this.stations = const [], this.exception});

  List<BusRouteStationModel> stations;
  ApiException? exception;

  @override
  Future<List<BusRouteStationModel>> getStationsOnRoute({required String routeId}) async {
    if (exception != null) throw exception!;
    return stations;
  }
}

class FakeStorageService implements StorageService {
  UserSaveModel? lastSaved;

  @override
  Future<void> addUserSaveModel(UserSaveModel newUser) async {
    lastSaved = newUser;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

BusRouteModel makeRoute({String staOrder = '3', String routeId = '208000017'}) => BusRouteModel(
      regionName: '수원',
      routeDestId: '0',
      routeDestName: '수원역',
      routeId: routeId,
      routeName: '51',
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
    test('route가 null이면(잘못된 진입) 에러 상태 + 저장 불가', () async {
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(),
        FakeStorageService(),
        route: null,
      );

      await vm.init();

      expect(vm.state, isA<FavoriteSettingError>());
      expect(vm.canSave, isFalse);
    });

    test('조회 성공: staOrder 기준 탑승 정류장과 종점까지의 타임라인이 준비된다', () async {
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(stations: makeStations(10)),
        FakeStorageService(),
        route: makeRoute(staOrder: '3'),
      );

      await vm.init();

      final state = vm.state;
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
        route: makeRoute(staOrder: '99'),
      );

      await vm.init();

      expect(vm.state, isA<FavoriteSettingError>());
      expect(vm.canSave, isFalse);
    });

    test('정류장 목록이 비어있으면 에러 상태', () async {
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(stations: []),
        FakeStorageService(),
        route: makeRoute(),
      );

      await vm.init();

      expect(vm.state, isA<FavoriteSettingError>());
    });

    test('ApiException 발생 시 에러 상태, retry 성공 시 복구된다', () async {
      final repo = FakeBusRouteStationRepository(exception: ApiException(message: '서버 오류'));
      final vm = FavoriteSettingViewModel(repo, FakeStorageService(), route: makeRoute());

      await vm.init();
      expect(vm.state, isA<FavoriteSettingError>());

      repo.exception = null;
      repo.stations = makeStations(5);
      await vm.retry();

      expect(vm.state, isA<FavoriteSettingReady>());
    });

    test('save: 선택한 버스 타입으로 올바른 UserSaveModel이 저장된다', () async {
      final storage = FakeStorageService();
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(stations: makeStations(10)),
        storage,
        route: makeRoute(staOrder: '3'),
      );
      await vm.init();
      vm.setBusType(BusType.work);

      final saved = await vm.save();

      expect(saved, isTrue);
      expect(storage.lastSaved, isNotNull);
      expect(storage.lastSaved!.routeName, '51');
      expect(storage.lastSaved!.routeId, 208000017);
      expect(storage.lastSaved!.staOrder, 3);
      expect(storage.lastSaved!.busType, BusType.work);
    });

    test('save: 준비 전(로딩/에러)에는 저장되지 않는다', () async {
      final storage = FakeStorageService();
      final vm = FavoriteSettingViewModel(
        FakeBusRouteStationRepository(exception: ApiException(message: '서버 오류')),
        storage,
        route: makeRoute(),
      );
      await vm.init();

      final saved = await vm.save();

      expect(saved, isFalse);
      expect(storage.lastSaved, isNull);
    });

    test('save: 숫자 파싱이 불가능한 값이면 저장하지 않고 에러 상태가 된다', () async {
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
        route: makeRoute(staOrder: '1'),
      );
      await vm.init();

      final saved = await vm.save();

      expect(saved, isFalse);
      expect(storage.lastSaved, isNull);
      expect(vm.state, isA<FavoriteSettingError>());
    });
  });
}
