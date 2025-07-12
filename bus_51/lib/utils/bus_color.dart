import 'package:bus_51/theme/colors.dart';
import 'package:flutter/material.dart';

class BusColor {
  Color setColor(int busType) {
    Color color = CustomColors.commonBlack;
    switch (busType) {
      case 11:
      case 16:
        color = CustomColors.light.busRed;
        break;
      case 12:
      case 14:
        color = CustomColors.light.busBlue;
        break;
      case 13:
        color = CustomColors.light.busGreen;
        break;
      case 15:
        color = CustomColors.light.busPurple;
        break;
      case 30:
        color = CustomColors.light.busYellow;
        break;
      case 41:
      case 42:
      case 43:
      case 51:
      case 52:
      case 53:
        break;
      default:
        color = CustomColors.commonBlack;
        break;
    }
    return color;
  }
}