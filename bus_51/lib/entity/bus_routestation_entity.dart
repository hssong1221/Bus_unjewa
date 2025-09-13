import 'package:freezed_annotation/freezed_annotation.dart';

part 'bus_routestation_entity.freezed.dart';
part 'bus_routestation_entity.g.dart';

// --------------------------------------------------
// 버스 노선 정류장 Entity
// --------------------------------------------------
// NOTE: 향후 Entity-Mapper-Model 구조를 단순화할 때
//       이 Entity를 UI에서 직접 사용 가능
//       (Model과 Mapper 제거 고려)
// --------------------------------------------------
@Freezed()
sealed class BusRouteStationEntity with _$BusRouteStationEntity {
  const factory BusRouteStationEntity({
    required String centerYn,
    required String districtCd,
    required String mobileNo,
    required String regionName,
    required String stationId,
    required String stationName,
    required String x,
    required String y,
    required String adminName,
    required String stationSeq,
    required String turnSeq,
    required String turnYn,
  }) = _BusRouteStationEntity;

  factory BusRouteStationEntity.fromJson(Map<String, dynamic> json) => _$BusRouteStationEntityFromJson(json);
}
