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

  //String? get latitude => _latitude;
  //String?  get longitude => _longitude;

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

  // 유저가 선택한 노선 idx
  int _userDataIdx = 0;
  int get userDataIdx => _userDataIdx;
  set userDataIdx(int value) {
    _userDataIdx = value;
    notifyListeners();
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
    } on ApiException catch (e) {
      debugPrint(e.toString());
    } finally {
      notifyListeners();
    }
  }

  // 서버 연결 테스트
  Future<void> testConnect({required String item_id, required String q}) async {
    try {
        await _busApiServices.testConnect(
        item_id: item_id,
        q: q,
      );
    } on ApiException catch (e) {
      debugPrint(e.toString());
    } finally {
      notifyListeners();
    }
  }


}
