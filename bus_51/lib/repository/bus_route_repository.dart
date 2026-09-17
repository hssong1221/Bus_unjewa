import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/service/bus_api_service.dart';

// --------------------------------------------------
// 버스 노선 Repository
// ViewModel(UI 계층)과 ApiService(데이터 소스) 사이의 데이터 계층
// --------------------------------------------------
class BusRouteRepository {
  BusRouteRepository(this._apiService);

  final BusApiService _apiService;

  /// 정류장을 경유하는 버스 노선 조회
  ///
  /// - 빈 리스트 반환: 경유 노선 없음
  /// - [ApiException] throw: 네트워크/API 오류
  Future<List<BusRouteModel>> getRoutesThroughStation({required String stationId}) {
    return _apiService.getBusRouteList(stationId: stationId);
  }
}
