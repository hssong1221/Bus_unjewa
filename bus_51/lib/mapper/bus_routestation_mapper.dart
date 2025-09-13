import 'package:bus_51/entity/bus_routestation_entity.dart';
import 'package:bus_51/model/bus_routestation_model.dart';

class BusRouteStationMapper {
  static BusRouteStationModel fromEntity(BusRouteStationEntity entity) {
    return BusRouteStationModel(
      centerYn: entity.centerYn,
      districtCd: int.tryParse(entity.districtCd) ?? 0,
      mobileNo: entity.mobileNo,
      regionName: entity.regionName,
      stationId: int.tryParse(entity.stationId) ?? 0,
      stationName: entity.stationName,
      x: double.tryParse(entity.x) ?? 0.0,
      y: double.tryParse(entity.y) ?? 0.0,
      adminName: entity.adminName,
      stationSeq: int.tryParse(entity.stationSeq) ?? 0,
      turnSeq: int.tryParse(entity.turnSeq) ?? 0,
      turnYn: entity.turnYn,
    );
  }

  static List<BusRouteStationModel> fromEntityList(List<BusRouteStationEntity> entities) {
    return entities.map(fromEntity).toList();
  }
}
