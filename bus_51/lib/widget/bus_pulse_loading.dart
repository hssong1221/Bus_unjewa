import 'package:bus_51/utils/bus_color.dart';
import 'package:flutter/material.dart';

// --------------------------------------------------
// Bus Pulse Loading Indicator with Bus Type Color Support
// --------------------------------------------------

/// 버스 펄스 로딩 인디케이터 - 버스 종류별 색상 지원
class BusPulseLoading extends StatefulWidget {
  final double size;
  final Color? color;
  final int? busType;
  final Duration duration;
  final String? text;
  final TextStyle? textStyle;

  /// 직접 색상을 지정하는 생성자
  const BusPulseLoading({
    super.key,
    this.size = 32.0,
    required this.color,
    this.busType,
    this.duration = const Duration(milliseconds: 1200),
    this.text,
    this.textStyle,
  }) : assert(color != null || busType != null, 'color 또는 busType 중 하나는 필수입니다');

  /// 버스 타입으로 색상을 자동 설정하는 생성자
  const BusPulseLoading.fromBusType({
    super.key,
    this.size = 32.0,
    required this.busType,
    this.color,
    this.duration = const Duration(milliseconds: 1200),
    this.text,
    this.textStyle,
  }) : assert(color != null || busType != null, 'color 또는 busType 중 하나는 필수입니다');

  /// 기본 색상 (Primary)으로 생성하는 생성자
  const BusPulseLoading.primary({
    super.key,
    this.size = 32.0,
    this.color,
    this.busType,
    this.duration = const Duration(milliseconds: 1200),
    this.text,
    this.textStyle,
  });

  @override
  State<BusPulseLoading> createState() => _BusPulseLoadingState();
}

class _BusPulseLoadingState extends State<BusPulseLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _controller.repeat(reverse: true);
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getIndicatorColor() {
    // 1. 직접 지정된 색상이 있으면 우선 사용
    if (widget.color != null) {
      return widget.color!;
    }
    
    // 2. busType이 있으면 BusColor로 색상 결정
    if (widget.busType != null) {
      return BusColor().setColor(widget.busType!);
    }
    
    // 3. 둘 다 없으면 Theme의 primary 색상 사용
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final indicatorColor = _getIndicatorColor();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Icon(
                  Icons.directions_bus_rounded,
                  size: widget.size,
                  color: indicatorColor,
                ),
              ),
            );
          },
        ),
        if (widget.text != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.text!,
            style: widget.textStyle ?? 
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ],
    );
  }
}

// --------------------------------------------------
// Bus Type Color Extensions
// --------------------------------------------------

/// 버스 타입 상수들
class BusTypes {
  static const int redBus = 11;        // 간선급행버스 (빨강)
  static const int redBusAlt = 16;     // 간선급행버스 대체 (빨강)
  static const int blueBus = 12;       // 간선버스 (파랑)
  static const int blueBusAlt = 14;    // 간선버스 대체 (파랑)
  static const int greenBus = 13;      // 지선버스 (초록)
  static const int purpleBus = 15;     // 광역급행버스 (보라)
  static const int yellowBus = 30;     // 마을버스 (노랑)
  
  // 공항버스들
  static const int airportBus1 = 41;
  static const int airportBus2 = 42;
  static const int airportBus3 = 43;
  
  // 농어촌버스들  
  static const int ruralBus1 = 51;
  static const int ruralBus2 = 52;
  static const int ruralBus3 = 53;
}

/// 버스 타입별 로딩 인디케이터 편의 생성자들
extension BusPulseLoadingExtensions on BusPulseLoading {
  /// 빨간 버스 (간선급행)
  static BusPulseLoading red({
    double size = 32.0,
    Duration duration = const Duration(milliseconds: 1200),
    String? text,
    TextStyle? textStyle,
  }) {
    return BusPulseLoading.fromBusType(
      size: size,
      busType: BusTypes.redBus,
      duration: duration,
      text: text,
      textStyle: textStyle,
    );
  }

  /// 파란 버스 (간선)
  static BusPulseLoading blue({
    double size = 32.0,
    Duration duration = const Duration(milliseconds: 1200),
    String? text,
    TextStyle? textStyle,
  }) {
    return BusPulseLoading.fromBusType(
      size: size,
      busType: BusTypes.blueBus,
      duration: duration,
      text: text,
      textStyle: textStyle,
    );
  }

  /// 초록 버스 (지선)
  static BusPulseLoading green({
    double size = 32.0,
    Duration duration = const Duration(milliseconds: 1200),
    String? text,
    TextStyle? textStyle,
  }) {
    return BusPulseLoading.fromBusType(
      size: size,
      busType: BusTypes.greenBus,
      duration: duration,
      text: text,
      textStyle: textStyle,
    );
  }

  /// 보라 버스 (광역급행)
  static BusPulseLoading purple({
    double size = 32.0,
    Duration duration = const Duration(milliseconds: 1200),
    String? text,
    TextStyle? textStyle,
  }) {
    return BusPulseLoading.fromBusType(
      size: size,
      busType: BusTypes.purpleBus,
      duration: duration,
      text: text,
      textStyle: textStyle,
    );
  }

  /// 노란 버스 (마을)
  static BusPulseLoading yellow({
    double size = 32.0,
    Duration duration = const Duration(milliseconds: 1200),
    String? text,
    TextStyle? textStyle,
  }) {
    return BusPulseLoading.fromBusType(
      size: size,
      busType: BusTypes.yellowBus,
      duration: duration,
      text: text,
      textStyle: textStyle,
    );
  }
}