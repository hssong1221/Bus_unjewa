import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:flutter/material.dart';

class BusProvider extends ChangeNotifier {
  BusProvider();

  // bus station model
  BusStationModel? _selectedStationModel;
  Map<String, String>? _data;

  BusStationModel? get selectedStationModel => _selectedStationModel;
  Map<String, String> get data => _data ?? {};

  // bus route model
  BusRouteModel? _selectedRouteModel;

  BusRouteModel? get selectedRouteModel => _selectedRouteModel;

  // route with Station model
  BusRouteStationModel? _selectedBusRouteStationModel;

  BusRouteStationModel? get selectedBusRouteStationModel => _selectedBusRouteStationModel;

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
  // 서버 연결 테스트
  // 자체 서버 복구 시 BusApiService 를 다시 주입해서 아래 호출을 살린다
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
