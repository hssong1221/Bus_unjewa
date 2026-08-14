import 'package:bus_51/enums/bus_enums.dart';
import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:flutter/foundation.dart';

// --------------------------------------------------
// 저장 노선 리스트 화면 UI 상태
// UI는 이 sealed class 를 switch 해서 화면을 분기한다
// --------------------------------------------------
sealed class BusListState {
  const BusListState();
}

/// 저장된 노선이 하나도 없음 (첫 사용)
class BusListEmpty extends BusListState {
  const BusListEmpty();
}

/// 저장된 노선은 있지만 현재 모드(출근/퇴근)에 해당하는 노선이 없음
class BusListFilterEmpty extends BusListState {
  const BusListFilterEmpty();
}

/// 현재 모드에 해당하는 노선 목록
class BusListSuccess extends BusListState {
  const BusListSuccess(this.items);

  final List<UserSaveModel> items;
}

// --------------------------------------------------
// 저장 노선 리스트 ViewModel
// 저장소 읽기/삭제/타입 변경, 출퇴근 모드 필터, 선택 모드를 담당한다.
// 저장 리스트는 메모리에 올려두고 조작하며, 저장소 인덱스가 필요한
// 연산은 모델로 받아 내부에서 한 번만 변환한다
// --------------------------------------------------
class BusListViewModel extends ChangeNotifier {
  BusListViewModel(this._storageService, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _allItems = _storageService.loadUserModelList();
    _mode = _initialMode();
  }

  final StorageService _storageService;
  final DateTime Function() _clock;

  late List<UserSaveModel> _allItems;

  // ----- 출퇴근 모드 필터 -----

  late BusMode _mode;
  BusMode get mode => _mode;

  /// 진입 시간대별 초기 모드: 6~10시 출근, 17~20시 퇴근, 그 외 전체
  BusMode _initialMode() {
    final hour = _clock().hour;
    if (hour >= 6 && hour < 10) return BusMode.work;
    if (hour >= 17 && hour < 20) return BusMode.home;
    return BusMode.all;
  }

  void setMode(BusMode mode) {
    _mode = mode;
    notifyListeners();
  }

  BusListState get state {
    if (_allItems.isEmpty) return const BusListEmpty();

    final filterType = switch (_mode) {
      BusMode.work => BusType.work,
      BusMode.home => BusType.home,
      BusMode.all => null,
    };
    final filtered = filterType == null
        ? _allItems
        : _allItems.where((bus) => bus.busType == filterType).toList();

    if (filtered.isEmpty) return const BusListFilterEmpty();
    return BusListSuccess(filtered);
  }

  /// 저장된 노선 존재 여부 (필터와 무관 — 삭제 버튼 노출 기준)
  bool get hasItems => _allItems.isNotEmpty;
  int get totalCount => _allItems.length;

  /// 메인 화면 진입용: 전체 저장 리스트 기준 인덱스
  int indexOf(UserSaveModel item) => _allItems.indexOf(item);

  /// 저장소 재동기화 (노선 추가 플로우에서 돌아왔을 때)
  void reload() {
    _allItems = _storageService.loadUserModelList();
    _selected.removeWhere((item) => !_allItems.contains(item));
    notifyListeners();
  }

  // ----- 선택(삭제) 모드 -----

  bool _isSelectionMode = false;
  bool get isSelectionMode => _isSelectionMode;

  final Set<UserSaveModel> _selected = {};
  int get selectedCount => _selected.length;
  bool isSelected(UserSaveModel item) => _selected.contains(item);
  List<String> get selectedRouteNames =>
      _selected.map((item) => item.routeName).toList();

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    _selected.clear();
    notifyListeners();
  }

  void toggleSelection(UserSaveModel item) {
    if (!_selected.remove(item)) _selected.add(item);
    notifyListeners();
  }

  // ----- 저장소 조작 -----

  Future<void> deleteSelected() async {
    final indices =
        _selected.map(_allItems.indexOf).where((i) => i >= 0).toList();
    await _storageService.removeItems(indices);
    _isSelectionMode = false;
    reload();
  }

  void deleteAll() {
    _storageService.deleteUserData();
    _isSelectionMode = false;
    reload();
  }

  Future<void> changeBusType(UserSaveModel item, BusType newType) async {
    final index = _allItems.indexOf(item);
    if (index < 0) return;
    await _storageService.updateBusType(index, newType);
    reload();
  }
}
