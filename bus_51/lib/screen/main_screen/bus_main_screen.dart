import 'dart:async';

import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/provider/timer_provider.dart';
import 'package:bus_51/screen/main_screen/widget/bus_arrival_indicator.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:bus_51/widgets/base_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// Screen
// --------------------------------------------------
class BusMainScreen extends StatelessWidget {
  const BusMainScreen({super.key});

  static const String routeName = "main";
  static const String routeURL = "/main";

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TimerProvider(),
        ),
      ],
      child: const BusMainView(),
    );
  }
}

// --------------------------------------------------
// View
// --------------------------------------------------
class BusMainView extends StatefulWidget {
  const BusMainView({super.key});

  @override
  State<BusMainView> createState() => _BusMainViewState();
}

class _BusMainViewState extends State<BusMainView> {
  late Timer _timer;
  late var userSaveModel;
  late var idx;
  late UserSaveModel userModel;

  @override
  void initState() {
    super.initState();
    final readProvider = context.read<BusProvider>();
    final readTimerProvider = context.read<TimerProvider>();

    userSaveModel = readProvider.loadUserDataList();
    idx = readProvider.userDataIdx;
    userModel = userSaveModel[idx];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await readProvider.getBusArrivalTimeList(
        stationId: userModel.stationId.toString(),
        routeId: userModel.routeId.toString(),
        staOrder: userModel.staOrder.toString(),
      );

      var item = readProvider.busArrivalModel;
      readTimerProvider.setTimerFromApi(item?.predictTimeSec1 ?? 0, item?.predictTimeSec2 ?? 0);
      // 진짜 시간 갱신
      _startTimer(userModel);
    });
  }

  void _startTimer(UserSaveModel userModel) {
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      await context.read<BusProvider>().getBusArrivalTimeList(
            stationId: userModel.stationId.toString(),
            routeId: userModel.routeId.toString(),
            staOrder: userModel.staOrder.toString(),
          );

      var item = context.read<BusProvider>().busArrivalModel;
      context.read<TimerProvider>().setTimerFromApi(item?.predictTimeSec1 ?? 0, item?.predictTimeSec2 ?? 0);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readProvider = context.read<BusProvider>();
    final watchProvider = context.watch<BusProvider>();
    final readTimerProvider = context.read<TimerProvider>();
    final watchTimerProvider = context.watch<TimerProvider>();

    // 점들의 간격
    final double dotSpacing = MediaQuery.of(context).size.height / 4;
    // 막대 높이
    final double lineHeight = MediaQuery.of(context).size.height / 2;

    var item = watchProvider.busArrivalModel;

    if (item == null) {
      return const Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: BaseAppBar(
        title: "버스 언제와",
        backgroundColor: BusColor().setColor(userModel.routeTypeCd),
      ),
      body: Column(
        spacing: 20,
        children: [
          Text(item.flag == "PASS" ? "네트워크에 연결되었습니다." : "네트워크 연결이 끊겼습니다."),
          Center(
            child: Text(
              userModel.routeName,
              style: context.textStyle.titleBoldLg.copyWith(color: BusColor().setColor(userModel.routeTypeCd)),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              // 좌측 막대와 점
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: lineHeight + 20,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 세로 막대
                    Positioned(
                      left: 20,
                      top: 20,
                      bottom: 8,
                      child: Container(
                        width: 2,
                        height: lineHeight,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    // 점 3개
                    Positioned(
                      left: 15,
                      top: 20,
                      child: Row(
                        spacing: 20,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Dot(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 15,
                            children: [
                              Text(
                                "두번째 버스",
                                style: context.textStyle.bodyRegularLg,
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${item.stationNm2} - ",
                                      style: context.textStyle.bodyRegularLg,
                                    ),
                                    TextSpan(
                                      text: "${item.locationNo2}",
                                      style: context.textStyle.subtitleRegularMd,
                                    ),
                                    TextSpan(
                                      text: " 정거장 전",
                                      style: context.textStyle.bodyRegularLg,
                                    )
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: SizedBox(
                                        width: 75,
                                        child: Text(
                                          "${(watchTimerProvider.remainingSeconds2 ~/ 60).toString().padLeft(2, '0')}분 "
                                              "${(watchTimerProvider.remainingSeconds2 % 60).toString().padLeft(2, '0')}초",
                                          style: context.textStyle.subtitleRegularMd,
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: " 뒤에 도착 예정",
                                      style: context.textStyle.bodyRegularLg,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    Positioned(
                      left: 15,
                      top: dotSpacing,
                      child: Row(
                        spacing: 20,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Dot(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 15,
                            children: [
                              Text(
                                "첫번째 버스",
                                style: context.textStyle.bodyBoldLg,
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${item.stationNm1} - ",
                                      style: context.textStyle.bodyBoldLg,
                                    ),
                                    TextSpan(
                                      text: "${item.locationNo1}",
                                      style: context.textStyle.subtitleBoldMd,
                                    ),
                                    TextSpan(
                                      text: " 정거장 전",
                                      style: context.textStyle.bodyBoldLg,
                                    )
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: SizedBox(
                                        width: 100,
                                        child: Text(
                                          "${(watchTimerProvider.remainingSeconds1 ~/ 60).toString().padLeft(2, '0')}분 "
                                          "${(watchTimerProvider.remainingSeconds1 % 60).toString().padLeft(2, '0')}초",
                                          style: context.textStyle.titleMediumLg,
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: " 뒤에 도착 예정",
                                      style: context.textStyle.bodyRegularLg,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 15,
                      top: dotSpacing * 2,
                      child: Row(
                        spacing: 20,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Dot(),
                          Text(
                            readProvider.selectedStationModel?.stationName ?? "내가 선택한 정류장",
                            style: context.textStyle.bodyRegularLg,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              readProvider.getBusArrivalTimeList(
                stationId: userModel.stationId.toString(),
                routeId: userModel.routeId.toString(),
                staOrder: userModel.staOrder.toString(),
              );

              var item = readProvider.busArrivalModel;
              readTimerProvider.setTimerFromApi(item?.predictTimeSec1 ?? 0, item?.predictTimeSec2 ?? 0);
            },
            child: const Text("갱신 버튼"),
          ),
        ],
      ),
    );
  }
}
