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
  /// - null 반환: 운행 중인 버스 없음 (API resultCode 4, 데이터 없음)
  /// - [ApiException] throw: 네트워크/API 오류
  Future<BusArrivalModel?> getArrival({
    required String stationId,
    required String routeId,
    required String staOrder,
  }) {
    return _apiService.getBusArrivalTimeList(
      stationId: stationId,
      routeId: routeId,
      staOrder: staOrder,
    );
  }
}
