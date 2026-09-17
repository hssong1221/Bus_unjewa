import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InitProvider 최초 온보딩 (startIdx 0)', () {
    test('웰컴(0)에서 시작하고 첫 단계로 판정한다', () {
      final provider = InitProvider();

      expect(provider.curIdx, 0);
      expect(provider.isFirstStep, isTrue);
      expect(provider.stepNumber, 1);
      expect(provider.totalSteps, 4);
    });

    test('첫 단계에서 prev 를 눌러도 0 아래로 내려가지 않는다', () {
      final provider = InitProvider();

      provider.prevAccountView();

      expect(provider.curIdx, 0);
      expect(provider.isFirstStep, isTrue);
    });

    test('next 로 마지막 단계(3)까지 가고 그 이상은 멈춘다', () {
      final provider = InitProvider();

      provider.nextAccountView();
      provider.nextAccountView();
      provider.nextAccountView();
      provider.nextAccountView();

      expect(provider.curIdx, 3);
      expect(provider.stepNumber, 4);
      expect(provider.isFirstStep, isFalse);
    });
  });

  group('InitProvider 노선 추가 플로우 (startIdx 1)', () {
    test('정류장 선택(1)에서 시작하고 진행 표시는 1/3 이다', () {
      final provider = InitProvider(startIdx: InitProvider.stationStepIdx);

      expect(provider.curIdx, 1);
      expect(provider.isFirstStep, isTrue);
      expect(provider.stepNumber, 1);
      expect(provider.totalSteps, 3);
    });

    test('첫 단계에서 prev 를 눌러도 웰컴(0)으로 돌아가지 않는다', () {
      final provider = InitProvider(startIdx: InitProvider.stationStepIdx);

      provider.prevAccountView();

      expect(provider.curIdx, 1);
      expect(provider.isFirstStep, isTrue);
    });

    test('next 후 prev 하면 시작 단계로 돌아오고 다시 첫 단계로 판정한다', () {
      final provider = InitProvider(startIdx: InitProvider.stationStepIdx);

      provider.nextAccountView();
      expect(provider.curIdx, 2);
      expect(provider.isFirstStep, isFalse);
      expect(provider.stepNumber, 2);

      provider.prevAccountView();
      expect(provider.curIdx, 1);
      expect(provider.isFirstStep, isTrue);
    });

    test('마지막 단계는 3/3 으로 표시된다', () {
      final provider = InitProvider(startIdx: InitProvider.stationStepIdx);

      provider.nextAccountView();
      provider.nextAccountView();

      expect(provider.curIdx, 3);
      expect(provider.stepNumber, 3);
      expect(provider.totalSteps, 3);
    });

    test('단계가 바뀔 때 리스너에게 알린다', () {
      final provider = InitProvider(startIdx: InitProvider.stationStepIdx);
      var notified = 0;
      provider.addListener(() => notified++);

      provider.nextAccountView();
      provider.prevAccountView();

      expect(notified, 2);
    });
  });

  selectionTests();
}

BusRouteModel makeRoute(String routeId) => BusRouteModel(
      regionName: '수원',
      routeDestId: '0',
      routeDestName: '수원역',
      routeId: routeId,
      routeName: routeId,
      routeTypeCd: '13',
      routeTypeName: '일반형시내버스',
      staOrder: '3',
    );

BusStationModel makeStation(String stationId) => BusStationModel(
      mobileNo: '01234',
      regionName: '수원',
      stationId: stationId,
      stationName: '정류장$stationId',
      distance: '10',
      x: '127.0',
      y: '37.2',
    );

void selectionTests() {
  group('InitProvider 노선 다중 선택', () {
    test('토글하면 체크한 순서대로 쌓이고, 다시 토글하면 빠진다', () {
      final provider = InitProvider();
      final a = makeRoute('A'), b = makeRoute('B');

      provider.toggleSelectedRoute(a);
      provider.toggleSelectedRoute(b);
      expect(provider.selectedRouteModels, [a, b]);
      expect(provider.isRouteSelected(a), isTrue);

      provider.toggleSelectedRoute(a);
      expect(provider.selectedRouteModels, [b]);
      expect(provider.isRouteSelected(a), isFalse);
    });

    test('같은 정류장을 다시 골라도 체크는 유지된다 (뒤로 갔다 오는 경우)', () {
      final provider = InitProvider();
      provider.setSelectedStationModel(makeStation('S1'));
      provider.toggleSelectedRoute(makeRoute('A'));

      provider.setSelectedStationModel(makeStation('S1'));

      expect(provider.selectedRouteModels, hasLength(1));
    });

    test('다른 정류장을 고르면 이전 정류장 기준 체크는 비워진다', () {
      final provider = InitProvider();
      provider.setSelectedStationModel(makeStation('S1'));
      provider.toggleSelectedRoute(makeRoute('A'));

      provider.setSelectedStationModel(makeStation('S2'));

      expect(provider.selectedRouteModels, isEmpty);
    });
  });
}
