import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/screen/init_setting_screen/explain_screen.dart';
import 'package:bus_51/screen/init_setting_screen/favorite_setting_screen.dart';
import 'package:bus_51/screen/init_setting_screen/route_setting_screen.dart';
import 'package:bus_51/screen/init_setting_screen/station_setting_screen.dart';
import 'package:flutter/material.dart';

class InitProvider with ChangeNotifier {

  final List<Widget> _views = [
    const ExplainScreenView(),
    const StationSettingView(),
    const RouteSettingView(),
    const FavoriteSettingView(),
  ];
  int _curIdx = 0;

  Widget get curView => _views[_curIdx];
  int get curIdx => _curIdx;

  // 초기 인덱스 설정 (버스 추가 시 StationSettingView부터 시작)
  void setInitialIndex(int index) {
    _curIdx = index;
    notifyListeners();
  }

  // ----- 온보딩 단계 간 선택값 전달 (정류장 선택 → 노선 선택 → 확인) -----
  // InitProvider는 온보딩 화면과 수명이 같으므로 온보딩이 끝나면 함께 사라진다

  BusStationModel? _selectedStationModel;
  BusStationModel? get selectedStationModel => _selectedStationModel;

  BusRouteModel? _selectedRouteModel;
  BusRouteModel? get selectedRouteModel => _selectedRouteModel;

  void setSelectedStationModel(BusStationModel model) {
    _selectedStationModel = model;
    notifyListeners();
  }

  void setSelectedRouteModel(BusRouteModel model) {
    _selectedRouteModel = model;
    notifyListeners();
  }

  // view 순서 제어
  void prevAccountView() {
    _curIdx--;
    if(_curIdx <= 0){
      _curIdx = 0;
    }
    notifyListeners();
  }

  void nextAccountView() {
    _curIdx++;
    if(_curIdx >= _views.length-1){
      _curIdx = _views.length-1;
    }
    notifyListeners();
  }
}
