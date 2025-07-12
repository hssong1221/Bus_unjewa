import 'package:flutter/material.dart';

class BusArrivalIndicator extends StatelessWidget {
  const BusArrivalIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // 점들의 간격
    double dotSpacing = MediaQuery.of(context).size.height / 4;
    // 막대 높이
    double lineHeight = MediaQuery.of(context).size.height / 2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
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
                      children: [
                        Text("data"),
                        Text("data"),
                        Text("data"),
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
                    Text("data")
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
                    Text("data")
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 점 위젯
class Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
