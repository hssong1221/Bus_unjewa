import 'package:bus_51/enums/bus_enums.dart';
import 'package:bus_51/model/bus_arrival_model.dart';
import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:bus_51/service/bus_api_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class BusProvider extends ChangeNotifier {
  BusProvider(
    this._busApiServices,
    this._storageService,
  );

  final BusApiService _busApiServices;
  final StorageService _storageService;

  //GPS DATA
  String? _latitude;
  String? _longitude;

  String? get latitude => _latitude;
  String? get longitude => _longitude;

  // bus station model
  List<BusStationModel>? _busStationModel;
  BusStationModel? _selectedStationModel;
  Map<String, String>? _data;

  List<BusStationModel>? get busStationModel => _busStationModel;
  BusStationModel? get selectedStationModel => _selectedStationModel;
  Map<String, String> get data => _data ?? {};

  set busStationModel(List<BusStationModel>? value) {
    _busStationModel = value;
    notifyListeners();
  }

  // bus route model
  List<BusRouteModel>? _busRouteModel;
  BusRouteModel? _selectedRouteModel;

  List<BusRouteModel>? get busRouteModel => _busRouteModel;
  BusRouteModel? get selectedRouteModel => _selectedRouteModel;

  // route with Station model
  List<BusRouteStationModel>? _busRouteStationModel;
  BusRouteStationModel? _selectedBusRouteStationModel;

  BusRouteStationModel? _prevStationModel;
  BusRouteStationModel? _curStationModel;
  BusRouteStationModel? _nextStationModel;

  List<BusRouteStationModel>? get busRouteStationModel => _busRouteStationModel;
  BusRouteStationModel? get selectedBusRouteStationModel => _selectedBusRouteStationModel;

  BusRouteStationModel? get prevStationModel => _prevStationModel;
  BusRouteStationModel? get curStationModel => _curStationModel;
  BusRouteStationModel? get nextStationModel => _nextStationModel;

  // bus with arrival time model
  BusArrivalModel? _busArrivalModel;

  BusArrivalModel? get busArrivalModel => _busArrivalModel;

  // 버스 운행 상태
  bool _isBusOperating = true; // 버스가 운행 중인지 여부

  bool get isBusOperating => _isBusOperating;

  // 정류장 리스트에서 선택
  void setSelectedStationModel(BusStationModel model) {
    _selectedStationModel = model;
    //debugPrint("${model.stationName} ${model.stationId}");
    notifyListeners();
  }

  // 정류장 리스트에서 선택
  void setSelectedRouteModel(BusRouteModel model) {
    _selectedRouteModel = model;
    //debugPrint("${model.stationName} ${model.stationId}");
    notifyListeners();
  }

  // 전 현 다음, 정류장 넣기
  void setUserStation() {
    int staOrder = _selectedRouteModel!.staOrder;

    if (_busRouteStationModel == null) {
      return;
    } else {
      _curStationModel = _busRouteStationModel![staOrder - 1];

      if (staOrder == 1) {
        _prevStationModel = null;
        _nextStationModel = _busRouteStationModel![staOrder];
      } else if (staOrder == _busRouteStationModel!.length) {
        _prevStationModel = _busRouteStationModel![staOrder - 2];
        _nextStationModel = null;
      } else {
        _prevStationModel = _busRouteStationModel![staOrder - 2];
        _nextStationModel = _busRouteStationModel![staOrder];
      }
    }
  }

  // 유저가 선택한 노선 저장
  Future<void> saveUserDataList(UserSaveModel order) async {
    await _storageService.addUserSaveModel(order);
  }

  /*UserSaveModel loadUserData() {
    var result = _storageService.loadUserModel();
    if(result == null) {
      return UserSaveModel(stationId: -1, routeId: -1, staOrder: -1);
    } else {
      return result;
    }
  }*/

  List<UserSaveModel> loadUserDataList() {
    return _storageService.loadUserModelList();
  }

  void deleteAllData(){
    return _storageService.deleteUserData();
  }

  // 선택한 노선들 삭제
  Future<void> deleteSelectedUserData(List<int> indices) async {
    await _storageService.removeItems(indices);
    notifyListeners();
  }

  // 버스 타입 변경
  Future<void> updateBusType(int index, BusType newBusType) async {
    await _storageService.updateBusType(index, newBusType);
    notifyListeners();
  }

  // 유저가 선택한 노선 idx
  int _userDataIdx = 0;
  int get userDataIdx => _userDataIdx;
  set userDataIdx(int value) {
    _userDataIdx = value;
    notifyListeners();
  }

  // 현재 버스 모드 (출근/퇴근/전체) - 시간대별 초기값 설정
  BusMode _currentBusMode = BusMode.all;
  BusMode get currentBusMode => _currentBusMode;

  // 초기 모드 설정 (시간대별)
  BusMode get initialBusMode {
    final now = DateTime.now();
    final hour = now.hour;
    
    // 오전 6-10시: 출근
    if (hour >= 6 && hour < 10) {
      return BusMode.work;
    }
    // 오후 5-8시(17-20시): 퇴근
    else if (hour >= 17 && hour < 20) {
      return BusMode.home;
    }
    // 그 외 시간: 전체 보기
    return BusMode.all;
  }

  // 앱 시작시 초기 모드 설정
  void setInitialBusMode() {
    _currentBusMode = initialBusMode;
    notifyListeners();
  }

  // ==========================================
  // 테스트용 임시 데이터 (나중에 필요할 때 주석 해제)
  // ==========================================
  /*
  Future<void> addTestData() async {
    final testBuses = [
      UserSaveModel(
        routeName: '101',
        stationId: 226000060,
        routeId: 208000017,
        staOrder: 1,
        routeTypeCd: 1, // 일반버스
        busType: BusType.work, // 출근용
      ),
      UserSaveModel(
        routeName: '102',
        stationId: 226000061,
        routeId: 208000018,
        staOrder: 2,
        routeTypeCd: 3, // 간선버스
        busType: BusType.work, // 출근용
      ),
      UserSaveModel(
        routeName: '201',
        stationId: 226000062,
        routeId: 208000019,
        staOrder: 1,
        routeTypeCd: 2, // 지선버스
        busType: BusType.home, // 퇴근용
      ),
      UserSaveModel(
        routeName: '301',
        stationId: 226000063,
        routeId: 208000020,
        staOrder: 3,
        routeTypeCd: 4, // 순환버스
        busType: BusType.home, // 퇴근용
      ),
      UserSaveModel(
        routeName: '501',
        stationId: 226000064,
        routeId: 208000021,
        staOrder: 2,
        routeTypeCd: 1, // 일반버스
        busType: BusType.none, // 평시
      ),
      UserSaveModel(
        routeName: '502',
        stationId: 226000065,
        routeId: 208000022,
        staOrder: 1,
        routeTypeCd: 2, // 지선버스
        busType: BusType.none, // 평시
      ),
    ];

    for (final bus in testBuses) {
      await saveUserDataList(bus);
    }
  }
  */

  // 현재 모드에 따른 실제 필터링할 버스 타입
  BusType? get effectiveFilterType {
    switch (_currentBusMode) {
      case BusMode.work:
        return BusType.work;
      case BusMode.home:
        return BusType.home;
      case BusMode.all:
        return null; // 필터링 안함
    }
  }

  // 모드 변경
  void setBusMode(BusMode mode) {
    _currentBusMode = mode;
    notifyListeners();
  }

  // 현재 설정에 맞는 버스 리스트 필터링
  List<UserSaveModel> getFilteredBusList() {
    final allBuses = loadUserDataList();
    final filterType = effectiveFilterType;
    
    if (filterType == null) {
      return allBuses; // 전체 보기
    }
    
    return allBuses.where((bus) => bus.busType == filterType).toList();
  }

  // -------
  // API 연결
  // -------
  // gps 데이터 연결 및 가져오기
  Future<void> getGPSData() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('permissions are denied');
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    _latitude = position.latitude.toString();
    _longitude = position.longitude.toString();
  }

  // 버스 정류장 데이터 가져오기
  Future<void> getBusStationList() async {
    try {
      _busStationModel = await _busApiServices.getBusStationList(x: _longitude!, y: _latitude!);
    } on ApiException catch (e) {
      debugPrint(e.toString());
    } finally {
      notifyListeners();
    }
  }

  // 버스 정류장을 지나가는 노선 데이터 가져오기
  Future<void> getBusRouteList() async {
    String? stationId = _selectedStationModel?.stationId.toString();

    try {
      _busRouteModel = await _busApiServices.getBusRouteList(stationId: stationId ?? "226000060");
    } on ApiException catch (e) {
      debugPrint(e.toString());
    } finally {
      notifyListeners();
    }
  }

  // 노선이 지나가는 정류장 데이터 가져오기
  Future<void> getRouteStationList() async {
    String? routeId = _selectedRouteModel?.routeId.toString();

    try {
      _busRouteStationModel = await _busApiServices.getBusRouteStationList(routeId: routeId ?? "208000017");
      setUserStation();
    } on ApiException catch (e) {
      debugPrint(e.toString());
    } finally {
      notifyListeners();
    }
  }

  // 유저가 선택한 정류장과 노선에 맞는 버스 도착정보 가져오기
  Future<void> getBusArrivalTimeList({required String stationId, required String routeId, required String staOrder}) async {
    try {
      _busArrivalModel = await _busApiServices.getBusArrivalTimeList(
        stationId: stationId,
        routeId: routeId,
        staOrder: staOrder,
      );

      // 버스 운행 상태 업데이트
      _isBusOperating = _busArrivalModel != null;

    } on ApiException catch (e) {
      debugPrint(e.toString());
      // API 에러 시에도 운행 상태 false로 설정
      _isBusOperating = false;
      _busArrivalModel = null;
    } finally {
      notifyListeners();
    }
  }

  // 서버 연결 테스트
  Future<void> testConnect({required String item_id, required String q}) async {
    try {
        /*await _busApiServices.testConnect(
        item_id: item_id,
        q: q,
      );*/
    } on ApiException catch (e) {
      debugPrint(e.toString());
    } finally {
      notifyListeners();
    }
  }


}
