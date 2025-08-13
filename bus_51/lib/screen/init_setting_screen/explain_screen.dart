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
class ExplainScreenView extends StatefulWidget {
  const ExplainScreenView({super.key});

  @override
  State<ExplainScreenView> createState() => _ExplainScreenViewState();
}

class _ExplainScreenViewState extends State<ExplainScreenView> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final readProvider = context.read<BusProvider>();
      readProvider.testConnect(item_id: "1", q: "hello world");
    });
  }
  @override
  Widget build(BuildContext context) {
    final readBusProvider = context.read<BusProvider>();
    final watchBusProvider = context.watch<BusProvider>();
    final readInitProvider = context.read<InitProvider>();

    return Scaffold(
      appBar: const BaseAppBar(
        title: "회사가기 싫지만",
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 30,
            children: [
              Text(
                " 매일 집 앞 정류장에서\n 똑같은 버스를 타고\n 회사를 가는 직장인들을 위한",
                style: context.textStyle.titleBoldLg,
                textAlign: TextAlign.center,
              ),
              InkWell(
                child: Image.asset(
                  Images.iconArrowFront,
                  color: Colors.black,
                ),
                onTap: () {
                  readInitProvider.nextAccountView();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
