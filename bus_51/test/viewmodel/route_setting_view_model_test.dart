import 'dart:async';

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
  int callCount = 0;

  /// 설정하면 응답을 이 Completer 가 완료될 때까지 붙잡는다 (요청 진행 중 상태를 만들 때)
  Completer<void>? gate;

  @override
  Future<List<BusRouteModel>> getRoutesThroughStation({required String stationId}) async {
    callCount++;
    lastStationId = stationId;
    // 응답 내용은 요청 시점 기준으로 굳힌다 (붙잡혀 있는 동안 routes 를 바꿔도 이 응답은 그대로)
    final result = routes;
    final gate = this.gate;
    if (gate != null) await gate.future;
    if (exception != null) throw exception!;
    return result;
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

String singleRouteName(RouteSettingViewModel vm) => (vm.state as RouteSettingSuccess).routes.single.routeName;

void main() {
  group('RouteSettingViewModel', () {
    test('stationId가 null이면(잘못된 진입) 에러 상태가 된다', () async {
      final repo = FakeBusRouteRepository();
      final vm = RouteSettingViewModel(repo);

      await vm.load(stationId: null);

      expect(vm.state, isA<RouteSettingError>());
      expect(repo.callCount, 0);
    });

    test('조회 성공 시 Success 상태 + 정류장 id로 조회한다', () async {
      final repo = FakeBusRouteRepository(routes: [makeRoute()]);
      final vm = RouteSettingViewModel(repo);

      await vm.load(stationId: '226000060');

      expect(repo.lastStationId, '226000060');
      expect(vm.state, isA<RouteSettingSuccess>());
      expect((vm.state as RouteSettingSuccess).routes, hasLength(1));
    });

    test('경유 노선이 없으면 Empty 상태가 된다', () async {
      final vm = RouteSettingViewModel(FakeBusRouteRepository(routes: []));

      await vm.load(stationId: '226000060');

      expect(vm.state, isA<RouteSettingEmpty>());
    });

    test('ApiException 발생 시 에러 상태 + 메시지, retry 성공 시 복구된다', () async {
      final repo = FakeBusRouteRepository(exception: ApiException(message: '서버 오류'));
      final vm = RouteSettingViewModel(repo);

      await vm.load(stationId: '226000060');
      expect(vm.state, isA<RouteSettingError>());
      expect((vm.state as RouteSettingError).message, '서버 오류');

      repo.exception = null;
      repo.routes = [makeRoute()];
      await vm.retry();

      expect(vm.state, isA<RouteSettingSuccess>());
      expect(repo.lastStationId, '226000060');
    });
  });

  // 온보딩에서 뒤로 갔다 다시 들어오면 화면은 새로 만들어지지만 VM 은 남아 load 가 다시 불린다
  group('RouteSettingViewModel 다시 들어올 때 (load 재호출)', () {
    test('같은 정류장이면 API 를 다시 부르지 않고 받아둔 결과를 그대로 쓴다', () async {
      final repo = FakeBusRouteRepository(routes: [makeRoute()]);
      final vm = RouteSettingViewModel(repo);
      await vm.load(stationId: 'A');
      final firstState = vm.state;

      await vm.load(stationId: 'A');

      expect(repo.callCount, 1);
      expect(vm.state, same(firstState));
    });

    test('정류장이 바뀌면 다시 조회한다', () async {
      final repo = FakeBusRouteRepository(routes: [makeRoute()]);
      final vm = RouteSettingViewModel(repo);
      await vm.load(stationId: 'A');

      await vm.load(stationId: 'B');

      expect(repo.callCount, 2);
      expect(repo.lastStationId, 'B');
      expect(vm.state, isA<RouteSettingSuccess>());
    });

    test('지난 조회가 실패했으면 같은 정류장이라도 다시 조회한다', () async {
      final repo = FakeBusRouteRepository(exception: ApiException(message: '서버 오류'));
      final vm = RouteSettingViewModel(repo);
      await vm.load(stationId: 'A');
      expect(vm.state, isA<RouteSettingError>());

      repo.exception = null;
      repo.routes = [makeRoute()];
      await vm.load(stationId: 'A');

      expect(repo.callCount, 2);
      expect(vm.state, isA<RouteSettingSuccess>());
    });

    test('같은 정류장 조회가 진행 중이면 한 번 더 부르지 않는다', () async {
      final repo = FakeBusRouteRepository(routes: [makeRoute()]);
      final vm = RouteSettingViewModel(repo);
      final gate = repo.gate = Completer<void>();

      final first = vm.load(stationId: 'A');
      final second = vm.load(stationId: 'A');
      expect(repo.callCount, 1);
      expect(vm.state, isA<RouteSettingLoading>());

      gate.complete();
      await Future.wait([first, second]);

      expect(vm.state, isA<RouteSettingSuccess>());
    });

    test('기다리는 사이 정류장이 바뀌면 늦게 온 이전 응답은 버린다', () async {
      final repo = FakeBusRouteRepository(routes: [makeRoute(name: 'A노선')]);
      final vm = RouteSettingViewModel(repo);
      final gateA = repo.gate = Completer<void>();
      final stale = vm.load(stationId: 'A'); // A 응답은 붙잡혀 있음

      repo.gate = null;
      repo.routes = [makeRoute(name: 'B노선')];
      await vm.load(stationId: 'B');
      expect(singleRouteName(vm), 'B노선');

      gateA.complete();
      await stale;

      expect(singleRouteName(vm), 'B노선');
    });
  });
}
