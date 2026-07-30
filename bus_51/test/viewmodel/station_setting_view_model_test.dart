import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/repository/bus_station_repository.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:bus_51/viewmodel/station_setting_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBusStationRepository implements BusStationRepository {
  FakeBusStationRepository({this.stations = const [], this.exception});

  List<BusStationModel> stations;
  ApiException? exception;
  MapPoint? lastSearchedCenter;
  int callCount = 0;

  @override
  Future<List<BusStationModel>> getStationsAround({
    required double latitude,
    required double longitude,
  }) async {
    callCount++;
    lastSearchedCenter = (lat: latitude, lng: longitude);
    if (exception != null) throw exception!;
    return stations;
  }
}

BusStationModel makeStation({String stationId = '226000060', String name = '수원역'}) => BusStationModel(
      mobileNo: '03123',
      regionName: '수원',
      stationId: stationId,
      stationName: name,
      distance: '150',
      x: '126.99992',
      y: '37.26574',
    );

void main() {
  group('StationSettingViewModel', () {
    test('init: GPS 성공 시 현위치가 초기 위치가 되고 그 주변을 자동 검색한다', () async {
      final repo = FakeBusStationRepository(stations: [makeStation()]);
      final vm = StationSettingViewModel(
        repo,
        positionResolver: () async => (lat: 37.5, lng: 127.1),
      );

      await vm.init();

      expect(vm.initialPosition, (lat: 37.5, lng: 127.1));
      expect(vm.usedFallbackPosition, isFalse);
      expect(repo.lastSearchedCenter, (lat: 37.5, lng: 127.1));
      expect(vm.stations, hasLength(1));
    });

    test('init: GPS 실패 시 기본 위치(수원역)로 대체하고 검색은 계속한다', () async {
      final repo = FakeBusStationRepository(stations: [makeStation()]);
      final vm = StationSettingViewModel(
        repo,
        positionResolver: () async => throw Exception('위치 권한 거부'),
      );

      await vm.init();

      expect(vm.initialPosition, StationSettingViewModel.defaultPosition);
      expect(vm.usedFallbackPosition, isTrue);
      expect(repo.callCount, 1);
      expect(vm.stations, hasLength(1));
    });

    test('searchAround: 검색 성공 시 정류장이 교체되고 기존 선택은 해제된다', () async {
      final repo = FakeBusStationRepository(stations: [makeStation()]);
      final vm = StationSettingViewModel(repo, positionResolver: () async => (lat: 37.5, lng: 127.1));
      await vm.init();
      vm.selectStation(vm.stations.first);

      repo.stations = [makeStation(stationId: '2', name: '장안구청')];
      await vm.searchAround((lat: 37.3, lng: 127.0));

      expect(vm.stations.single.stationName, '장안구청');
      expect(vm.selectedStation, isNull);
      expect(vm.noticeMessage, isNull);
      expect(vm.isSearching, isFalse);
    });

    test('searchAround: 빈 결과면 안내 문구를 노출한다', () async {
      final repo = FakeBusStationRepository(stations: []);
      final vm = StationSettingViewModel(repo, positionResolver: () async => (lat: 37.5, lng: 127.1));

      await vm.init();

      expect(vm.stations, isEmpty);
      expect(vm.noticeMessage, '주변에 버스 정류장이 없습니다');
    });

    test('searchAround: ApiException 발생 시 실패 안내 문구 + 검색 상태 해제', () async {
      final repo = FakeBusStationRepository(exception: ApiException(message: '서버 오류'));
      final vm = StationSettingViewModel(repo, positionResolver: () async => (lat: 37.5, lng: 127.1));

      await vm.init();

      expect(vm.noticeMessage, '정류장 검색에 실패했습니다');
      expect(vm.isSearching, isFalse);

      // 실패 후 재검색 성공 시 정상 복구
      repo.exception = null;
      repo.stations = [makeStation()];
      await vm.searchAround((lat: 37.3, lng: 127.0));
      expect(vm.stations, hasLength(1));
      expect(vm.noticeMessage, isNull);
    });

    test('selectStation / clearSelection', () async {
      final repo = FakeBusStationRepository(stations: [makeStation()]);
      final vm = StationSettingViewModel(repo, positionResolver: () async => (lat: 37.5, lng: 127.1));
      await vm.init();

      vm.selectStation(vm.stations.first);
      expect(vm.selectedStation, vm.stations.first);

      vm.clearSelection();
      expect(vm.selectedStation, isNull);
    });
  });
}
