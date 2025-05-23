import 'package:flutter/material.dart';

class ColorManager {
  static Color primary = HexColor.fromHex('#D2691E');
  static Color background = HexColor.fromHex('#f9fafb');
  static Color grey = HexColor.fromHex('#e5e7ea');
    static Color progressWhite = HexColor.fromHex('#E5E7EB');
  static Color textGrey = HexColor.fromHex('#9a9ca1');



  static Color textWhite = HexColor.fromHex("#FFFFFF");
  static Color black = HexColor.fromHex('#000000');
  static Color signUpRed = Color.fromARGB(191, 245, 88, 54);
  static Color cardGrey = HexColor.fromHex('#E5E7EB');
    static Color textgrey2 = HexColor.fromHex('#4B5563');

}

extension HexColor on Color {
  static Color fromHex(String hexColorString) {
    hexColorString = hexColorString.replaceAll('#', '');
    if (hexColorString.length == 6) {
      hexColorString =
          "FF$hexColorString"; //Appending characters for opacity of 100% at start of HexCode
    }
    return Color(int.parse(hexColorString, radix: 16));
  }
}
