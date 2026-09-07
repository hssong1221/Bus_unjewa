import 'dart:async';

import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/utils/arrival_time.dart';
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
// 카드 하나의 도착 정보 상태. 카드마다 독립이라 한 노선이 실패해도 나머지는 그대로 보인다
// --------------------------------------------------
sealed class BusCardArrival {
  const BusCardArrival();
}

/// 조회 중 (시간 자리에 스켈레톤)
class BusCardLoading extends BusCardArrival {
  const BusCardLoading();
}

/// 다음 버스가 오고 있음
class BusCardArriving extends BusCardArrival {
  const BusCardArriving({required this.remainingSeconds, required this.locationNo});

  /// 카운트다운 중인 남은 초
  final int remainingSeconds;

  /// 몇 정거장 전
  final String locationNo;

  BusCardArriving tick() => BusCardArriving(
        remainingSeconds: remainingSeconds > 0 ? remainingSeconds - 1 : 0,
        locationNo: locationNo,
      );
}

/// 오는 버스 없음 (출발 전 · 운행 종료)
class BusCardNotOperating extends BusCardArrival {
  const BusCardNotOperating();
}

/// 조회 실패 (네트워크/API 오류)
class BusCardError extends BusCardArrival {
  const BusCardError();
}

// --------------------------------------------------
// 저장 노선 리스트 ViewModel
// 저장소 읽기/삭제, 선택 모드, 카드별 도착 정보 조회·카운트다운을 담당한다.
// 저장 리스트는 메모리에 올려두고 조작하며, 저장소 인덱스가 필요한
// 연산은 모델로 받아 내부에서 한 번만 변환한다
// --------------------------------------------------
class BusListViewModel extends ChangeNotifier {
  BusListViewModel(this._storageService, this._arrivalRepository) {
    _allItems = _storageService.loadUserModelList();
  }

  final StorageService _storageService;
  final BusArrivalRepository _arrivalRepository;

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

  /// 저장소 재동기화 (노선 추가 플로우에서 돌아왔을 때, 삭제 후)
  void reload() {
    _allItems = _storageService.loadUserModelList();
    _selected.removeWhere((item) => !_allItems.contains(item));
    _arrivals.removeWhere((key, _) => !_isSaved(key));
    notifyListeners();
  }

  // ----- 카드별 도착 정보 -----

  /// 리스트는 노선 수만큼 API 를 부르므로 메인(60초)보다 길게 잡는다
  static const Duration refreshInterval = Duration(minutes: 2);

  /// 저장소를 다시 읽으면 모델 인스턴스가 바뀌므로 객체가 아니라 값(정류장·노선·순번)으로 찾는다
  final Map<String, BusCardArrival> _arrivals = {};

  /// 카드를 값으로 식별하는 키 (도착 정보 맵, 리스트 위젯 키 공용)
  static String keyOf(UserSaveModel item) => '${item.stationId}-${item.routeId}-${item.staOrder}';

  bool _isSaved(String key) => _allItems.any((item) => keyOf(item) == key);

  Timer? _refreshTimer;
  Timer? _countdownTimer;

  /// 아직 응답이 없는 카드는 로딩으로 본다
  BusCardArrival arrivalOf(UserSaveModel item) => _arrivals[keyOf(item)] ?? const BusCardLoading();

  /// 화면 진입: 전부 조회하고 주기 갱신 시작
  Future<void> loadArrivals() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) => _fetchAll());
    return _fetchAll();
  }

  /// 화면을 떠날 때(상세·노선 추가로 이동) 갱신·카운트다운 정지
  void pause() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// 돌아왔을 때 전부 다시 조회하고 갱신 재개
  Future<void> resume() => loadArrivals();

  /// 당겨서 새로고침. 이전 숫자를 지우지 않고 응답이 오면 바꿔 끼운다
  Future<void> refresh() => _fetchAll();

  /// 실패한 카드만 다시 조회
  Future<void> retry(UserSaveModel item) {
    _arrivals[keyOf(item)] = const BusCardLoading();
    notifyListeners();
    return _fetchOne(item);
  }

  Future<void> _fetchAll() => Future.wait(_allItems.map(_fetchOne));

  Future<void> _fetchOne(UserSaveModel item) async {
    BusCardArrival result;
    try {
      final arrival = await _arrivalRepository.getArrival(
        stationId: item.stationId.toString(),
        routeId: item.routeId.toString(),
        staOrder: item.staOrder.toString(),
      );
      result = arrival == null
          ? const BusCardNotOperating()
          : BusCardArriving(
              remainingSeconds: arrivalSeconds(sec: arrival.predictTimeSec1, min: arrival.predictTime1),
              locationNo: arrival.locationNo1,
            );
    } catch (_) {
      // ApiException 과 공공 API 응답 파싱 오류 모두 카드 하나의 실패로만 보여준다
      result = const BusCardError();
    }
    // 응답이 오기 전에 삭제된 카드는 버린다
    final key = keyOf(item);
    if (!_isSaved(key)) return;
    _arrivals[key] = result;
    _ensureCountdown();
    notifyListeners();
  }

  bool get _hasTicking => _arrivals.values.any((a) => a is BusCardArriving && a.remainingSeconds > 0);

  /// 카운트다운할 카드가 있을 때만 1초 타이머를 돌린다
  void _ensureCountdown() {
    if (_countdownTimer != null || !_hasTicking) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _arrivals.updateAll((_, a) => a is BusCardArriving ? a.tick() : a);
      if (!_hasTicking) {
        timer.cancel();
        _countdownTimer = null;
      }
      notifyListeners();
    });
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

  /// 선택 모드에서 드래그로 순서 변경 ([newIndex] 는 옮긴 뒤 리스트 기준). 바꾼 순서는 바로 저장한다
  Future<void> move(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return Future.value();
    final item = _allItems.removeAt(oldIndex);
    _allItems.insert(newIndex, item);
    notifyListeners();
    return _storageService.saveUserModelList(_allItems);
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

  @override
  void dispose() {
    pause();
    super.dispose();
  }
}
