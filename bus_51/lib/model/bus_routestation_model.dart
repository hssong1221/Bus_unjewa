import 'package:freezed_annotation/freezed_annotation.dart';

part 'bus_routestation_model.freezed.dart';
part 'bus_routestation_model.g.dart';

@freezed
sealed class BusRouteStationModel with _$BusRouteStationModel {
  const factory BusRouteStationModel({
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
  }) = _BusRouteStationModel;

  factory BusRouteStationModel.fromJson(Map<String, dynamic> json) =>
      _$BusRouteStationModelFromJson(json);
}
