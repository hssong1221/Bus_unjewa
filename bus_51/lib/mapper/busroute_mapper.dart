import 'package:bus_51/entity/busroute_entity.dart';
import 'package:bus_51/model/busroute_model.dart';

class BusRouteMapper {
  static BusRouteModel fromEntity(BusRouteEntity entity) {
    return BusRouteModel(
      regionName: entity.regionName,
      routeDestId: int.tryParse(entity.routeDestId) ?? 0,
      routeDestName: entity.routeDestName,
      routeId: int.tryParse(entity.routeId) ?? 0,
      routeName: entity.routeName,
      routeTypeCd: int.tryParse(entity.routeTypeCd) ?? 0,
      routeTypeName: entity.routeTypeName,
      staOrder: int.tryParse(entity.staOrder) ?? 0,
    );
  }

  static List<BusRouteModel> fromEntityList(List<BusRouteEntity> entities) {
    return entities.map(fromEntity).toList();
  }
}
