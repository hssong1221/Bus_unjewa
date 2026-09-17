import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/busstation_model.dart';
import 'package:bus_51/screen/init_setting_screen/explain_screen.dart';
import 'package:bus_51/screen/init_setting_screen/favorite_setting_screen.dart';
import 'package:bus_51/screen/init_setting_screen/route_setting_screen.dart';
import 'package:bus_51/screen/init_setting_screen/station_setting_screen.dart';
import 'package:flutter/material.dart';

/// 온보딩 단계 전환 상태.
/// 최초 실행은 ① 웰컴부터, 리스트에서 노선 추가로 들어오면 ② 정류장부터 시작한다.
/// [startIdx]는 뒤로가기의 바닥 — 그보다 앞 단계(웰컴)로는 돌아가지 않는다.
class InitProvider with ChangeNotifier {
  InitProvider({int startIdx = 0})
      : assert(startIdx >= 0 && startIdx < stepCount),
        _startIdx = startIdx,
        _curIdx = startIdx;

  /// 노선 추가 플로우 진입 시 시작 인덱스 (② 정류장 선택)
  static const int stationStepIdx = 1;
  static const int stepCount = 4;

  final List<Widget> _views = [
    const ExplainScreenView(),
    const StationSettingView(),
    const RouteSettingView(),
    const FavoriteSettingView(),
  ];
  final int _startIdx;
  int _curIdx;

  Widget get curView => _views[_curIdx];
  int get curIdx => _curIdx;

  /// 이 플로우의 첫 단계인가 (여기서 뒤로가기는 단계 이동이 아니라 화면 이탈)
  bool get isFirstStep => _curIdx == _startIdx;

  /// 진행 표시용 — 추가 플로우는 웰컴을 빼고 1/3 부터 센다
  int get stepNumber => _curIdx - _startIdx + 1;
  int get totalSteps => stepCount - _startIdx;

  // ----- 온보딩 단계 간 선택값 전달 (정류장 선택 → 노선 선택 → 확인) -----
  // InitProvider는 온보딩 화면과 수명이 같으므로 온보딩이 끝나면 함께 사라진다

  BusStationModel? _selectedStationModel;
  BusStationModel? get selectedStationModel => _selectedStationModel;

  /// 노선 선택 화면에서 체크한 노선들 (체크한 순서). 확인 화면에서 한 번에 저장한다
  final List<BusRouteModel> _selectedRouteModels = [];
  List<BusRouteModel> get selectedRouteModels => List.unmodifiable(_selectedRouteModels);

  void setSelectedStationModel(BusStationModel model) {
    // 정류장이 바뀌면 이전 정류장 기준으로 체크한 노선은 의미가 없으므로 비운다
    if (_selectedStationModel?.stationId != model.stationId) {
      _selectedRouteModels.clear();
    }
    _selectedStationModel = model;
    notifyListeners();
  }

  bool isRouteSelected(BusRouteModel model) => _selectedRouteModels.contains(model);

  /// 체크 토글. 뒤로 갔다 와도 유지되도록 화면이 아닌 여기서 들고 있는다
  void toggleSelectedRoute(BusRouteModel model) {
    if (!_selectedRouteModels.remove(model)) {
      _selectedRouteModels.add(model);
    }
    notifyListeners();
  }

  // view 순서 제어
  void prevAccountView() {
    _curIdx--;
    if (_curIdx <= _startIdx) {
      _curIdx = _startIdx;
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
