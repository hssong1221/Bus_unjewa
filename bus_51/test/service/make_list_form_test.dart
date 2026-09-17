import 'package:bus_51/service/bus_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('makeListForm', () {
    // 공공 API는 결과가 1건이면 Map, 여러 건이면 List로 내려주는 quirk가 있다
    final service = BusApiService();

    test('List는 그대로 반환한다', () {
      final result = service.makeListForm([
        {'a': 1},
        {'a': 2},
      ]);
      expect(result, hasLength(2));
    });

    test('단일 Map은 원소 1개짜리 List로 감싼다', () {
      final result = service.makeListForm({'a': 1});
      expect(result, hasLength(1));
      expect(result.first, {'a': 1});
    });

    test('null 등 그 외 타입은 빈 List를 반환한다', () {
      expect(service.makeListForm(null), isEmpty);
      expect(service.makeListForm('unexpected'), isEmpty);
    });
  });
}
