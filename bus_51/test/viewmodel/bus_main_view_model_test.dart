import 'dart:async';

import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/tracking/bus_tracking_service.dart';
import 'package:bus_51/tracking/bus_tracking_target.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:bus_51/viewmodel/bus_main_view_model.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tracking/fake_bus_tracking_service.dart';

class FakeBusArrivalRepository implements BusArrivalRepository {
  FakeBusArrivalRepository({this.arrival, this.exception});

  BusArrivalModel? arrival;
  ApiException? exception;
  int callCount = 0;

  /// 설정하면 이 Completer 가 완료될 때까지 응답을 붙잡는다 (요청 진행 중 상태를 만들 때)
  Completer<void>? gate;

  @override
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async {
    callCount++;
    if (gate != null) await gate!.future;
    if (exception != null) throw exception!;
    return arrival;
  }

  /// 정류장 단위 조회는 리스트 화면용이라 상세 VM 은 부르지 않는다
  @override
  Future<List<BusArrivalModel>> getArrivalsAtStation({required String stationId}) => throw UnimplementedError();
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
  BusTrackingService? tracking,
  List<UserSaveModel>? savedBuses,
  int index = 0,
}) =>
    BusMainViewModel(
      arrivalRepository,
      routeStationRepository ?? FakeBusRouteStationRepository(),
      tracking ?? FakeBusTrackingService(),
      savedBuses: savedBuses ?? [makeUser()],
      index: index,
    );

BusArrivalModel makeArrival({String sec1 = '120', String sec2 = '300', String plateNo1 = ''}) => BusArrivalModel(
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
      plateNo1: plateNo1,
    );

