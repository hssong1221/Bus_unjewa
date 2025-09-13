import 'package:bus_51/entity/busstation_entity.dart';
import 'package:bus_51/model/busstation_model.dart';

class BusStationMapper {
  static BusStationModel fromEntity(BusStationEntity entity) {
    return BusStationModel(
      mobileNo: entity.mobileNo,
      regionName: entity.regionName,
      stationId: int.tryParse(entity.stationId) ?? 0,
      stationName: entity.stationName,
      distance: int.tryParse(entity.distance) ?? 0,
      x: double.tryParse(entity.x) ?? 0.0,
      y: double.tryParse(entity.y) ?? 0.0,
    );
  }

  static List<BusStationModel> fromEntityList(List<BusStationEntity> entities) {
    return entities.map(fromEntity).toList();
  }
}
