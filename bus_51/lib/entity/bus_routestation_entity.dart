import 'package:bus_51/utils/safe_string_converter.dart';
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
  @SafeStringConverter()
  const factory BusRouteStationEntity({
    @Default('') String centerYn,
    @Default('') String districtCd,
    @Default('') String mobileNo,
    @Default('') String regionName,
    @Default('') String stationId,
    @Default('') String stationName,
    @Default('') String x,
    @Default('') String y,
    @Default('') String adminName,
    @Default('') String stationSeq,
    @Default('') String turnSeq,
    @Default('') String turnYn,
  }) = _BusRouteStationEntity;

  factory BusRouteStationEntity.fromJson(Map<String, dynamic> json) => _$BusRouteStationEntityFromJson(json);
}
