import 'package:freezed_annotation/freezed_annotation.dart';

part 'busroute_model.freezed.dart';
part 'busroute_model.g.dart';

@freezed
sealed class BusRouteModel with _$BusRouteModel {
  const factory BusRouteModel({
    required String regionName,
    required int routeDestId,
    required String routeDestName,
    required int routeId,
    required String routeName,
    required int routeTypeCd,
    required String routeTypeName,
    required int staOrder,
  }) = _BusRouteModel;

  factory BusRouteModel.fromJson(Map<String, dynamic> json) =>
      _$BusRouteModelFromJson(json);
}
