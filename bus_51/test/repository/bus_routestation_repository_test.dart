import 'dart:async';

import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/service/bus_api_service.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// routeId 별 호출 횟수를 세고, [failing] 이면 ApiException, [empty] 면 빈 리스트를 돌려준다
class FakeBusApiService implements BusApiService {
  final Map<String, int> _callCounts = {};
  Set<String> failing = {};
  Set<String> empty = {};

  /// 설정하면 응답을 이 Completer 가 완료될 때까지 붙잡는다 (요청 진행 중 상태를 만들 때)
  Completer<void>? gate;

  int callCount(String routeId) => _callCounts[routeId] ?? 0;

  @override
  Future<List<BusRouteStationModel>> getBusRouteStationList({required String routeId}) async {
    _callCounts[routeId] = callCount(routeId) + 1;
    if (gate != null) await gate!.future;
    if (failing.contains(routeId)) throw ApiException(message: '서버 오류');
    if (empty.contains(routeId)) return [];
    return [makeStation(routeId, 1), makeStation(routeId, 2)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

BusRouteStationModel makeStation(String routeId, int seq) => BusRouteStationModel(
      centerYn: 'N',
      districtCd: '1',
      mobileNo: '0$seq',
      regionName: '수원',
      stationId: '$routeId-$seq',
      stationName: '정류장$seq',
      x: '127.0',
      y: '37.0',
      adminName: '수원시',
      stationSeq: '$seq',
      turnSeq: '10',
      turnYn: 'N',
    );

void main() {
  late FakeBusApiService api;
  late BusRouteStationRepository repo;

  setUp(() {
    api = FakeBusApiService();
    repo = BusRouteStationRepository(api);
  });

  group('BusRouteStationRepository 캐시', () {
    test('같은 노선을 다시 조회하면 API 를 부르지 않고 같은 결과를 준다', () async {
      final first = await repo.getStationsOnRoute(routeId: 'A');
      final second = await repo.getStationsOnRoute(routeId: 'A');

      expect(api.callCount('A'), 1);
      expect(second, first);
    });

    test('노선이 다르면 각각 조회한다', () async {
      await repo.getStationsOnRoute(routeId: 'A');
      await repo.getStationsOnRoute(routeId: 'B');

      expect(api.callCount('A'), 1);
      expect(api.callCount('B'), 1);
    });

    test('같은 노선을 동시에 요청해도 API 는 한 번만 나간다', () async {
      api.gate = Completer<void>();
      final futures = [
        repo.getStationsOnRoute(routeId: 'A'),
        repo.getStationsOnRoute(routeId: 'A'),
      ];
      expect(api.callCount('A'), 1);

      api.gate!.complete();
      final results = await Future.wait(futures);
      expect(results[0], hasLength(2));
      expect(results[1], results[0]);
    });

    test('실패는 캐시하지 않아 재시도 때 다시 요청한다', () async {
      api.failing = {'A'};
      await expectLater(repo.getStationsOnRoute(routeId: 'A'), throwsA(isA<ApiException>()));

      api.failing = {};
      final stations = await repo.getStationsOnRoute(routeId: 'A');

      expect(api.callCount('A'), 2);
      expect(stations, hasLength(2));
    });

    test('빈 결과는 캐시하지 않아 다음 조회 때 다시 요청한다', () async {
      api.empty = {'A'};
      expect(await repo.getStationsOnRoute(routeId: 'A'), isEmpty);

      api.empty = {};
      final stations = await repo.getStationsOnRoute(routeId: 'A');

      expect(api.callCount('A'), 2);
      expect(stations, hasLength(2));
    });
  });
}
