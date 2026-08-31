import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:flutter/foundation.dart';

// --------------------------------------------------
// 설정 완료(마지막 확인) 화면 UI 상태
// --------------------------------------------------
sealed class FavoriteSettingState {
  const FavoriteSettingState();
}

/// 경유 정류장 목록 불러오는 중
class FavoriteSettingLoading extends FavoriteSettingState {
  const FavoriteSettingLoading();
}

/// 정류장 정보 준비 완료 (저장 가능)
class FavoriteSettingReady extends FavoriteSettingState {
  const FavoriteSettingReady({
    required this.curStation,
    required this.timelineStations,
  });

  /// 유저가 탑승할 정류장 (노선의 staOrder 기준)
  final BusRouteStationModel curStation;

  /// 탑승 정류장부터 종점까지
  final List<BusRouteStationModel> timelineStations;
}

/// 조회 실패 (네트워크/API 오류, 노선 정보 없음)
class FavoriteSettingError extends FavoriteSettingState {
  const FavoriteSettingError(this.message);

  final String message;
}

// --------------------------------------------------
// 설정 완료 화면 ViewModel
// 경유 정류장 조회, 저장을 담당한다
// --------------------------------------------------
class FavoriteSettingViewModel extends ChangeNotifier {
  FavoriteSettingViewModel(
    this._repository,
    this._storageService, {
    required this.route,
  });

  final BusRouteStationRepository _repository;
  final StorageService _storageService;

  /// 이전 단계에서 선택한 노선. null이면 잘못된 진입
  final BusRouteModel? route;

  FavoriteSettingState _state = const FavoriteSettingLoading();
  FavoriteSettingState get state => _state;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  /// 정류장 정보가 준비됐고 저장 중이 아닐 때만 저장 가능
  bool get canSave => _state is FavoriteSettingReady && !_isSaving;

  Future<void> init() => _fetchStations();

  /// 실패 후 다시 시도
  Future<void> retry() async {
    _state = const FavoriteSettingLoading();
    notifyListeners();
    await _fetchStations();
  }

  Future<void> _fetchStations() async {
    final r = route;
    if (r == null) {
      _state = const FavoriteSettingError('선택된 노선 정보가 없습니다');
      notifyListeners();
      return;
    }

    try {
      final stations = await _repository.getStationsOnRoute(routeId: r.routeId);
      final staOrder = int.tryParse(r.staOrder);

      if (stations.isEmpty || staOrder == null || staOrder < 1 || staOrder > stations.length) {
        _state = const FavoriteSettingError('정류장 정보를 불러오지 못했습니다');
      } else {
        _state = FavoriteSettingReady(
          curStation: stations[staOrder - 1],
          timelineStations: stations.sublist(staOrder - 1),
        );
      }
    } on ApiException catch (e) {
      _state = FavoriteSettingError(e.message ?? e.error ?? '정류장 정보를 불러오지 못했습니다');
    } catch (e) {
      // 공공 API 응답 형태가 일정하지 않아 파싱 오류 가능성이 있음
      _state = const FavoriteSettingError('정류장 정보를 불러오지 못했습니다');
    }
    notifyListeners();
  }

  /// 저장. 성공하면 true 반환 (뷰가 리스트 화면으로 이동)
  Future<bool> save() async {
    final state = _state;
    final r = route;
    if (state is! FavoriteSettingReady || r == null || _isSaving) return false;

    final stationId = int.tryParse(state.curStation.stationId);
    final routeId = int.tryParse(r.routeId);
    final staOrder = int.tryParse(state.curStation.stationSeq);
    final routeTypeCd = int.tryParse(r.routeTypeCd);
    if (stationId == null || routeId == null || staOrder == null || routeTypeCd == null) {
      _state = const FavoriteSettingError('저장할 노선 정보가 올바르지 않습니다');
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();

    await _storageService.addUserSaveModel(UserSaveModel(
      routeName: r.routeName,
      stationId: stationId,
      routeId: routeId,
      staOrder: staOrder,
      routeTypeCd: routeTypeCd,
      stationName: state.curStation.stationName,
      routeDestName: r.routeDestName,
    ));

    _isSaving = false;
    notifyListeners();
    return true;
  }
}
