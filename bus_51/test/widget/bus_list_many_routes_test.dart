import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 도착 정보는 이 테스트의 관심사가 아니라 전부 운행 없음으로 돌려준다 (카운트다운이 없어 pumpAndSettle 을 쓸 수 있다)
class NullBusArrivalRepository implements BusArrivalRepository {
  @override
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async => null;

  @override
  Future<List<BusArrivalModel>> getArrivalsAtStation({required String stationId}) async => const [];
}

UserSaveModel makeUser(int stationId, String routeName) => UserSaveModel(
      stationId: stationId,
      stationName: '정류장$stationId',
      routeId: 1,
      routeName: routeName,
      routeTypeCd: 13,
      routeDestName: '수원역',
      staOrder: 3,
    );

void main() {
  late StorageService storage;

  /// 한 화면에 다 들어가지 않을 만큼 많은 노선
  const routeCount = 30;
  final routeNames = [for (var i = 1; i <= routeCount; i++) 'R$i'];

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    storage = StorageService(prefs);
    GetIt.I.registerSingleton<StorageService>(storage);
    GetIt.I.registerSingleton<BusArrivalRepository>(NullBusArrivalRepository());
    for (var i = 0; i < routeCount; i++) {
      await storage.addUserSaveModel(makeUser(i + 1, routeNames[i]));
    }
  });

  tearDown(() async => GetIt.I.reset());

  Widget buildApp() => MaterialApp.router(
        theme: lightTheme,
        routerConfig: GoRouter(
          initialLocation: BusListScreen.routeURL,
          routes: [
            GoRoute(
              name: BusListScreen.routeName,
              path: BusListScreen.routeURL,
              builder: (_, __) => const BusListScreen(),
            ),
          ],
        ),
      );

  /// 휴대폰 세로 화면(360 x 780)에서 리스트를 열고 편집 모드로 들어간다
  Future<void> openEditMode(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();
  }

  final editList = find.byType(Scrollable).first;

  testWidgets('노선이 많아도 편집 화면 목록은 끝까지 스크롤되고 삭제 바는 화면 안에 있다', (tester) async {
    await openEditMode(tester);

    expect(find.text('전체 삭제').hitTestable(), findsOneWidget);
    expect(find.text('선택 삭제 (0)').hitTestable(), findsOneWidget);

    await tester.scrollUntilVisible(find.text(routeNames.last), 200, scrollable: editList);
    expect(find.text(routeNames.last).hitTestable(), findsOneWidget);
  });

  testWidgets('노선을 많이 골라도 선택 삭제 확인창이 화면을 넘지 않고 노선 목록만 스크롤된다', (tester) async {
    await openEditMode(tester);

    for (final name in routeNames) {
      await tester.scrollUntilVisible(find.text(name), 200, scrollable: editList);
      await tester.pumpAndSettle();
      await tester.tap(find.text(name));
      await tester.pump();
    }
    expect(find.text('$routeCount개 선택됨'), findsOneWidget);

    await tester.tap(find.text('선택 삭제 ($routeCount)'));
    await tester.pumpAndSettle();

    // 질문·되돌릴 수 없음 안내·버튼은 스크롤하지 않아도 보인다
    expect(find.text('선택한 $routeCount개의 노선을 삭제하시겠습니까?').hitTestable(), findsOneWidget);
    expect(find.text('이 작업은 실행 취소할 수 없습니다.').hitTestable(), findsOneWidget);
    expect(find.text('취소').hitTestable(), findsOneWidget);
    expect(find.text('삭제').hitTestable(), findsOneWidget);

    // 마지막 노선까지 확인창 안에서 스크롤해 볼 수 있다
    final dialogList = find.descendant(of: find.byType(AlertDialog), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('• ${routeNames.last}'), 100, scrollable: dialogList);
    expect(find.text('• ${routeNames.last}').hitTestable(), findsOneWidget);
  });
}
