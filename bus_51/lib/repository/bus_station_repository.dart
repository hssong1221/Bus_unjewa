import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/service/bus_api_service.dart';

// --------------------------------------------------
// 버스 정류장 Repository
// ViewModel(UI 계층)과 ApiService(데이터 소스) 사이의 데이터 계층
// --------------------------------------------------
class BusStationRepository {
  BusStationRepository(this._apiService);

  final BusApiService _apiService;

  /// API는 500m 고정 반경이라, 응답의 distance로 이 값 초과 정류장을 걸러낸다
  static const int searchRadiusMeters = 300;

  /// 좌표 주변 버스 정류장 조회 (지도 중심 좌표 기준 검색에 사용)
  ///
  /// - 빈 리스트 반환: 주변에 정류장 없음
  /// - [ApiException] throw: 네트워크/API 오류
  Future<List<BusStationModel>> getStationsAround({
    required double latitude,
    required double longitude,
  }) async {
    // 공공 API 파라미터: x=경도, y=위도
    final stations = await _apiService.getBusStationList(
      x: longitude.toString(),
      y: latitude.toString(),
    );
    return stations
        .where((station) => (int.tryParse(station.distance) ?? 0) <= searchRadiusMeters)
        .toList();
  }
}
