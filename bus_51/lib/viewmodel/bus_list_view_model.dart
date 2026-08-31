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

/// 저장된 노선 목록 (저장 순서)
class BusListSuccess extends BusListState {
  const BusListSuccess(this.items);

  final List<UserSaveModel> items;
}

// --------------------------------------------------
// 저장 노선 리스트 ViewModel
// 저장소 읽기/삭제, 선택 모드를 담당한다.
// 저장 리스트는 메모리에 올려두고 조작하며, 저장소 인덱스가 필요한
// 연산은 모델로 받아 내부에서 한 번만 변환한다
// --------------------------------------------------
class BusListViewModel extends ChangeNotifier {
  BusListViewModel(this._storageService) {
    _allItems = _storageService.loadUserModelList();
  }

  final StorageService _storageService;

  late List<UserSaveModel> _allItems;

  BusListState get state {
    if (_allItems.isEmpty) return const BusListEmpty();
    return BusListSuccess(_allItems);
  }

  /// 저장된 노선 존재 여부 (삭제 버튼 노출 기준)
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
}
