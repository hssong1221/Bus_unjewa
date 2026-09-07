import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/repository/bus_route_repository.dart';
import 'package:bus_51/screen/init_setting_screen/route_setting_screen.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:bus_51/viewmodel/route_setting_view_model.dart';
import 'package:bus_51/widget/bus_pulse_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 호출 횟수를 세는 노선 Repository
class CountingBusRouteRepository implements BusRouteRepository {
  CountingBusRouteRepository(this.routes);

  final List<BusRouteModel> routes;
  int callCount = 0;

  @override
  Future<List<BusRouteModel>> getRoutesThroughStation({required String stationId}) async {
    callCount++;
    return routes;
  }
}

BusStationModel makeStation(String id, String name) => BusStationModel(
      mobileNo: '01234',
      regionName: '수원',
      stationId: id,
      stationName: name,
      distance: '10',
      x: '127.0',
      y: '37.2',
    );

const route = BusRouteModel(
  regionName: '수원',
  routeDestId: '0',
  routeDestName: '사당역',
  routeId: '1',
  routeName: '7770',
  routeTypeCd: '11',
  routeTypeName: '직행좌석형시내버스',
  staOrder: '3',
);

void main() {
  late CountingBusRouteRepository repo;
  late InitProvider initProvider;
  late RouteSettingViewModel routeVm;

  setUp(() {
    repo = CountingBusRouteRepository([route]);
    initProvider = InitProvider(startIdx: InitProvider.stationStepIdx)
      ..setSelectedStationModel(makeStation('1', '수원역'))
      ..nextAccountView(); // 정류장(1) → 노선 선택(2)
    routeVm = RouteSettingViewModel(repo);
  });

  /// InitSettingScreen 처럼 InitProvider 와 노선 VM 을 단계 위젯 바깥에서 제공한다.
  /// [child] 만 갈아끼우면 InitProvider 가 단계 위젯을 교체하는 상황과 같다
  Widget wrap(Widget child) => MaterialApp(
        theme: lightTheme,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: initProvider),
            ChangeNotifierProvider.value(value: routeVm),
          ],
          child: child,
        ),
      );

  testWidgets('노선 선택 화면을 나갔다 다시 들어와도 같은 정류장이면 노선을 다시 조회하지 않는다', (tester) async {
    await tester.pumpWidget(wrap(const RouteSettingView()));
    await tester.pumpAndSettle();
    expect(find.text('7770'), findsOneWidget);
    expect(repo.callCount, 1);

    // 정류장 단계로 돌아갔다가(노선 위젯 제거) 다시 노선 단계로
    await tester.pumpWidget(wrap(const SizedBox()));
    await tester.pumpWidget(wrap(const RouteSettingView()));
    await tester.pump();

    // 로딩 없이 받아둔 목록이 바로 보이고, API 는 처음 한 번뿐
    expect(find.byType(BusPulseLoading), findsNothing);
    expect(find.text('7770'), findsOneWidget);
    expect(repo.callCount, 1);
  });

  testWidgets('뒤로 가서 다른 정류장을 고르고 들어오면 그 정류장 노선을 새로 조회한다', (tester) async {
    await tester.pumpWidget(wrap(const RouteSettingView()));
    await tester.pumpAndSettle();
    expect(repo.callCount, 1);

    await tester.pumpWidget(wrap(const SizedBox()));
    initProvider.setSelectedStationModel(makeStation('2', '장안구청'));
    await tester.pumpWidget(wrap(const RouteSettingView()));
    await tester.pumpAndSettle();

    expect(find.text("'장안구청' 정류장을 지나는 노선이에요"), findsOneWidget);
    expect(repo.callCount, 2);
  });
}
