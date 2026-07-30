import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/repository/bus_route_repository.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:bus_51/viewmodel/route_setting_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBusRouteRepository implements BusRouteRepository {
  FakeBusRouteRepository({this.routes = const [], this.exception});

  List<BusRouteModel> routes;
  ApiException? exception;
  String? lastStationId;

  @override
  Future<List<BusRouteModel>> getRoutesThroughStation({required String stationId}) async {
    lastStationId = stationId;
    if (exception != null) throw exception!;
    return routes;
  }
}

BusRouteModel makeRoute({String routeId = '208000017', String name = '51'}) => BusRouteModel(
      regionName: '수원',
      routeDestId: '0',
      routeDestName: '수원역',
      routeId: routeId,
      routeName: name,
      routeTypeCd: '13',
      routeTypeName: '일반형시내버스',
      staOrder: '1',
    );

void main() {
  group('RouteSettingViewModel', () {
    test('stationId가 null이면(잘못된 진입) 에러 상태가 된다', () async {
      final vm = RouteSettingViewModel(FakeBusRouteRepository(), stationId: null);

      await vm.init();

      expect(vm.state, isA<RouteSettingError>());
    });

    test('조회 성공 시 Success 상태 + 정류장 id로 조회한다', () async {
      final repo = FakeBusRouteRepository(routes: [makeRoute()]);
      final vm = RouteSettingViewModel(repo, stationId: '226000060');

      await vm.init();

      expect(repo.lastStationId, '226000060');
      expect(vm.state, isA<RouteSettingSuccess>());
      expect((vm.state as RouteSettingSuccess).routes, hasLength(1));
    });

    test('경유 노선이 없으면 Empty 상태가 된다', () async {
      final vm = RouteSettingViewModel(FakeBusRouteRepository(routes: []), stationId: '226000060');

      await vm.init();

      expect(vm.state, isA<RouteSettingEmpty>());
    });

    test('ApiException 발생 시 에러 상태 + 메시지, retry 성공 시 복구된다', () async {
      final repo = FakeBusRouteRepository(exception: ApiException(message: '서버 오류'));
      final vm = RouteSettingViewModel(repo, stationId: '226000060');

      await vm.init();
      expect(vm.state, isA<RouteSettingError>());
      expect((vm.state as RouteSettingError).message, '서버 오류');

      repo.exception = null;
      repo.routes = [makeRoute()];
      await vm.retry();

      expect(vm.state, isA<RouteSettingSuccess>());
    });
  });
}
