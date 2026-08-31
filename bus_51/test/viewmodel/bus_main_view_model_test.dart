import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:bus_51/viewmodel/bus_main_view_model.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBusArrivalRepository implements BusArrivalRepository {
  FakeBusArrivalRepository({this.arrival, this.exception});

  BusArrivalModel? arrival;
  ApiException? exception;
  int callCount = 0;

  @override
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async {
    callCount++;
    if (exception != null) throw exception!;
    return arrival;
  }
}

class FakeBusRouteStationRepository implements BusRouteStationRepository {
  FakeBusRouteStationRepository({this.stations = const [], this.exception});

  List<BusRouteStationModel> stations;
  ApiException? exception;
  int callCount = 0;

  @override
  Future<List<BusRouteStationModel>> getStationsOnRoute({required String routeId}) async {
    callCount++;
    if (exception != null) throw exception!;
    return stations;
  }
}

/// staOrder(=탑승 정류장의 stationSeq) 기본값은 3
UserSaveModel makeUser({int staOrder = 3}) => UserSaveModel(
      routeName: '51',
      stationId: 226000060,
      routeId: 208000017,
      staOrder: staOrder,
      routeTypeCd: 13,
      stationName: '정류장$staOrder',
      routeDestName: '수원역',
    );

BusRouteStationModel makeRouteStation(int seq) => BusRouteStationModel(
      centerYn: 'N',
      districtCd: '1',
      mobileNo: '0$seq',
      regionName: '수원',
      stationId: '22600006$seq',
      stationName: '정류장$seq',
      x: '127.0',
      y: '37.0',
      adminName: '수원시',
      stationSeq: '$seq',
      turnSeq: '10',
      turnYn: 'N',
    );

List<BusRouteStationModel> makeRouteStations(int count) =>
    [for (int i = 1; i <= count; i++) makeRouteStation(i)];

/// 테스트에서 반복되는 VM 생성. 타임라인을 쓰지 않는 테스트는 두 번째 인자를 생략한다
BusMainViewModel makeViewModel(
  BusArrivalRepository arrivalRepository, {
  BusRouteStationRepository? routeStationRepository,
  List<UserSaveModel>? savedBuses,
  int index = 0,
}) =>
    BusMainViewModel(
      arrivalRepository,
      routeStationRepository ?? FakeBusRouteStationRepository(),
      savedBuses: savedBuses ?? [makeUser()],
      index: index,
    );

BusArrivalModel makeArrival({String sec1 = '120', String sec2 = '300'}) => BusArrivalModel(
      predictTime1: '2',
      predictTime2: '5',
      predictTimeSec1: sec1,
      predictTimeSec2: sec2,
      locationNo1: '3',
      locationNo2: '8',
      stationNm1: '앞정류장',
      stationNm2: '뒷정류장',
      flag: 'PASS',
      routeDestName: '종점',
      routeId: '208000017',
      stationId: '226000060',
    );

