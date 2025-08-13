import 'package:freezed_annotation/freezed_annotation.dart';

part 'busroute_entity.freezed.dart';
part 'busroute_entity.g.dart';

@freezed
sealed class BusRouteEntity with _$BusRouteEntity {
  const factory BusRouteEntity({
    required String regionName,
    required int routeDestId,
    required String routeDestName,
    required int routeId,
    required String routeName,
    required int routeTypeCd,
    required String routeTypeName,
    required int staOrder,
  }) = _BusRouteEntity;

  factory BusRouteEntity.fromJson(Map<String, dynamic> json) =>
      _$BusRouteEntityFromJson(json);
}
