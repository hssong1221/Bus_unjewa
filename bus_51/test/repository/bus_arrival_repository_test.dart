import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/service/bus_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBusApiService implements BusApiService {
  FakeBusApiService(this.arrival);

  final BusArrivalModel? arrival;

  @override
  Future<BusArrivalModel?> getBusArrivalTimeList({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async =>
      arrival;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// 운행 시간 외에 공공 API가 실제로 돌려주는 모양:
/// resultCode 0, flag "PASS" 인데 예측 시간·위치·차량 필드가 전부 ""
const emptyArrival = BusArrivalModel(
  predictTime1: '',
  predictTime2: '',
  predictTimeSec1: '',
  predictTimeSec2: '',
  locationNo1: '',
  locationNo2: '',
  stationNm1: '',
  stationNm2: '',
  flag: 'PASS',
  routeDestName: '덕장중학교',
  routeId: '226000036',
  stationId: '226000060',
);

const runningArrival = BusArrivalModel(
  predictTime1: '3',
  predictTime2: '10',
  predictTimeSec1: '211',
  predictTimeSec2: '617',
  locationNo1: '3',
  locationNo2: '8',
  stationNm1: '의왕국민체육센터',
  stationNm2: '농수산물시장',
  flag: 'PASS',
  routeDestName: '구로디지털단지역',
  routeId: '208000017',
  stationId: '226000060',
);

Future<BusArrivalModel?> fetch(BusArrivalModel? fromApi) =>
    BusArrivalRepository(FakeBusApiService(fromApi)).getArrival(stationId: '1', routeId: '2', staOrder: '3');

void main() {
  group('BusArrivalRepository.getArrival', () {
    test('API가 null(resultCode 4)이면 null', () async {
      expect(await fetch(null), isNull);
    });

    test('응답은 정상이지만 도착 예정 차량이 없는 빈 항목이면 null (운행 없음 화면으로)', () async {
      expect(await fetch(emptyArrival), isNull);
    });

    test('첫 번째 버스 정보가 있으면 그대로 돌려준다', () async {
      expect(await fetch(runningArrival), runningArrival);
    });
  });

  group('BusArrivalModel.hasBus', () {
    test('빈 항목은 두 버스 모두 없음', () {
      expect(emptyArrival.hasBus1, isFalse);
      expect(emptyArrival.hasBus2, isFalse);
    });

    test('차량이 한 대만 운행 중이면 hasBus2 만 false', () {
      const oneBus = BusArrivalModel(
        predictTime1: '3',
        predictTime2: '',
        predictTimeSec1: '211',
        predictTimeSec2: '',
        locationNo1: '3',
        locationNo2: '',
        stationNm1: '의왕국민체육센터',
        stationNm2: '',
        flag: 'PASS',
        routeDestName: '구로디지털단지역',
        routeId: '208000017',
        stationId: '226000060',
      );
      expect(oneBus.hasBus1, isTrue);
      expect(oneBus.hasBus2, isFalse);
    });
  });
}
