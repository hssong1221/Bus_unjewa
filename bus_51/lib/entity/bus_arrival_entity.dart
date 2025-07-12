class BusArrivalEntity {
  final String crowded1;
  final String crowded2;
  final String flag;
  final String locationNo1;
  final String locationNo2;
  final String lowPlate1;
  final String lowPlate2;
  final String plateNo1;
  final String plateNo2;
  final String predictTime1;
  final String predictTime2;
  final String remainSeatCnt1;
  final String remainSeatCnt2;
  final int routeDestId;
  final String routeDestName;
  final int routeId;
  final String routeName;
  final int routeTypeCd;
  final int staOrder;
  final int stationId;
  final String stationNm1;
  final String stationNm2;
  final String taglessCd1;
  final String taglessCd2;
  final int turnSeq;
  final String vehId1;
  final String vehId2;
  final int? predictTimeSec1;
  final int? predictTimeSec2;

  BusArrivalEntity({
    required this.crowded1,
    required this.crowded2,
    required this.flag,
    required this.locationNo1,
    required this.locationNo2,
    required this.lowPlate1,
    required this.lowPlate2,
    required this.plateNo1,
    required this.plateNo2,
    required this.predictTime1,
    required this.predictTime2,
    required this.remainSeatCnt1,
    required this.remainSeatCnt2,
    required this.routeDestId,
    required this.routeDestName,
    required this.routeId,
    required this.routeName,
    required this.routeTypeCd,
    required this.staOrder,
    required this.stationId,
    required this.stationNm1,
    required this.stationNm2,
    required this.taglessCd1,
    required this.taglessCd2,
    required this.turnSeq,
    required this.vehId1,
    required this.vehId2,
    this.predictTimeSec1 = 0,
    this.predictTimeSec2 = 0,
  });

  factory BusArrivalEntity.fromJson(Map<String, dynamic> json) {
    return BusArrivalEntity(
      crowded1: json['crowded1'].toString(),
      crowded2: json['crowded2'].toString(),
      flag: json['flag'],
      locationNo1: json['locationNo1'].toString(),
      locationNo2: json['locationNo2'].toString(),
      lowPlate1: json['lowPlate1'].toString(),
      lowPlate2: json['lowPlate2'].toString(),
      plateNo1: json['plateNo1'].toString(),
      plateNo2: json['plateNo2'].toString(),
      predictTime1: json['predictTime1'].toString(),
      predictTime2: json['predictTime2'].toString(),
      remainSeatCnt1: json['remainSeatCnt1'].toString(),
      remainSeatCnt2: json['remainSeatCnt2'].toString(),
      routeDestId: json['routeDestId'],
      routeDestName: json['routeDestName'],
      routeId: json['routeId'],
      routeName: json['routeName'].toString(),
      routeTypeCd: json['routeTypeCd'],
      staOrder: json['staOrder'],
      stationId: json['stationId'],
      stationNm1: json['stationNm1'],
      stationNm2: json['stationNm2'],
      taglessCd1: json['taglessCd1'].toString(),
      taglessCd2: json['taglessCd2'].toString(),
      turnSeq: json['turnSeq'],
      vehId1: json['vehId1'].toString(),
      vehId2: json['vehId2'].toString(),
      predictTimeSec1: json['predictTimeSec1'],
      predictTimeSec2: json['predictTimeSec2'],
    );
  }
}