void main() {
  group('BusMainViewModel', () {
    test('저장된 버스가 없으면(인덱스 범위 밖) 크래시 대신 에러 상태가 된다', () async {
      final vm = makeViewModel(FakeBusArrivalRepository(), savedBuses: []);

      await vm.init();

      expect(vm.userModel, isNull);
      expect(vm.state, isA<BusMainError>());
    });

    test('조회 성공 시 Success 상태 + 카운트다운 초기값 세팅', () async {
      final repo = FakeBusArrivalRepository(arrival: makeArrival(sec1: '120', sec2: '300'));
      final vm = makeViewModel(repo);

      await vm.init();

      expect(vm.state, isA<BusMainSuccess>());
      expect((vm.state as BusMainSuccess).arrival.routeId, '208000017');
      expect(vm.remainingSeconds1, 120);
      expect(vm.remainingSeconds2, 300);
      vm.dispose();
    });

    test('predictTimeSec 가 비어 오면 predictTime(분)으로 카운트다운을 시작한다', () async {
      // 공공 API 응답에 초 단위 필드가 빠져 오는 경우 — 00:00 으로 보이면 안 된다
      final repo = FakeBusArrivalRepository(arrival: makeArrival(sec1: '', sec2: ''));
      final vm = makeViewModel(repo);

      await vm.init();

      expect(vm.remainingSeconds1, 2 * 60);
      expect(vm.remainingSeconds2, 5 * 60);
      vm.dispose();
    });

    test('도착 정보가 없으면(null) 미운행 상태가 된다', () async {
      final vm = makeViewModel(FakeBusArrivalRepository(arrival: null));

      await vm.init();

      expect(vm.state, isA<BusMainNotOperating>());
      expect(vm.remainingSeconds1, 0);
      vm.dispose();
    });

    test('ApiException 발생 시 에러 상태 + 메시지 노출', () async {
      final vm = makeViewModel(FakeBusArrivalRepository(exception: ApiException(message: '서버 오류')));

      await vm.init();

      expect(vm.state, isA<BusMainError>());
      expect((vm.state as BusMainError).message, '서버 오류');
      vm.dispose();
    });

    test('에러 후 refresh 성공 시 Success 상태로 복구된다', () async {
      final repo = FakeBusArrivalRepository(exception: ApiException(message: '서버 오류'));
      final vm = makeViewModel(repo);
      await vm.init();
      expect(vm.state, isA<BusMainError>());

      repo.exception = null;
      repo.arrival = makeArrival();
      await vm.refresh();

      expect(vm.state, isA<BusMainSuccess>());
      vm.dispose();
    });

    test('카운트다운은 1초마다 감소하고 60초마다 재조회한다', () {
      fakeAsync((async) {
        final repo = FakeBusArrivalRepository(arrival: makeArrival(sec1: '120', sec2: '300'));
        final vm = makeViewModel(repo);

        vm.init();
        async.flushMicrotasks();
        expect(vm.remainingSeconds1, 120);
        expect(repo.callCount, 1);

        async.elapse(const Duration(seconds: 1));
        expect(vm.remainingSeconds1, 119);
        expect(vm.remainingSeconds2, 299);

        async.elapse(const Duration(seconds: 59));
        expect(repo.callCount, 2);

        vm.dispose();
      });
    });

    test('카운트다운은 0 밑으로 내려가지 않는다', () {
      fakeAsync((async) {
        final repo = FakeBusArrivalRepository(arrival: makeArrival(sec1: '2', sec2: '3'));
        final vm = makeViewModel(repo);

        vm.init();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 10));
        expect(vm.remainingSeconds1, 0);
        expect(vm.remainingSeconds2, 0);

        vm.dispose();
      });
    });
  });

  group('BusMainViewModel 전체 노선 타임라인', () {
    test('조회 성공 시 정류장 목록과 탑승 정류장 인덱스를 계산한다', () async {
      final routeRepo = FakeBusRouteStationRepository(stations: makeRouteStations(5));
      final vm = makeViewModel(
        FakeBusArrivalRepository(),
        routeStationRepository: routeRepo,
        savedBuses: [makeUser(staOrder: 3)],
      );

      await vm.loadTimeline();

      final state = vm.timelineState;
      expect(state, isA<BusTimelineSuccess>());
      expect((state as BusTimelineSuccess).stations, hasLength(5));
      // staOrder 3 = stationSeq '3' = 리스트 인덱스 2
      expect(state.currentIndex, 2);
    });

    test('탑승 정류장을 찾지 못하면 인덱스가 -1이다', () async {
      final routeRepo = FakeBusRouteStationRepository(stations: makeRouteStations(3));
      final vm = makeViewModel(
        FakeBusArrivalRepository(),
        routeStationRepository: routeRepo,
        savedBuses: [makeUser(staOrder: 99)],
      );

      await vm.loadTimeline();

      expect((vm.timelineState as BusTimelineSuccess).currentIndex, -1);
    });

    test('한 번 성공하면 다시 조회하지 않는다', () async {
      final routeRepo = FakeBusRouteStationRepository(stations: makeRouteStations(3));
      final vm = makeViewModel(FakeBusArrivalRepository(), routeStationRepository: routeRepo);

      await vm.loadTimeline();
      await vm.loadTimeline();
      await vm.loadTimeline();

      expect(routeRepo.callCount, 1);
    });

    test('조회 중 재호출해도 요청은 한 번만 나간다', () async {
      final routeRepo = FakeBusRouteStationRepository(stations: makeRouteStations(3));
      final vm = makeViewModel(FakeBusArrivalRepository(), routeStationRepository: routeRepo);

      await Future.wait([vm.loadTimeline(), vm.loadTimeline()]);

      expect(routeRepo.callCount, 1);
      expect(vm.timelineState, isA<BusTimelineSuccess>());
    });

    test('ApiException 발생 시 에러 상태 + 메시지 노출', () async {
      final routeRepo = FakeBusRouteStationRepository(exception: ApiException(message: '노선 서버 오류'));
      final vm = makeViewModel(FakeBusArrivalRepository(), routeStationRepository: routeRepo);

      await vm.loadTimeline();

      expect(vm.timelineState, isA<BusTimelineError>());
      expect((vm.timelineState as BusTimelineError).message, '노선 서버 오류');
    });

    test('정류장이 비어 있으면 에러 상태가 된다', () async {
      final routeRepo = FakeBusRouteStationRepository(stations: []);
      final vm = makeViewModel(FakeBusArrivalRepository(), routeStationRepository: routeRepo);

      await vm.loadTimeline();

      expect(vm.timelineState, isA<BusTimelineError>());
    });

    test('실패 후 다시 펼치면 재조회한다', () async {
      final routeRepo = FakeBusRouteStationRepository(exception: ApiException(message: '노선 서버 오류'));
      final vm = makeViewModel(FakeBusArrivalRepository(), routeStationRepository: routeRepo);

      await vm.loadTimeline();
      expect(vm.timelineState, isA<BusTimelineError>());

      routeRepo.exception = null;
      routeRepo.stations = makeRouteStations(3);
      await vm.loadTimeline();

      expect(vm.timelineState, isA<BusTimelineSuccess>());
      expect(routeRepo.callCount, 2);
    });

    test('저장된 버스가 없으면 조회하지 않는다', () async {
      final routeRepo = FakeBusRouteStationRepository(stations: makeRouteStations(3));
      final vm = makeViewModel(
        FakeBusArrivalRepository(),
        routeStationRepository: routeRepo,
        savedBuses: [],
      );

      await vm.loadTimeline();

      expect(routeRepo.callCount, 0);
      expect(vm.timelineState, isA<BusTimelineLoading>());
    });
  });
}
