import 'package:bus_51/tracking/bus_tracking_target.dart';
import 'package:flutter_test/flutter_test.dart';

const target = BusTrackingTarget(
  stationId: 226000060,
  routeId: 208000017,
  staOrder: 15,
  routeName: '51',
  plateNo: '경기71바1146',
  remainingSeconds: 1800,
);

void main() {
  group('BusTrackingTarget', () {
    test('JSON 문자열로 저장했다 읽어도 같은 값이다 (서비스 isolate 에 넘기는 경로)', () {
      expect(BusTrackingTarget.decode(target.encode()), target);
    });

    test('정류장·노선·순번이 전부 같아야 같은 버스다', () {
      expect(target.isSameBus(stationId: 226000060, routeId: 208000017, staOrder: 15), isTrue);
      expect(target.isSameBus(stationId: 226000060, routeId: 208000017, staOrder: 16), isFalse);
      expect(target.isSameBus(stationId: 226000060, routeId: 1, staOrder: 15), isFalse);
    });
  });
}
