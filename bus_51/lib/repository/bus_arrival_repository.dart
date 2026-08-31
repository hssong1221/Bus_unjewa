import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/service/bus_api_service.dart';

// --------------------------------------------------
// 버스 도착 정보 Repository
// ViewModel(UI 계층)과 ApiService(데이터 소스) 사이의 데이터 계층.
// 자체 서버 <-> 공공 API 전환, 폴백 같은 데이터 소스 선택 로직이
// 생기면 이 계층에 들어간다.
// --------------------------------------------------
class BusArrivalRepository {
  BusArrivalRepository(this._apiService);

  final BusApiService _apiService;

  /// 정류장 + 노선 + 정류장 순번에 대한 실시간 도착 정보 조회
  ///
  /// - null 반환: 운행 중인 버스 없음
  ///   (API resultCode 4 / 데이터 없음, 또는 응답은 정상이지만 도착 예정 차량이 없는 빈 항목)
  /// - [ApiException] throw: 네트워크/API 오류
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) async {
    final arrival = await _apiService.getBusArrivalTimeList(
      stationId: stationId,
      routeId: routeId,
      staOrder: staOrder,
    );
    // 운행 시간 외에는 resultCode 0 으로 필드가 전부 "" 인 항목이 오므로 여기서 걸러낸다
    if (arrival == null || !arrival.hasBus1) return null;
    return arrival;
  }
}
