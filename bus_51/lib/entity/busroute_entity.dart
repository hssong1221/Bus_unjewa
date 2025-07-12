class BusRouteEntity {
  final String regionName;
  final int routeDestId;
  final String routeDestName;
  final int routeId;
  final String routeName;
  final int routeTypeCd;
  final String routeTypeName;
  final int staOrder;

  BusRouteEntity({
    required this.regionName,
    required this.routeDestId,
    required this.routeDestName,
    required this.routeId,
    required this.routeName,
    required this.routeTypeCd,
    required this.routeTypeName,
    required this.staOrder,
  });

  factory BusRouteEntity.fromJson(Map<String, dynamic> json) {
    return BusRouteEntity(
      regionName: json['regionName'],
      routeDestId: json['routeDestId'],
      routeDestName: json['routeDestName'],
      routeId: json['routeId'],
      routeName: json['routeName'].toString(),
      routeTypeCd: json['routeTypeCd'],
      routeTypeName: json['routeTypeName'],
      staOrder: json['staOrder'],
    );
  }
}
