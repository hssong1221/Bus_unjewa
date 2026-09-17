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

  BusCardArriving tick() => elapsed(1);

  /// [seconds] 만큼 시간이 흐른 뒤의 상태. 0 밑으로는 내려가지 않는다
  BusCardArriving elapsed(int seconds) => BusCardArriving(
        remainingSeconds: remainingSeconds > seconds ? remainingSeconds - seconds : 0,
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
  BusListViewModel(this._storageService, this._arrivalRepository, {DateTime Function()? now})
      : _now = now ?? DateTime.now {
    _allItems = _storageService.loadUserModelList();
  }

  final StorageService _storageService;
  final BusArrivalRepository _arrivalRepository;

  /// 현재 시각. 테스트에서 가짜 시계를 넣을 수 있게 함수로 받는다
  final DateTime Function() _now;

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

  /// 리스트는 정류장 수만큼 API 를 부르므로 메인(60초)보다 길게 잡는다
  static const Duration refreshInterval = Duration(minutes: 2);

  /// 이 시간 안에 받은 도착 정보는 화면에 돌아와도 다시 받지 않고 그대로 쓴다
  /// (상세를 잠깐 보고 나오거나 앱을 잠깐 내렸다 올리는 왕복마다 정류장 수만큼 호출하던 것을 막는다)
  static const Duration staleAfter = Duration(seconds: 30);

  /// 마지막 전체 조회를 시작한 시각. 응답이 아니라 요청 시각이라 데이터 나이를 보수적으로 잡는다
  DateTime? _lastFetchAt;

  /// pause 된 시각. 카운트다운이 멈춰 있던 시간을 resume 때 한 번에 빼기 위해 기억한다
  DateTime? _pausedAt;

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
    _startRefreshTimer();
    return _fetchAll();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) => _fetchAll());
  }

  /// 화면을 떠날 때(상세·노선 추가로 이동, 앱 백그라운드) 갱신·카운트다운 정지
  void pause() {
    _pausedAt ??= _now();
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// 돌아왔을 때 갱신 재개. 마지막 조회가 [staleAfter] 안이고 모든 카드에 결과가 있으면
  /// 다시 받지 않고, 멈춰 있던 카운트다운만 흐른 시간만큼 당긴다
  Future<void> resume() {
    final now = _now();
    final pausedFor = _pausedAt == null ? Duration.zero : now.difference(_pausedAt!);
    _pausedAt = null;

    final isFresh = _lastFetchAt != null && now.difference(_lastFetchAt!) < staleAfter;
    final allHaveResult = _allItems.every((item) => _arrivals.containsKey(keyOf(item)));
    if (!isFresh || !allHaveResult) return loadArrivals();

    _arrivals.updateAll((_, a) => a is BusCardArriving ? a.elapsed(pausedFor.inSeconds) : a);
    _startRefreshTimer();
    _ensureCountdown();
    notifyListeners();
    return Future.value();
  }

  /// 당겨서 새로고침. 이전 숫자를 지우지 않고 응답이 오면 바꿔 끼운다
  Future<void> refresh() => _fetchAll();

  /// 실패한 카드의 정류장을 다시 조회 (같은 정류장의 다른 카드도 함께 갱신된다)
  Future<void> retry(UserSaveModel item) {
    _arrivals[keyOf(item)] = const BusCardLoading();
    notifyListeners();
    return _fetchStation(item.stationId);
  }

  /// 저장 노선은 대부분 한 정류장에 몰려 있으므로 노선이 아니라 정류장 단위로 조회한다
  Future<void> _fetchAll() {
    _lastFetchAt = _now();
    return Future.wait(_allItems.map((item) => item.stationId).toSet().map(_fetchStation));
  }

  /// 정류장 하나의 도착 정보를 한 번에 받아 그 정류장에 저장된 카드 전부를 채운다
  Future<void> _fetchStation(int stationId) async {
    BusCardArrival Function(UserSaveModel) resultOf;
    try {
      final arrivals = await _arrivalRepository.getArrivalsAtStation(stationId: stationId.toString());
      resultOf = (item) {
        // 순환 노선은 같은 정류장을 두 번 지나므로 routeId 만으로는 부족하고 staOrder 까지 맞아야 한다
        final arrival = arrivals
            .where((a) => a.routeId == item.routeId.toString() && a.staOrder == item.staOrder.toString())
            .firstOrNull;
        return arrival == null
            ? const BusCardNotOperating()
            : BusCardArriving(
                remainingSeconds: arrivalSeconds(sec: arrival.predictTimeSec1, min: arrival.predictTime1),
                locationNo: arrival.locationNo1,
              );
      };
    } catch (_) {
      // ApiException 과 공공 API 응답 파싱 오류 모두 이 정류장 카드들의 실패로만 보여준다
      resultOf = (_) => const BusCardError();
    }
    // 응답을 기다리는 사이 삭제된 카드는 _allItems 에 없으니 자연히 버려진다
    for (final item in _allItems.where((item) => item.stationId == stationId)) {
      _arrivals[keyOf(item)] = resultOf(item);
    }
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
