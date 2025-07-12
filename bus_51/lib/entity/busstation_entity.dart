class BusStationEntity {
  final String centerYn;
  final String mobileNo;    // 정류소 번호
  final String regionName;
  final int stationId;      // 정류소 id
  final String stationName; // 정류소 이름
  final double x;
  final double y;
  final int distance;

  BusStationEntity({
    required this.centerYn,
    required this.mobileNo,
    required this.regionName,
    required this.stationId,
    required this.stationName,
    required this.x,
    required this.y,
    required this.distance,
  });

  factory BusStationEntity.fromJson(Map<String, dynamic> json) {
    return BusStationEntity(
      centerYn: json['centerYn'],
      mobileNo: json['mobileNo'],
      regionName: json['regionName'],
      stationId: json['stationId'],
      stationName: json['stationName'],
      x: json['x'],
      y: json['y'],
      distance: json['distance'],
    );
  }
}
