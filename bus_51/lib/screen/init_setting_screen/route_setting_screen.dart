import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:bus_51/widgets/base_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// View
// --------------------------------------------------
class RouteSettingView extends StatefulWidget {
  const RouteSettingView({super.key});

  @override
  State<RouteSettingView> createState() => _RouteSettingViewState();
}

class _RouteSettingViewState extends State<RouteSettingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BusProvider>().getBusRouteList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final readBusProvider = context.read<BusProvider>();
    final watchBusProvider = context.watch<BusProvider>();
    final readInitProvider = context.read<InitProvider>();

    var busRouteModel = watchBusProvider.busRouteModel;

    return Scaffold(
      appBar: BaseAppBar(
        title: "버스 노선",
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
                const Row(
                  children: [
                    Expanded(flex: 1, child: Text("노선 번호", textAlign: TextAlign.center)),
                    Expanded(flex: 1, child: Text("버스 종류", textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text("버스 노선 방향", textAlign: TextAlign.center)),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: busRouteModel?.length ?? 0,
                      itemBuilder: (context, index) {
                        var item = busRouteModel![index];
                        return InkWell(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              spacing: 10,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    item.routeName,
                                    style: context.textStyle.titleBoldLg.copyWith(color: BusColor().setColor(item.routeTypeCd)),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(flex: 1, child: Text(item.routeTypeName, textAlign: TextAlign.center)),
                                Expanded(flex: 2, child: Text("${item.routeDestName} 방향", textAlign: TextAlign.center)),
                              ],
                            ),
                          ),
                          onTap: () {
                            readBusProvider.setSelectedRouteModel(item);
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
