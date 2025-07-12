import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_main_screen.dart';
import 'package:bus_51/theme/colors.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/theme/images.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:bus_51/widgets/base_appbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// Screen
// --------------------------------------------------
class BusListScreen extends StatelessWidget {
  const BusListScreen({super.key});

  static const String routeName = "list";
  static const String routeURL = "/list";

  @override
  Widget build(BuildContext context) {
    return const BusListView();
  }
}

// --------------------------------------------------
// View
// --------------------------------------------------
class BusListView extends StatefulWidget {
  const BusListView({super.key});

  @override
  State<BusListView> createState() => _BusListViewState();
}

class _BusListViewState extends State<BusListView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final readProvider = context.read<BusProvider>();
    final watchProvider = context.watch<BusProvider>();

    var userSaveModel = watchProvider.loadUserDataList();

    return Scaffold(
      appBar: BaseAppBar(
        title: "버스 언제와",
        actions: [
          InkWell(
            child: Image.asset(
              Images.iconPlus,
              width: 24,
              height: 24,
            ),
            onTap: () {
              context.pushNamed(InitSettingScreen.routeName);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          spacing: 20,
          children: [
            Text(
              "내가 저장한 노선",
              style: context.textStyle.subtitleMediumMd,
            ),
            Expanded(
              child: ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  itemCount: userSaveModel.length,
                  itemBuilder: (context, index) {
                    var item = userSaveModel[index];
                    return InkWell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 15,
                          children: [
                            Text(
                              item.routeName.toString(),
                              style: context.textStyle.titleBoldLg.copyWith(color: BusColor().setColor(item.routeTypeCd)),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        readProvider.userDataIdx = index;

                        context.pushNamed(BusMainScreen.routeName);
                      },
                    );
                  }),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () {
                readProvider.deleteAllData();
                context.goNamed(InitSettingScreen.routeName);
              },
              child: Text("전체 삭제"),
            )
          ],
        ),
      ),
    );
  }
}
