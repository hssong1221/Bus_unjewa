import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/service/bus_api_service.dart';

// --------------------------------------------------
// 버스 노선 경유 정류장 Repository
// ViewModel(UI 계층)과 ApiService(데이터 소스) 사이의 데이터 계층.
// 노선의 경유 정류장은 사실상 바뀌지 않는 데이터라 앱이 켜져 있는 동안 노선당 한 번만 받는다
// (온보딩 확인 화면과 상세 화면이 같은 노선을 따로 조회하던 것을 여기서 합친다)
// --------------------------------------------------
class BusRouteStationRepository {
  BusRouteStationRepository(this._apiService);

  final BusApiService _apiService;

  /// routeId → 조회 결과. 완성된 리스트가 아니라 진행 중인 Future 를 넣어두므로
  /// 같은 노선을 동시에 두 번 요청해도 API 는 한 번만 나간다
  final Map<String, Future<List<BusRouteStationModel>>> _cache = {};

  /// 노선이 경유하는 정류장 목록 조회 (stationSeq 순). 한 번 받은 노선은 캐시에서 준다
  ///
  /// - 빈 리스트 반환: 정류장 정보 없음 (캐시하지 않음)
  /// - [ApiException] throw: 네트워크/API 오류 (캐시하지 않음 → 재시도 때 다시 요청)
  Future<List<BusRouteStationModel>> getStationsOnRoute({required String routeId}) {
    return _cache[routeId] ??= _fetch(routeId);
  }

  Future<List<BusRouteStationModel>> _fetch(String routeId) async {
    try {
      final stations = await _apiService.getBusRouteStationList(routeId: routeId);
      // 빈 응답은 일시적인 데이터 문제일 수 있으니 다음에 다시 받는다
      if (stations.isEmpty) _cache.remove(routeId);
      return stations;
    } catch (_) {
      _cache.remove(routeId);
      rethrow;
    }
  }
}
