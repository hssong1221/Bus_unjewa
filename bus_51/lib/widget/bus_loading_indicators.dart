import 'package:flutter/material.dart';
import 'dart:math' as math;

// --------------------------------------------------
// Bus Loading Indicators Collection
// --------------------------------------------------

/// 1. 버스 아이콘 회전 인디케이터
class BusRotatingIndicator extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const BusRotatingIndicator({
    super.key,
    this.size = 32.0,
    this.color = Colors.blue,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<BusRotatingIndicator> createState() => _BusRotatingIndicatorState();
}

class _BusRotatingIndicatorState extends State<BusRotatingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Icon(
            Icons.directions_bus_rounded,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// 2. 버스 좌우 이동 인디케이터
class BusBouncingIndicator extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const BusBouncingIndicator({
    super.key,
    this.size = 32.0,
    this.color = Colors.blue,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<BusBouncingIndicator> createState() => _BusBouncingIndicatorState();
}

class _BusBouncingIndicatorState extends State<BusBouncingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value * 20, 0),
          child: Icon(
            Icons.directions_bus_rounded,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// 3. 정류장 + 버스 회전 인디케이터
class BusStationIndicator extends StatefulWidget {
  final double size;
  final Color busColor;
  final Color stationColor;
  final Duration duration;

  const BusStationIndicator({
    super.key,
    this.size = 60.0,
    this.busColor = Colors.blue,
    this.stationColor = Colors.grey,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<BusStationIndicator> createState() => _BusStationIndicatorState();
}

class _BusStationIndicatorState extends State<BusStationIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 중앙 정류장 아이콘
          Icon(
            Icons.location_on_rounded,
            size: widget.size * 0.4,
            color: widget.stationColor,
          ),
          // 회전하는 버스 아이콘
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: Transform.translate(
                  offset: Offset(widget.size * 0.3, 0),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    size: widget.size * 0.25,
                    color: widget.busColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 4. 점선 원형 버스 노선 인디케이터
class BusRouteIndicator extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final double strokeWidth;

  const BusRouteIndicator({
    super.key,
    this.size = 40.0,
    this.color = Colors.blue,
    this.duration = const Duration(seconds: 2),
    this.strokeWidth = 3.0,
  });

  @override
  State<BusRouteIndicator> createState() => _BusRouteIndicatorState();
}

class _BusRouteIndicatorState extends State<BusRouteIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: BusRoutePainter(
            progress: _controller.value,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class BusRoutePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  BusRoutePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // 점선 원형 그리기
    const int dashCount = 12;
    const double dashLength = 2 * math.pi / dashCount;
    
    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * dashLength) + (progress * 2 * math.pi);
      final double endAngle = startAngle + dashLength * 0.6;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BusRoutePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 5. 버스 펄스 인디케이터
class BusPulseIndicator extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const BusPulseIndicator({
    super.key,
    this.size = 32.0,
    this.color = Colors.blue,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<BusPulseIndicator> createState() => _BusPulseIndicatorState();
}

class _BusPulseIndicatorState extends State<BusPulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
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
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(
              Icons.directions_bus_rounded,
              size: widget.size,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}