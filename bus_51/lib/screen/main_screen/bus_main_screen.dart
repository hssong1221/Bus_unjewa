import 'dart:async';

import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/provider/timer_provider.dart';
import 'package:bus_51/utils/bus_color.dart';
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

class _BusMainViewState extends State<BusMainView> with TickerProviderStateMixin {
  late Timer _timer;
  late var userSaveModel;
  late var idx;
  late UserSaveModel userModel;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    final readProvider = context.read<BusProvider>();
    final readTimerProvider = context.read<TimerProvider>();

    userSaveModel = readProvider.loadUserDataList();
    idx = readProvider.userDataIdx;
    userModel = userSaveModel[idx];

    _fadeController.forward();
    _pulseController.repeat(reverse: true);

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
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final readProvider = context.read<BusProvider>();
    final watchProvider = context.watch<BusProvider>();
    final readTimerProvider = context.read<TimerProvider>();
    final watchTimerProvider = context.watch<TimerProvider>();

    var item = watchProvider.busArrivalModel;

    if (item == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.surface,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '버스 정보를 불러오는 중...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BusColor().setColor(userModel.routeTypeCd).withValues(alpha: 0.05),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BusColor().setColor(userModel.routeTypeCd).withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Connection Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: item.flag == "PASS" ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.flag == "PASS" ? "실시간 연결됨" : "연결 끊김",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: item.flag == "PASS" ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Route Number
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          decoration: BoxDecoration(
                            color: BusColor().setColor(userModel.routeTypeCd).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            userModel.routeName,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: BusColor().setColor(userModel.routeTypeCd),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Bus Arrival Information
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Second Bus
                          _buildBusInfo(
                            context,
                            "2번째 버스",
                            "${item.stationNm2} - ${item.locationNo2}정거장 전",
                            "${(watchTimerProvider.remainingSeconds2 ~/ 60).toString().padLeft(2, '0')}분 ${(watchTimerProvider.remainingSeconds2 % 60).toString().padLeft(2, '0')}초",
                            colorScheme.onSurface.withValues(alpha: 0.6),
                            Icons.directions_bus_outlined,
                            false,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Route Line
                          Container(
                            height: 2,
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // First Bus (Next)
                          _buildBusInfo(
                            context,
                            "다음 버스",
                            "${item.stationNm1} - ${item.locationNo1}정거장 전",
                            "${(watchTimerProvider.remainingSeconds1 ~/ 60).toString().padLeft(2, '0')}분 ${(watchTimerProvider.remainingSeconds1 % 60).toString().padLeft(2, '0')}초",
                            colorScheme.primary,
                            Icons.directions_bus,
                            true,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Current Station
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.my_location,
                                  color: colorScheme.secondary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "현재 위치",
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      Text(
                                        readProvider.selectedStationModel?.stationName ?? "선택한 정류장",
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Refresh Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await readProvider.getBusArrivalTimeList(
                          stationId: userModel.stationId.toString(),
                          routeId: userModel.routeId.toString(),
                          staOrder: userModel.staOrder.toString(),
                        );

                        var updatedItem = readProvider.busArrivalModel;
                        readTimerProvider.setTimerFromApi(
                          updatedItem?.predictTimeSec1 ?? 0, 
                          updatedItem?.predictTimeSec2 ?? 0
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        "정보 새로고침",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusInfo(
    BuildContext context, 
    String title, 
    String location, 
    String time, 
    Color color, 
    IconData icon,
    bool isNext,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNext ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isNext ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isNext ? color : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$time 후 도착",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isNext ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
