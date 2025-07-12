import 'package:get_storage/get_storage.dart';

class UserSaveModel {
  UserSaveModel({
    required this.routeName,
    required this.stationId,
    required this.routeId,
    required this.staOrder,
    required this.routeTypeCd,
  });

  final String routeName;
  final int stationId;
  final int routeId;
  final int staOrder;
  final int routeTypeCd;


  Map<String, dynamic> toMap() => {
    'routeName': routeName,
    'stationId': stationId,
    'routeId': routeId,
    'staOrder': staOrder,
    'routeTypeCd': routeTypeCd,
  };

  factory UserSaveModel.fromMap(Map<String, dynamic> map) {
    return UserSaveModel(
      routeName: map['routeName'],
      stationId: map['stationId'],
      routeId: map['routeId'],
      staOrder: map['staOrder'],
      routeTypeCd: map['routeTypeCd'],
    );
  }
}