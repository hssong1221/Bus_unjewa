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
