import 'package:flutter/material.dart';

Map<String, Color> themeColorMap = {
  'bluegrey': Colors.blueGrey,
  'red': Colors.red[300]
};

class AppInfoProvider with ChangeNotifier {
  String _themeColor = '';

  String get themeColor => _themeColor;

  setTheme(String themeColor) {
    _themeColor = themeColor;
    notifyListeners();
  }
}
