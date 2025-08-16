// --------------------------------------------------
// 버스 노선 Model (UI용 데이터 구조)
// --------------------------------------------------
class BusRouteModel {
  final String regionName;
  final int routeDestId;
  final String routeDestName;
  final int routeId;
  final String routeName;
  final int routeTypeCd;
  final String routeTypeName;
  final int staOrder;

  const BusRouteModel({
    required this.regionName,
    required this.routeDestId,
    required this.routeDestName,
    required this.routeId,
    required this.routeName,
    required this.routeTypeCd,
    required this.routeTypeName,
    required this.staOrder,
  });

  @override
  String toString() {
    return 'BusRouteModel(regionName: $regionName, routeDestId: $routeDestId, routeDestName: $routeDestName, routeId: $routeId, routeName: $routeName, routeTypeCd: $routeTypeCd, routeTypeName: $routeTypeName, staOrder: $staOrder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusRouteModel &&
        other.regionName == regionName &&
        other.routeDestId == routeDestId &&
        other.routeDestName == routeDestName &&
        other.routeId == routeId &&
        other.routeName == routeName &&
        other.routeTypeCd == routeTypeCd &&
        other.routeTypeName == routeTypeName &&
        other.staOrder == staOrder;
  }

  @override
  int get hashCode {
    return Object.hash(regionName, routeDestId, routeDestName, routeId, routeName, routeTypeCd, routeTypeName, staOrder);
  }
}
