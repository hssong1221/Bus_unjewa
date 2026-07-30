import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/repository/bus_station_repository.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// 지도 좌표 (lat=위도, lng=경도)
typedef MapPoint = ({double lat, double lng});

/// 현위치 좌표를 얻는 함수. 테스트에서 GPS 없이 주입 가능
typedef PositionResolver = Future<MapPoint> Function();

// --------------------------------------------------
// 정류장 선택(지도) 화면 ViewModel
// 현위치 확보, 지도 중심 좌표 기준 주변 정류장 검색, 정류장 선택 상태를 담당
// --------------------------------------------------
class StationSettingViewModel extends ChangeNotifier {
  StationSettingViewModel(
    this._repository, {
    PositionResolver? positionResolver,
  }) : _positionResolver = positionResolver ?? _getCurrentPosition;

  final BusStationRepository _repository;
  final PositionResolver _positionResolver;

  /// GPS 실패 시 기본 위치 (수원역)
  static const MapPoint defaultPosition = (lat: 37.26574, lng: 126.99992);

  /// 지도 초기 카메라 위치. null이면 아직 위치 확보 전(지도 미표시)
  MapPoint? _initialPosition;
  MapPoint? get initialPosition => _initialPosition;

  /// GPS를 못 얻어 기본 위치로 대체했는지 (안내 문구용)
  bool _usedFallbackPosition = false;
  bool get usedFallbackPosition => _usedFallbackPosition;

  List<BusStationModel> _stations = [];
  List<BusStationModel> get stations => _stations;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  /// 검색 실패/빈 결과 안내 문구 (null이면 표시 안 함)
  String? _noticeMessage;
  String? get noticeMessage => _noticeMessage;

  BusStationModel? _selectedStation;
  BusStationModel? get selectedStation => _selectedStation;

  /// 최초 진입: 현위치 확보 후 그 주변을 1회 자동 검색
  Future<void> init() async {
    try {
      _initialPosition = await _positionResolver();
    } catch (e) {
      _initialPosition = defaultPosition;
      _usedFallbackPosition = true;
    }
    notifyListeners();
    await searchAround(_initialPosition!);
  }

  /// 지도 중심 좌표 주변 정류장 검색 ("이 지역에서 검색" 버튼)
  Future<void> searchAround(MapPoint center) async {
    _isSearching = true;
    _noticeMessage = null;
    notifyListeners();

    try {
      _stations = await _repository.getStationsAround(
        latitude: center.lat,
        longitude: center.lng,
      );
      _selectedStation = null;
      if (_stations.isEmpty) {
        _noticeMessage = '주변에 버스 정류장이 없습니다';
      }
    } on ApiException {
      _noticeMessage = '정류장 검색에 실패했습니다';
    } catch (e) {
      // 공공 API 응답 형태가 일정하지 않아 파싱 오류 가능성이 있음
      _noticeMessage = '정류장 검색에 실패했습니다';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void selectStation(BusStationModel station) {
    _selectedStation = station;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedStation == null) return;
    _selectedStation = null;
    notifyListeners();
  }

  // 위치 권한 확인 후 현재 GPS 좌표 획득
  static Future<MapPoint> _getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 거부되었습니다');
    }
    final position = await Geolocator.getCurrentPosition();
    return (lat: position.latitude, lng: position.longitude);
  }
}
