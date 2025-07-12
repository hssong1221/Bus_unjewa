import 'package:bus_51/entity/busroute_entity.dart';
import 'package:bus_51/model/busroute_model.dart';

class BusRouteMapper {
  static BusRouteModel fromEntity(BusRouteEntity entity) {
    return BusRouteModel(
      regionName: entity.regionName,
      routeDestId: entity.routeDestId,
      routeDestName: entity.routeDestName,
      routeId: entity.routeId,
      routeName: entity.routeName,
      routeTypeCd: entity.routeTypeCd,
      routeTypeName: entity.routeTypeName,
      staOrder: entity.staOrder,
    );
  }

  static List<BusRouteModel> fromEntityList(List<BusRouteEntity> entities) {
    return entities.map(fromEntity).toList();
  }
}
