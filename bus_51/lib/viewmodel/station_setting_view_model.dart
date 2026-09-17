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
// 현위치 확보, 지도 중심 좌표 기준 주변 정류장 검색, 정류장 선택 상태를 담당.
// 온보딩 전체와 수명이 같다 (InitSettingScreen 에서 제공). 화면 위젯은 뒤로 갔다 오면
// 새로 만들어지지만 이 객체는 남아 있으므로 GPS·정류장 검색을 다시 하지 않는다
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

  /// 마지막으로 검색한 중심 좌표. 뒤로 갔다 다시 들어올 때 지도를 이 위치에서 열기 위해 기억한다
  MapPoint? _lastSearchCenter;
  MapPoint? get lastSearchCenter => _lastSearchCenter;

  /// 지도 SDK 를 못 불러왔는가 (인증 실패·오프라인·시간 초과). true 면 화면이 재시도 안내로 지도를 덮는다
  bool _mapLoadFailed = false;
  bool get mapLoadFailed => _mapLoadFailed;

  /// 지도 재시도 횟수. 화면이 NaverMap 위젯의 Key 로 써서 값이 바뀌면 지도를 새로 만든다
  int _mapAttempt = 0;
  int get mapAttempt => _mapAttempt;

  void markMapLoadFailed() {
    if (_mapLoadFailed) return;
    _mapLoadFailed = true;
    notifyListeners();
  }

  /// "다시 시도": 실패 표시를 지우고 지도를 새로 만들게 한다
  void retryMapLoad() {
    _mapLoadFailed = false;
    _mapAttempt++;
    notifyListeners();
  }

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
    _lastSearchCenter = center;
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

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
      );
      return (lat: position.latitude, lng: position.longitude);
    } on Exception {
      // 실내 등에서 GPS fix가 늦으면 마지막 알려진 위치로 폴백
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown == null) rethrow;
      return (lat: lastKnown.latitude, lng: lastKnown.longitude);
    }
  }
}
