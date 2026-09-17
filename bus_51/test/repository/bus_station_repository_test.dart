import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/repository/bus_station_repository.dart';
import 'package:bus_51/service/bus_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBusApiService implements BusApiService {
  FakeBusApiService(this.stations);

  final List<BusStationModel> stations;

  @override
  Future<List<BusStationModel>> getBusStationList({required String x, required String y}) async {
    return stations;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

BusStationModel makeStation({required String stationId, required String distance}) => BusStationModel(
      mobileNo: '03123',
      regionName: '수원',
      stationId: stationId,
      stationName: '정류장$stationId',
      distance: distance,
      x: '126.99992',
      y: '37.26574',
    );

void main() {
  group('BusStationRepository', () {
    test('searchRadiusMeters 초과 정류장은 걸러낸다 (경계값 포함)', () async {
      final repository = BusStationRepository(FakeBusApiService([
        makeStation(stationId: '1', distance: '100'),
        makeStation(stationId: '2', distance: '300'), // 경계값: 포함
        makeStation(stationId: '3', distance: '301'), // 초과: 제외
        makeStation(stationId: '4', distance: '499'),
      ]));

      final result = await repository.getStationsAround(latitude: 37.2, longitude: 127.0);

      expect(result.map((s) => s.stationId), ['1', '2']);
    });

    test('distance 파싱 실패 시 해당 정류장은 유지한다', () async {
      final repository = BusStationRepository(FakeBusApiService([
        makeStation(stationId: '1', distance: ''),
        makeStation(stationId: '2', distance: '400'),
      ]));

      final result = await repository.getStationsAround(latitude: 37.2, longitude: 127.0);

      expect(result.map((s) => s.stationId), ['1']);
    });
  });
}
