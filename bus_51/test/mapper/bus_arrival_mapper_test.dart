import 'package:bus_51/entity/bus_arrival_entity.dart';
import 'package:bus_51/mapper/bus_arrival_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2026-09-07 getBusArrivalListv2 실제 응답(정류장 226000060)에서 두 항목을 그대로 가져온 샘플.
/// 숫자 필드는 int 로, 운행 없는 노선은 "" 로 오는 타입 혼재가 그대로 담겨 있다
const runningItemJson = <String, dynamic>{
  "crowded1": 1, "crowded2": 1, "flag": "PASS", "locationNo1": 7, "locationNo2": 12,
  "lowPlate1": 1, "lowPlate2": 0, "plateNo1": "경기71바1146", "plateNo2": "경기71바1040",
  "predictTime1": 9, "predictTime2": 18, "remainSeatCnt1": 0, "remainSeatCnt2": 0,
  "routeDestId": 120000674, "routeDestName": "구로디지털단지역(중)", "routeId": 208000017,
  "routeName": 51, "routeTypeCd": 13, "staOrder": 15, "stationId": 226000060,
  "stationNm1": "대원아파트", "stationNm2": "동안고등학교정문", "taglessCd1": 0, "taglessCd2": 0,
  "turnSeq": 51, "vehId1": 208000397, "vehId2": 208000291,
  "predictTimeSec1": 576, "predictTimeSec2": 1157, "stateCd1": 2, "stateCd2": 2,
};

const idleItemJson = <String, dynamic>{
  "crowded1": "", "crowded2": "", "flag": "PASS", "locationNo1": "", "locationNo2": "",
  "lowPlate1": "", "lowPlate2": "", "plateNo1": "", "plateNo2": "", "predictTime1": "",
  "predictTime2": "", "remainSeatCnt1": "", "remainSeatCnt2": "", "routeDestId": 226000213,
  "routeDestName": "덕장중학교", "routeId": 226000036, "routeName": "통학1(등교)",
  "routeTypeCd": 13, "staOrder": 16, "stationId": 226000060, "stationNm1": "", "stationNm2": "",
  "taglessCd1": "", "taglessCd2": "", "turnSeq": 19, "vehId1": "", "vehId2": "",
};

void main() {
  group('BusArrivalMapper (정류장 단위 응답 샘플)', () {
    test('숫자로 오는 routeId·staOrder 가 문자열로 매핑되어 저장 노선과 비교할 수 있다', () {
      final model = BusArrivalMapper.fromEntity(BusArrivalEntity.fromJson(runningItemJson));

      expect(model.routeId, '208000017');
      expect(model.staOrder, '15');
      expect(model.predictTimeSec1, '576');
      expect(model.hasBus1, isTrue);
    });

    test('운행 차량이 없는 노선 항목은 hasBus1 이 false 다', () {
      final model = BusArrivalMapper.fromEntity(BusArrivalEntity.fromJson(idleItemJson));

      expect(model.staOrder, '16');
      expect(model.hasBus1, isFalse);
    });

    test('첫 번째 버스 차량번호(plateNo1)가 모델까지 전달된다 (도착 알림이 같은 차인지 판정하는 데 쓴다)', () {
      final running = BusArrivalMapper.fromEntity(BusArrivalEntity.fromJson(runningItemJson));
      final idle = BusArrivalMapper.fromEntity(BusArrivalEntity.fromJson(idleItemJson));

      expect(running.plateNo1, '경기71바1146');
      expect(idle.plateNo1, '');
    });

    test('목록 응답에만 있는 stateCd 같은 모르는 필드는 무시된다', () {
      expect(() => BusArrivalEntity.fromJson(runningItemJson), returnsNormally);
    });
  });
}
