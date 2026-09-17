import 'dart:convert';

// --------------------------------------------------
// 도착 알림 추적 대상
// 앱이 서비스를 켤 때 저장해 두고, 서비스 isolate 가 읽어 BusTracker 를 만든다.
// 화면 복귀 시 "지금 보고 있는 버스를 추적 중인가"를 판단하는 데도 쓴다
// --------------------------------------------------
class BusTrackingTarget {
  const BusTrackingTarget({
    required this.stationId,
    required this.routeId,
    required this.staOrder,
    required this.routeName,
    required this.plateNo,
    required this.remainingSeconds,
  });

  /// flutter_foreground_task 저장소 키
  static const String storageKey = 'bus_tracking_target';

  final int stationId;
  final int routeId;
  final int staOrder;
  final String routeName;

  /// 켤 때 첫 번째 버스 차량번호. 조회 결과와 다르면 그 버스는 지나간 것
  final String plateNo;

  /// 켤 때 남은 초. 서비스는 여기서부터 카운트다운을 이어간다
  final int remainingSeconds;

  /// 저장된 버스(정류장·노선·순번)와 같은 버스인가
  bool isSameBus({required int stationId, required int routeId, required int staOrder}) =>
      this.stationId == stationId && this.routeId == routeId && this.staOrder == staOrder;

  Map<String, dynamic> toJson() => {
        'stationId': stationId,
        'routeId': routeId,
        'staOrder': staOrder,
        'routeName': routeName,
        'plateNo': plateNo,
        'remainingSeconds': remainingSeconds,
      };

  factory BusTrackingTarget.fromJson(Map<String, dynamic> json) => BusTrackingTarget(
        stationId: json['stationId'] as int,
        routeId: json['routeId'] as int,
        staOrder: json['staOrder'] as int,
        routeName: json['routeName'] as String,
        plateNo: json['plateNo'] as String,
        remainingSeconds: json['remainingSeconds'] as int,
      );

  String encode() => jsonEncode(toJson());

  static BusTrackingTarget decode(String source) =>
      BusTrackingTarget.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      other is BusTrackingTarget &&
      other.stationId == stationId &&
      other.routeId == routeId &&
      other.staOrder == staOrder &&
      other.routeName == routeName &&
      other.plateNo == plateNo &&
      other.remainingSeconds == remainingSeconds;

  @override
  int get hashCode => Object.hash(stationId, routeId, staOrder, routeName, plateNo, remainingSeconds);

  @override
  String toString() => 'BusTrackingTarget(${toJson()})';
}
