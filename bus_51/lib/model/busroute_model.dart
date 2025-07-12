class BusRouteModel {
  final String regionName;
  final int routeDestId;
  final String routeDestName;
  final int routeId;
  final String routeName;
  final int routeTypeCd;
  final String routeTypeName;
  final int staOrder;

  BusRouteModel({
    required this.regionName,
    required this.routeDestId,
    required this.routeDestName,
    required this.routeId,
    required this.routeName,
    required this.routeTypeCd,
    required this.routeTypeName,
    required this.staOrder,
  });
}
