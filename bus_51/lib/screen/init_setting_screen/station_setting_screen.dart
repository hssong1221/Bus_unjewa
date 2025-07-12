import 'package:auto_size_text/auto_size_text.dart';
import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/theme/images.dart';
import 'package:bus_51/widgets/base_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// View
// --------------------------------------------------
class StationSettingView extends StatefulWidget {
  const StationSettingView({super.key});

  @override
  State<StationSettingView> createState() => _StationSettingViewState();
}

class _StationSettingViewState extends State<StationSettingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BusProvider>().getGPSData();
      await context.read<BusProvider>().getBusStationList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final readBusProvider = context.read<BusProvider>();
    final watchBusProvider = context.watch<BusProvider>();
    final readInitProvider = context.read<InitProvider>();

    var busStationModel = watchBusProvider.busStationModel;

    return Scaffold(
      appBar: BaseAppBar(
        title: "당신의 출발점",
        actions: [
          InkWell(
            child: Image.asset(
              Images.iconRefresh,
              scale: 3,
              width: 20,
              height: 20,
              color: Colors.white,
            ),
            onTap: () async {
              watchBusProvider.busStationModel = null;
              await context.read<BusProvider>().getGPSData();
              await context.read<BusProvider>().getBusStationList();
            },
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 15,
              children: [
                watchBusProvider.busStationModel == null
                    ? Text(
                        '현재 위치 500m 반경내에\n 있는 버스 정류장을 검색중입니다. \n잠시만 기다려주세요.',
                        style: context.textStyle.subtitleBoldMd,
                        textAlign: TextAlign.center,
                      )
                    : Text(
                        '집 앞 정류장을 선택해 주세요',
                        style: context.textStyle.subtitleBoldMd,
                      ),
                Row(
                  children: [
                    Expanded(flex: 1, child: Text("지역", style: context.textStyle.bodyMediumLg, textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text("정류장 이름", style: context.textStyle.bodyMediumLg, textAlign: TextAlign.center)),
                    Expanded(
                      flex: 2,
                      child: AutoSizeText(
                        "현재위치에서 떨어진 거리",
                        style: context.textStyle.bodyMediumLg,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        minFontSize: 1,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: busStationModel?.length ?? 0,
                      itemBuilder: (context, index) {
                        var item = busStationModel![index];
                        return InkWell(
                          child: Container(
                            height: 55,
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              spacing: 10,
                              children: [
                                Expanded(flex: 1, child: Text(item.regionName, textAlign: TextAlign.center)),
                                Expanded(
                                  flex: 2,
                                  child: AutoSizeText(
                                    item.stationName,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    minFontSize: 1,
                                  ),
                                ),
                                Expanded(flex: 2, child: Text("${item.distance} m", textAlign: TextAlign.center)),
                              ],
                            ),
                          ),
                          onTap: () {
                            readBusProvider.setSelectedStationModel(item);
                            readInitProvider.nextAccountView();
                          },
                        );
                      }),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
