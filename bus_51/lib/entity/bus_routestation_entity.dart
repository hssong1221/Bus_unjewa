import 'package:freezed_annotation/freezed_annotation.dart';

part 'bus_routestation_entity.freezed.dart';
part 'bus_routestation_entity.g.dart';

@Freezed(fromJson: false)
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

  factory BusRouteStationEntity.fromJson(Map<String, dynamic> json) {
    return BusRouteStationEntity(
      centerYn: json['centerYn'],
      districtCd: json['districtCd'],
      mobileNo: json['mobileNo'].toString(), // 명시적 변환
      regionName: json['regionName'],
      stationId: json['stationId'],
      stationName: json['stationName'],
      x: json['x'],
      y: json['y'],
      adminName: json['adminName'],
      stationSeq: json['stationSeq'],
      turnSeq: json['turnSeq'],
      turnYn: json['turnYn'],
    );
  }
}
