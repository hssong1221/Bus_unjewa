import 'package:bus_51/enums/bus_enums.dart';
import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
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

UserSaveModel makeUser() => const UserSaveModel(
      routeName: '51',
      stationId: 226000060,
      routeId: 208000017,
      staOrder: 1,
      routeTypeCd: 13,
      busType: BusType.none,
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
      final vm = BusMainViewModel(
        FakeBusArrivalRepository(),
        savedBuses: [],
        index: 0,
      );

      await vm.init();

      expect(vm.userModel, isNull);
      expect(vm.state, isA<BusMainError>());
    });

    test('조회 성공 시 Success 상태 + 카운트다운 초기값 세팅', () async {
      final repo = FakeBusArrivalRepository(arrival: makeArrival(sec1: '120', sec2: '300'));
      final vm = BusMainViewModel(repo, savedBuses: [makeUser()], index: 0);

      await vm.init();

      expect(vm.state, isA<BusMainSuccess>());
      expect((vm.state as BusMainSuccess).arrival.routeId, '208000017');
      expect(vm.remainingSeconds1, 120);
      expect(vm.remainingSeconds2, 300);
      vm.dispose();
    });

    test('도착 정보가 없으면(null) 미운행 상태가 된다', () async {
      final vm = BusMainViewModel(
        FakeBusArrivalRepository(arrival: null),
        savedBuses: [makeUser()],
        index: 0,
      );

      await vm.init();

      expect(vm.state, isA<BusMainNotOperating>());
      expect(vm.remainingSeconds1, 0);
      vm.dispose();
    });

    test('ApiException 발생 시 에러 상태 + 메시지 노출', () async {
      final vm = BusMainViewModel(
        FakeBusArrivalRepository(exception: ApiException(message: '서버 오류')),
        savedBuses: [makeUser()],
        index: 0,
      );

      await vm.init();

      expect(vm.state, isA<BusMainError>());
      expect((vm.state as BusMainError).message, '서버 오류');
      vm.dispose();
    });

    test('에러 후 refresh 성공 시 Success 상태로 복구된다', () async {
      final repo = FakeBusArrivalRepository(exception: ApiException(message: '서버 오류'));
      final vm = BusMainViewModel(repo, savedBuses: [makeUser()], index: 0);
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
        final vm = BusMainViewModel(repo, savedBuses: [makeUser()], index: 0);

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
        final vm = BusMainViewModel(repo, savedBuses: [makeUser()], index: 0);

        vm.init();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 10));
        expect(vm.remainingSeconds1, 0);
        expect(vm.remainingSeconds2, 0);

        vm.dispose();
      });
    });
  });
}