/// makeUser() 의 버스를 추적 중인 상태
const BusTrackingTarget trackingThisBus = BusTrackingTarget(
  stationId: 226000060,
  routeId: 208000017,
  staOrder: 3,
  routeName: '51',
  plateNo: '경기71바1146',
  remainingSeconds: 600,
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

    test('pause 하면 갱신·카운트다운이 멈추고 resume 하면 바로 다시 조회한다', () {
      fakeAsync((async) {
        final repo = FakeBusArrivalRepository(arrival: makeArrival(sec1: '300', sec2: '600'));
        final vm = makeViewModel(repo);

        vm.init();
        async.flushMicrotasks();
        expect(repo.callCount, 1);
        vm.pause();

        // 백그라운드 3분: 60초 갱신도 1초 카운트다운도 돌지 않는다
        async.elapse(const Duration(minutes: 3));
        expect(repo.callCount, 1);
        expect(vm.remainingSeconds1, 300);

        vm.resume();
        async.flushMicrotasks();
        expect(repo.callCount, 2);
        async.elapse(const Duration(seconds: 1));
        expect(vm.remainingSeconds1, 299);
        async.elapse(const Duration(seconds: 59));
        expect(repo.callCount, 3);

        vm.dispose();
      });
    });

    test('첫 응답을 기다리는 사이 pause 되면 자동 갱신 타이머가 남지 않는다', () {
      fakeAsync((async) {
        final repo = FakeBusArrivalRepository(arrival: makeArrival())..gate = Completer<void>();
        final vm = makeViewModel(repo);

        vm.init();
        async.flushMicrotasks();
        expect(repo.callCount, 1);
        vm.pause(); // 화면을 열자마자 백그라운드로

        repo.gate!.complete();
        async.flushMicrotasks();
        expect(vm.state, isA<BusMainSuccess>());

        async.elapse(const Duration(minutes: 3));
        expect(repo.callCount, 1);

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

  group('도착 알림', () {
    late FakeBusTrackingService tracking;

    setUp(() => tracking = FakeBusTrackingService());

    test('켜면 권한을 확인한 뒤 지금 보는 버스·차량번호·남은 초로 추적을 시작하고 리스너에게 알린다', () async {
      final vm = makeViewModel(
        FakeBusArrivalRepository(arrival: makeArrival(sec1: '600', plateNo1: '경기71바1146')),
        tracking: tracking,
      );
      await vm.init();
      var notified = 0;
      vm.addListener(() => notified++);

      expect(vm.alarmEnabled, isFalse);
      expect(await vm.toggleAlarm(), AlarmToggleResult.enabled);

      expect(vm.alarmEnabled, isTrue);
      expect(notified, 1);
      expect(tracking.started, [trackingThisBus]);
      vm.dispose();
    });

    test('끄면 추적을 중지한다', () async {
      final vm = makeViewModel(FakeBusArrivalRepository(arrival: makeArrival(sec1: '600')), tracking: tracking);
      await vm.init();
      await vm.toggleAlarm();

      expect(await vm.toggleAlarm(), AlarmToggleResult.disabled);

      expect(vm.alarmEnabled, isFalse);
      expect(tracking.stopCount, 1);
      vm.dispose();
    });

    test('알림을 받을 수 없으면 needsPermission 이고 추적을 시작하지 않는다', () async {
      tracking.notificationsAllowed = false;
      final vm = makeViewModel(FakeBusArrivalRepository(arrival: makeArrival(sec1: '600')), tracking: tracking);
      await vm.init();

      expect(await vm.toggleAlarm(), AlarmToggleResult.needsPermission);

      expect(vm.alarmEnabled, isFalse);
      expect(tracking.started, isEmpty);
      vm.dispose();
    });

    test('서비스가 뜨지 못하면 failed 이고 꺼진 채로 남는다', () async {
      tracking.startSucceeds = false;
      final vm = makeViewModel(FakeBusArrivalRepository(arrival: makeArrival(sec1: '600')), tracking: tracking);
      await vm.init();

      expect(await vm.toggleAlarm(), AlarmToggleResult.failed);

      expect(vm.alarmEnabled, isFalse);
      vm.dispose();
    });

    test('남은 시간이 1분 미만이면 켤 수 없다', () async {
      final vm = makeViewModel(FakeBusArrivalRepository(arrival: makeArrival(sec1: '59')), tracking: tracking);
      await vm.init();
      var notified = 0;
      vm.addListener(() => notified++);

      expect(vm.canToggleAlarm, isFalse);
      expect(await vm.toggleAlarm(), AlarmToggleResult.failed);
      expect(vm.alarmEnabled, isFalse);
      expect(tracking.started, isEmpty);
      expect(notified, 0);
      vm.dispose();
    });

    test('켜져 있으면 1분 미만이 되어도 끌 수는 있다', () {
      fakeAsync((async) {
        final vm = makeViewModel(FakeBusArrivalRepository(arrival: makeArrival(sec1: '61')), tracking: tracking);
        vm.init();
        async.flushMicrotasks();
        vm.toggleAlarm();
        async.flushMicrotasks();
        expect(vm.alarmEnabled, isTrue);

        async.elapse(const Duration(seconds: 5));
        expect(vm.remainingSeconds1, 56);
        expect(vm.canToggleAlarm, isTrue);
        vm.toggleAlarm();
        async.flushMicrotasks();
        expect(vm.alarmEnabled, isFalse);
        expect(vm.canToggleAlarm, isFalse);
        vm.dispose();
      });
    });

    test('화면에 들어올 때 이 버스를 추적 중이면 켜진 상태로 시작한다', () async {
      tracking.running = trackingThisBus;
      final vm = makeViewModel(FakeBusArrivalRepository(arrival: makeArrival()), tracking: tracking);

      await vm.init();

      expect(vm.alarmEnabled, isTrue);
      vm.dispose();
    });

    test('다른 버스를 추적 중이면 이 화면에서는 꺼진 상태다', () async {
      tracking.running = const BusTrackingTarget(
        stationId: 226000060,
        routeId: 208000017,
        staOrder: 9,
        routeName: '51',
        plateNo: '경기71바1146',
        remainingSeconds: 600,
      );
      final vm = makeViewModel(FakeBusArrivalRepository(arrival: makeArrival()), tracking: tracking);

      await vm.init();

      expect(vm.alarmEnabled, isFalse);
      vm.dispose();
    });

    test('다른 버스를 추적 중일 때 켜면 stop 없이 start 만 불러 그 버스로 교체한다 (교체는 파사드의 일)', () async {
      const otherBus = BusTrackingTarget(
        stationId: 226000060,
        routeId: 208000017,
        staOrder: 9,
        routeName: '51',
        plateNo: '경기71바1146',
        remainingSeconds: 600,
      );
      tracking.running = otherBus;
      final vm = makeViewModel(
        FakeBusArrivalRepository(arrival: makeArrival(sec1: '600', plateNo1: '경기71바1146')),
        tracking: tracking,
      );
      await vm.init();
      expect(vm.alarmEnabled, isFalse);

      expect(await vm.toggleAlarm(), AlarmToggleResult.enabled);

      expect(vm.alarmEnabled, isTrue);
      expect(tracking.stopCount, 0);
      expect(tracking.started, [trackingThisBus]);
      expect(tracking.running, trackingThisBus);
      vm.dispose();
    });

    test('서비스가 스스로 끝나면(도착·차량 변경·알림의 끄기) 꺼진 상태로 바뀌고 리스너에게 알린다', () async {
      final vm = makeViewModel(FakeBusArrivalRepository(arrival: makeArrival(sec1: '600')), tracking: tracking);
      await vm.init();
      await vm.toggleAlarm();
      var notified = 0;
      vm.addListener(() => notified++);

      tracking.finish();
      await Future<void>.delayed(Duration.zero);

      expect(vm.alarmEnabled, isFalse);
      expect(notified, 1);
      vm.dispose();
    });
  });
}
