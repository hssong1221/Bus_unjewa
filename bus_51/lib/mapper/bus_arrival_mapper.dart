import 'package:bus_51/entity/bus_arrival_entity.dart';
import 'package:bus_51/model/bus_arrival_model.dart';

class BusArrivalMapper {
  static BusArrivalModel fromEntity(BusArrivalEntity entity) {
    return BusArrivalModel(
      predictTime1: entity.predictTime1,
      predictTime2: entity.predictTime2,
      predictTimeSec1: int.tryParse(entity.predictTimeSec1 ?? '0'),
      predictTimeSec2: int.tryParse(entity.predictTimeSec2 ?? '0'),
      locationNo1: entity.locationNo1,
      locationNo2: entity.locationNo2,
      stationNm1: entity.stationNm1,
      stationNm2: entity.stationNm2,
      flag: entity.flag,
      routeDestName: entity.routeDestName,
      routeId: int.tryParse(entity.routeId) ?? 0,
      stationId: int.tryParse(entity.stationId) ?? 0,
    );
  }

  static List<BusArrivalModel> fromEntityList(List<BusArrivalEntity> entities) {
    return entities.map(fromEntity).toList();
  }
}
