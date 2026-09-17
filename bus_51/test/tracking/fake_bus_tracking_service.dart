import 'dart:async';

import 'package:bus_51/tracking/bus_tracking_service.dart';
import 'package:bus_51/tracking/bus_tracking_target.dart';

/// 뷰모델·위젯 테스트용 파사드. 플러그인 없이 호출만 기록하고, 설정한 대로 답한다
class FakeBusTrackingService implements BusTrackingService {
  /// ensureNotificationsAllowed 의 답
  bool notificationsAllowed = true;

  /// start 가 성공하는가
  bool startSucceeds = true;

  /// 설정하면 이 Completer 가 완료될 때까지 start 를 붙잡는다 (켜는 중 상태를 만들 때)
  Completer<void>? startGate;

  /// 지금 추적 중인 대상 (currentTarget 의 답). start 하면 채워지고 stop·finish 하면 비워진다
  BusTrackingTarget? running;

  final List<BusTrackingTarget> started = [];
  int stopCount = 0;
  int openSettingsCount = 0;

  final StreamController<void> _finished = StreamController<void>.broadcast();

  @override
  Future<bool> ensureNotificationsAllowed() async => notificationsAllowed;

  @override
  Future<void> openNotificationSettings() async => openSettingsCount++;

  @override
  Future<bool> start(BusTrackingTarget target) async {
    if (startGate != null) await startGate!.future;
    if (!startSucceeds) return false;
    started.add(target);
    running = target;
    return true;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    running = null;
  }

  @override
  Future<BusTrackingTarget?> currentTarget() async => running;

  @override
  Stream<void> get onFinished => _finished.stream;

  /// 서비스가 스스로 끝난 상황(도착·차량 변경·알림의 "끄기")을 흉내 낸다
  void finish() {
    running = null;
    _finished.add(null);
  }
}
