import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/repository/bus_route_repository.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/screen/init_setting_screen/favorite_setting_screen.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/init_setting_screen/route_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:bus_51/viewmodel/route_setting_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeBusRouteRepository implements BusRouteRepository {
  FakeBusRouteRepository(this.routes);

  final List<BusRouteModel> routes;

  @override
  Future<List<BusRouteModel>> getRoutesThroughStation({required String stationId}) async => routes;
}

class FakeBusRouteStationRepository implements BusRouteStationRepository {
  FakeBusRouteStationRepository(this.stations);

  final List<BusRouteStationModel> stations;

  @override
  Future<List<BusRouteStationModel>> getStationsOnRoute({required String routeId}) async => stations;
}

const station = BusStationModel(
  mobileNo: '01234',
  regionName: '수원',
  stationId: '226000003',
  stationName: '수원역',
  distance: '10',
  x: '127.0',
  y: '37.2',
);

BusRouteModel makeRoute(String routeName, String routeId, {String dest = '사당역'}) => BusRouteModel(
      regionName: '수원',
      routeDestId: '0',
      routeDestName: dest,
      routeId: routeId,
      routeName: routeName,
      routeTypeCd: '11',
      routeTypeName: '직행좌석형시내버스',
      staOrder: '3',
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

final routes = [makeRoute('7770', '1'), makeRoute('5000', '2', dest: '강남역'), makeRoute('900', '3', dest: '봉담')];

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    storage = StorageService(prefs);
    GetIt.I.registerSingleton<StorageService>(storage);
    GetIt.I.registerSingleton<BusRouteRepository>(FakeBusRouteRepository(routes));
    GetIt.I.registerSingleton<BusRouteStationRepository>(
      FakeBusRouteStationRepository([for (var i = 1; i <= 5; i++) makeStation(i)]),
    );
  });

  tearDown(() async => GetIt.I.reset());

  /// 실제 앱에서는 InitSettingScreen 이 InitProvider 와 단계 VM 을 함께 제공한다
  Widget wrap(InitProvider provider, Widget child) => MaterialApp(
        theme: lightTheme,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => RouteSettingViewModel(GetIt.I<BusRouteRepository>())),
          ],
          child: child,
        ),
      );

  testWidgets('노선 선택: 탭으로 체크 토글, 버튼 문구에 개수 반영, 0개면 비활성', (tester) async {
    final provider = InitProvider(startIdx: InitProvider.stationStepIdx)
      ..setSelectedStationModel(station)
      ..nextAccountView(); // 정류장(1) → 노선 선택(2)
    await tester.pumpWidget(wrap(provider, const RouteSettingView()));
    await tester.pumpAndSettle();

    expect(find.text('노선을 선택해 주세요'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).enabled, isFalse);

    await tester.tap(find.text('7770'));
    await tester.tap(find.text('5000'));
    await tester.pumpAndSettle();

    expect(find.text('2개 노선 선택 · 다음'), findsOneWidget);
    expect(provider.selectedRouteModels.map((r) => r.routeName), ['7770', '5000']);

    await tester.tap(find.text('7770'));
    await tester.pumpAndSettle();
    expect(find.text('1개 노선 선택 · 다음'), findsOneWidget);

    // 다음 → 확인 단계로 이동
    await tester.tap(find.byType(FilledButton));
    expect(provider.curIdx, 3);
  });

  testWidgets('노선 확인: 카드를 넘기면 인디케이터가 바뀌고, 저장하면 선택한 노선이 전부 저장된다', (tester) async {
    final provider = InitProvider(startIdx: InitProvider.stationStepIdx)..setSelectedStationModel(station);
    for (final r in routes) {
      provider.toggleSelectedRoute(r);
    }
    await tester.pumpWidget(MaterialApp.router(
      theme: lightTheme,
      routerConfig: GoRouter(
        initialLocation: InitSettingScreen.routeURL,
        routes: [
          GoRoute(
            name: InitSettingScreen.routeName,
            path: InitSettingScreen.routeURL,
            builder: (_, __) => ChangeNotifierProvider.value(value: provider, child: const FavoriteSettingView()),
          ),
          // 저장 후 이동하는 리스트 화면은 실제 화면 대신 빈 자리
          GoRoute(
            name: BusListScreen.routeName,
            path: BusListScreen.routeURL,
            builder: (_, __) => const Scaffold(body: Text('list')),
          ),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('3개 노선 저장하고 시작하기'), findsOneWidget);
    expect(find.text('7770'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('5000'), findsOneWidget);

    await tester.tap(find.text('3개 노선 저장하고 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('list'), findsOneWidget);

    expect(storage.loadUserModelList().map((m) => m.routeName), ['7770', '5000', '900']);
  });
}
