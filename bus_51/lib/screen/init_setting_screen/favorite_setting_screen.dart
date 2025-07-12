import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/screen/main_screen/bus_list_screen.dart';
import 'package:bus_51/theme/colors.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/theme/images.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:bus_51/widgets/base_appbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// View
// --------------------------------------------------
class FavoriteSettingView extends StatefulWidget {
  const FavoriteSettingView({super.key});

  @override
  State<FavoriteSettingView> createState() => _FavoriteSettingViewState();
}

class _FavoriteSettingViewState extends State<FavoriteSettingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BusProvider>().getRouteStationList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final readBusProvider = context.read<BusProvider>();
    final watchBusProvider = context.watch<BusProvider>();
    final readInitProvider = context.read<InitProvider>();

    return Scaffold(
      appBar: BaseAppBar(
        title: "버스 저장",
        isBackButtonCustom: true,
        onPressed_notRouter: () {
          readInitProvider.prevAccountView();
        },
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 15,
              children: [
                Text(
                  watchBusProvider.selectedRouteModel?.routeName ?? "버스 노선",
                  style: context.textStyle.titleBoldLg.copyWith(
                    color: BusColor().setColor(watchBusProvider.selectedRouteModel!.routeTypeCd),
                  ),
                ),
                const SizedBox.shrink(),
                Text(watchBusProvider.prevStationModel?.stationName ?? "전 전류장"),
                Image.asset(Images.iconArrowDown, color: CustomColors.commonBlack, scale: 3),
                Text("${watchBusProvider.curStationModel?.stationName} (선택한 정류장)", style: context.textStyle.bodyBoldLg),
                Image.asset(Images.iconArrowDown, color: CustomColors.commonBlack, scale: 3),
                Text(watchBusProvider.nextStationModel?.stationName ?? "다음 정류장"),
                Image.asset(Images.iconArrowDown, color: CustomColors.commonBlack, scale: 3),
                Image.asset(Images.iconArrowDown, color: CustomColors.commonBlack, scale: 3),
                Image.asset(Images.iconArrowDown, color: CustomColors.commonBlack, scale: 3),
                Text(watchBusProvider.selectedRouteModel?.routeDestName ?? "최종 목적지"),
                const Text("방향이 맞으면 저장버튼을 눌러주세요"),
                OutlinedButton(
                  onPressed: () async {
                    String routeName = readBusProvider.selectedRouteModel!.routeName;
                    int stationId = readBusProvider.curStationModel!.stationId;
                    int routeId = readBusProvider.selectedRouteModel!.routeId;
                    int staOrder = readBusProvider.curStationModel!.stationSeq;
                    int routeTypeCd = readBusProvider.selectedRouteModel!.routeTypeCd;

                    debugPrint("$routeName $stationId $routeId $staOrder $routeTypeCd");

                    final order = UserSaveModel(
                      routeName: routeName,
                      stationId: stationId,
                      routeId: routeId,
                      staOrder: staOrder,
                      routeTypeCd: routeTypeCd,
                    );

                    await readBusProvider.saveUserDataList(order);
                    await context.pushNamed(BusListScreen.routeName);
                  },
                  child: const Text("save"),
                ),
                /*Row(
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        var model = readBusProvider.loadUserDataList();
                        debugPrint(model[0].routeName.toString());
                        debugPrint(model[0].staOrder.toString());
                        debugPrint(model[0].stationId.toString());
                        debugPrint(model[0].routeId.toString());
                      },
                      child: const Text("load"),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        readBusProvider.deleteAllData();
                      },
                      child: const Text("delete"),
                    ),
                  ],
                )*/
              ],
            ),
          ),
        ),
      ),
    );
  }
}
