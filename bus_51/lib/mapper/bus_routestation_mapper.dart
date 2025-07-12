import 'package:bus_51/entity/bus_routestation_entity.dart';
import 'package:bus_51/model/bus_routestation_model.dart';

class BusRouteStationMapper {
  static BusRouteStationModel fromEntity(BusRouteStationEntity entity) {
    return BusRouteStationModel(
      centerYn: entity.centerYn,
      districtCd: entity.districtCd,
      mobileNo: entity.mobileNo,
      regionName: entity.regionName,
      stationId: entity.stationId,
      stationName: entity.stationName,
      x: entity.x,
      y: entity.y,
      adminName: entity.adminName,
      stationSeq: entity.stationSeq,
      turnSeq: entity.turnSeq,
      turnYn: entity.turnYn,
    );
  }

  static List<BusRouteStationModel> fromEntityList(List<BusRouteStationEntity> entities) {
    return entities.map(fromEntity).toList();
  }
}
