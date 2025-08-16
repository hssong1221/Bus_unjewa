import 'package:freezed_annotation/freezed_annotation.dart';

part 'busstation_model.freezed.dart';
part 'busstation_model.g.dart';

@freezed
sealed class BusStationModel with _$BusStationModel {
  const factory BusStationModel({
    required String mobileNo,
    required String regionName,
    required int stationId,
    required String stationName,
    required int distance,
    required double x,
    required double y,
  }) = _BusStationModel;

  factory BusStationModel.fromJson(Map<String, dynamic> json) =>
      _$BusStationModelFromJson(json);
}
