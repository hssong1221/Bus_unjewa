import 'package:freezed_annotation/freezed_annotation.dart';

part 'bus_routestation_entity.freezed.dart';
part 'bus_routestation_entity.g.dart';

@freezed
sealed class BusRouteStationEntity with _$BusRouteStationEntity {
  const factory BusRouteStationEntity({
    required String centerYn,
    required int districtCd,
    required String mobileNo,
    required String regionName,
    required int stationId,
    required String stationName,
    required double x,
    required double y,
    required String adminName,
    required int stationSeq,
    required int turnSeq,
    required String turnYn,
  }) = _BusRouteStationEntity;

  factory BusRouteStationEntity.fromJson(Map<String, dynamic> json) =>
      _$BusRouteStationEntityFromJson(json);
}
