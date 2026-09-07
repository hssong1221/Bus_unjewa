import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:bus_51/widget/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 정류장 ID 별로 다른 응답. 미등록은 운행 없음(null), [failingStationIds] 는 오류
class FakeBusArrivalRepository implements BusArrivalRepository {
  FakeBusArrivalRepository({this.arrivals = const {}, this.failingStationIds = const {}});

  Map<int, BusArrivalModel> arrivals;
  Set<int> failingStationIds;

  @override
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async {
    final id = int.parse(stationId);
    if (failingStationIds.contains(id)) throw ApiException(message: '서버 오류');
    return arrivals[id];
  }
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

BusArrivalModel makeArrival({required String sec, String locationNo = '3'}) => BusArrivalModel(
      predictTime1: '',
      predictTime2: '',
      predictTimeSec1: sec,
      predictTimeSec2: '',
      locationNo1: locationNo,
      locationNo2: '',
      stationNm1: '앞정류장',
      stationNm2: '',
      flag: 'PASS',
      routeDestName: '수원역',
      routeId: '1',
      stationId: '226000060',
    );

void main() {
  late StorageService storage;
  late FakeBusArrivalRepository repo;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    storage = StorageService(prefs);
    repo = FakeBusArrivalRepository();
    GetIt.I.registerSingleton<StorageService>(storage);
    GetIt.I.registerSingleton<BusArrivalRepository>(repo);
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

  /// 카운트다운 타이머가 매초 프레임을 잡아 pumpAndSettle 이 끝나지 않으므로
  /// 첫 프레임 + 응답 반영 프레임만 직접 그린다
  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump();
  }

  testWidgets('카드 오른쪽에 다음 버스 MM:SS 와 정거장 수가 보이고 1초마다 줄어든다', (tester) async {
    await storage.addUserSaveModel(makeUser(1, '51'));
    repo.arrivals = {1: makeArrival(sec: '332', locationNo: '3')};
    await pumpList(tester);

    expect(find.text('05:32'), findsOneWidget);
    expect(find.text('3정거장 전'), findsOneWidget);
    // 상세로 들어가는 화살표는 시간에 자리를 내주고 없앴다
    expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('05:31'), findsOneWidget);
  });

  testWidgets('2분 미만이면 숫자 대신 "잠시 후 도착"', (tester) async {
    await storage.addUserSaveModel(makeUser(1, '51'));
    repo.arrivals = {1: makeArrival(sec: '119', locationNo: '1')};
    await pumpList(tester);

    expect(find.text('잠시 후 도착'), findsOneWidget);
    expect(find.text('01:59'), findsNothing);
    expect(find.text('1정거장 전'), findsOneWidget);
  });

  testWidgets('운행 없음·오류는 카드별로 독립이고, 다시 시도는 그 카드만 다시 조회한다', (tester) async {
    await storage.addUserSaveModel(makeUser(1, '51'));
    await storage.addUserSaveModel(makeUser(2, '7770'));
    await storage.addUserSaveModel(makeUser(3, '900'));
    repo.arrivals = {1: makeArrival(sec: '332')};
    repo.failingStationIds = {2};
    await pumpList(tester);

    expect(find.text('05:32'), findsOneWidget);
    expect(find.text('불러오지 못함'), findsOneWidget);
    expect(find.text('운행 없음'), findsOneWidget);

    // 서버 복구 후 다시 시도
    repo.failingStationIds = {};
    repo.arrivals = {...repo.arrivals, 2: makeArrival(sec: '600', locationNo: '7')};
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    await tester.pump();

    expect(find.text('불러오지 못함'), findsNothing);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('7정거장 전'), findsOneWidget);
  });

  testWidgets('편집(선택) 모드에서는 시간 대신 순서 변경 손잡이가 보인다', (tester) async {
    await storage.addUserSaveModel(makeUser(1, '51'));
    repo.arrivals = {1: makeArrival(sec: '332')};
    await pumpList(tester);
    expect(find.text('05:32'), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle_rounded), findsNothing);

    await tester.tap(find.text('편집'));
    await tester.pump();

    expect(find.text('05:32'), findsNothing);
    expect(find.byIcon(Icons.drag_handle_rounded), findsOneWidget);
    expect(find.text('0개 선택됨'), findsOneWidget);
  });

  testWidgets('카드 하나를 삭제해도 남은 카드의 도착 시간은 그대로다', (tester) async {
    await storage.addUserSaveModel(makeUser(1, '51'));
    await storage.addUserSaveModel(makeUser(2, '7770'));
    repo.arrivals = {1: makeArrival(sec: '332'), 2: makeArrival(sec: '600')};
    await pumpList(tester);
    expect(find.text('05:32'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);

    // 편집 → 7770 선택 → 선택 삭제 → 확인
    await tester.tap(find.text('편집'));
    await tester.pump();
    await tester.tap(find.text('7770'));
    await tester.pump();
    await tester.tap(find.text('선택 삭제 (1)'));
    await tester.pump();
    await tester.tap(find.text('삭제'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('7770'), findsNothing);
    // 저장소를 다시 읽어 인스턴스가 바뀌어도 51번 카드는 스켈레톤으로 돌아가지 않는다
    expect(find.text('05:32'), findsOneWidget);
  });

  testWidgets('편집 모드에서 손잡이를 끌어 순서를 바꾸면 저장 순서도 바뀐다', (tester) async {
    await storage.addUserSaveModel(makeUser(1, '51'));
    await storage.addUserSaveModel(makeUser(2, '7770'));
    await storage.addUserSaveModel(makeUser(3, '900'));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();

    // 첫 카드(51)의 손잡이를 카드 두 장 높이만큼 조금씩 아래로 끈다
    final firstHandle = find.byIcon(Icons.drag_handle_rounded).first;
    final cardHeight = tester.getSize(find.byType(AppCard).first).height + 12;
    final gesture = await tester.startGesture(tester.getCenter(firstHandle));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(0, cardHeight * 2 / 10));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(storage.loadUserModelList().map((m) => m.routeName), ['7770', '900', '51']);
  });
}
