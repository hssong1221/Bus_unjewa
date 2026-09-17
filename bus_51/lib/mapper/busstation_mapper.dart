import 'package:bus_51/entity/busstation_entity.dart';
import 'package:bus_51/model/busstation_model.dart';

class BusStationMapper {
  static BusStationModel fromEntity(BusStationEntity entity) {
    return BusStationModel(
      mobileNo: entity.mobileNo,
      regionName: entity.regionName,
      stationId: entity.stationId,
      stationName: entity.stationName,
      distance: entity.distance,
      x: entity.x,
      y: entity.y,
    );
  }

  static List<BusStationModel> fromEntityList(List<BusStationEntity> entities) {
    return entities.map(fromEntity).toList();
  }
}
