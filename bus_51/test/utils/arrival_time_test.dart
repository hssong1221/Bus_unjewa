import 'package:bus_51/utils/arrival_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatArrival', () {
    test('2분 미만은 "잠시 후 도착", 2분부터는 MM:SS', () {
      expect(formatArrival(0), '잠시 후 도착');
      expect(formatArrival(119), '잠시 후 도착');
      expect(formatArrival(120), '02:00');
      expect(formatArrival(332), '05:32');
    });

    test('음수는 00:00 으로, 60분 이상은 분이 세 자리로', () {
      expect(formatMmss(-5), '00:00');
      expect(formatMmss(3600), '60:00');
      expect(formatMmss(6000), '100:00');
    });
  });

  test('arrivalSeconds 는 초 단위가 비면 분 단위로 폴백한다', () {
    expect(arrivalSeconds(sec: '332', min: '5'), 332);
    expect(arrivalSeconds(sec: '', min: '5'), 300);
    expect(arrivalSeconds(sec: '', min: ''), 0);
  });
}
