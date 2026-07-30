import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/service/bus_api_service.dart';

// --------------------------------------------------
// 버스 노선 경유 정류장 Repository
// ViewModel(UI 계층)과 ApiService(데이터 소스) 사이의 데이터 계층
// --------------------------------------------------
class BusRouteStationRepository {
  BusRouteStationRepository(this._apiService);

  final BusApiService _apiService;

  /// 노선이 경유하는 정류장 목록 조회 (stationSeq 순)
  ///
  /// - 빈 리스트 반환: 정류장 정보 없음
  /// - [ApiException] throw: 네트워크/API 오류
  Future<List<BusRouteStationModel>> getStationsOnRoute({required String routeId}) {
    return _apiService.getBusRouteStationList(routeId: routeId);
  }
}
