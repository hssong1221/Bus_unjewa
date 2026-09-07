import 'package:bus_51/model/bus_routestation_model.dart';
import 'package:bus_51/model/busroute_model.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_routestation_repository.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/utils/api_exception.dart';
import 'package:flutter/foundation.dart';

// --------------------------------------------------
// 설정 완료(마지막 확인) 화면 — 노선 카드 하나의 UI 상태
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
// 선택한 노선마다 경유 정류장을 조회하고, 전부 준비되면 한 번에 저장한다
// --------------------------------------------------
class FavoriteSettingViewModel extends ChangeNotifier {
  FavoriteSettingViewModel(
    this._repository,
    this._storageService, {
    required this.routes,
  }) : _states = List.filled(routes.length, const FavoriteSettingLoading());

  final BusRouteStationRepository _repository;
  final StorageService _storageService;

  /// 이전 단계에서 체크한 노선들. 비어 있으면 잘못된 진입
  final List<BusRouteModel> routes;

  /// routes 와 인덱스가 같은 카드별 상태
  final List<FavoriteSettingState> _states;
  FavoriteSettingState stateAt(int index) => _states[index];

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  /// 모든 노선의 정류장 정보가 준비됐고 저장 중이 아닐 때만 저장 가능
  bool get canSave =>
      routes.isNotEmpty && _states.every((s) => s is FavoriteSettingReady) && !_isSaving;

  /// 노선 수만큼 병렬 조회
  Future<void> init() => Future.wait([for (var i = 0; i < routes.length; i++) _fetchStations(i)]);

  /// 실패한 카드만 다시 시도
  Future<void> retry(int index) async {
    _states[index] = const FavoriteSettingLoading();
    notifyListeners();
    await _fetchStations(index);
  }

  Future<void> _fetchStations(int index) async {
    final r = routes[index];
    try {
      final stations = await _repository.getStationsOnRoute(routeId: r.routeId);
      final staOrder = int.tryParse(r.staOrder);

      if (stations.isEmpty || staOrder == null || staOrder < 1 || staOrder > stations.length) {
        _states[index] = const FavoriteSettingError('정류장 정보를 불러오지 못했습니다');
      } else {
        _states[index] = FavoriteSettingReady(
          curStation: stations[staOrder - 1],
          timelineStations: stations.sublist(staOrder - 1),
        );
      }
    } on ApiException catch (e) {
      _states[index] = FavoriteSettingError(e.message ?? e.error ?? '정류장 정보를 불러오지 못했습니다');
    } catch (e) {
      // 공공 API 응답 형태가 일정하지 않아 파싱 오류 가능성이 있음
      _states[index] = const FavoriteSettingError('정류장 정보를 불러오지 못했습니다');
    }
    notifyListeners();
  }

  /// 저장. 성공하면 true 반환 (뷰가 리스트 화면으로 이동)
  Future<bool> save() async {
    if (!canSave) return false;

    // 하나라도 값이 잘못됐으면 아무것도 저장하지 않고 해당 카드만 에러로 표시
    final models = <UserSaveModel>[];
    for (var i = 0; i < routes.length; i++) {
      final r = routes[i];
      final state = _states[i] as FavoriteSettingReady;

      final stationId = int.tryParse(state.curStation.stationId);
      final routeId = int.tryParse(r.routeId);
      final staOrder = int.tryParse(state.curStation.stationSeq);
      final routeTypeCd = int.tryParse(r.routeTypeCd);
      if (stationId == null || routeId == null || staOrder == null || routeTypeCd == null) {
        _states[i] = const FavoriteSettingError('저장할 노선 정보가 올바르지 않습니다');
        notifyListeners();
        return false;
      }

      models.add(UserSaveModel(
        routeName: r.routeName,
        stationId: stationId,
        routeId: routeId,
        staOrder: staOrder,
        routeTypeCd: routeTypeCd,
        stationName: state.curStation.stationName,
        routeDestName: r.routeDestName,
      ));
    }

    _isSaving = true;
    notifyListeners();

    // 저장은 읽고-쓰기라 순서대로 (중복은 StorageService 가 거른다)
    for (final model in models) {
      await _storageService.addUserSaveModel(model);
    }

    _isSaving = false;
    notifyListeners();
    return true;
  }
}
