class BusRouteStationEntity {
  final String centerYn;
  final int districtCd;
  final String mobileNo;
  final String regionName;
  final int stationId;
  final String stationName;
  final double x;
  final double y;
  final String adminName;
  final int stationSeq;
  final int turnSeq;
  final String turnYn;

  BusRouteStationEntity({
    required this.centerYn,
    required this.districtCd,
    required this.mobileNo,
    required this.regionName,
    required this.stationId,
    required this.stationName,
    required this.x,
    required this.y,
    required this.adminName,
    required this.stationSeq,
    required this.turnSeq,
    required this.turnYn,
  });

  factory BusRouteStationEntity.fromJson(Map<String, dynamic> json) {
    return BusRouteStationEntity(
      centerYn: json['centerYn'],
      districtCd: json['districtCd'],
      mobileNo: json['mobileNo'].toString(),
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
