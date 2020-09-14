import 'package:flutter/material.dart';

Map<String, Color> themeColorMap = {
  'bluegrey': Colors.blueGrey,
  'red': Colors.red[300]
};

class AppInfoProvider with ChangeNotifier {
  String _themeColor = '';
  bool _grid = false;

  String get themeColor => _themeColor;
  bool get gridmode => _grid;

  setTheme(String themeColor) {
    _themeColor = themeColor;
    notifyListeners();
  }

  setGrid(bool grid) {
    _grid=grid;
    notifyListeners();
  }

  changeGrid() async {
    _grid = !_grid;
    notifyListeners();
  }
}
