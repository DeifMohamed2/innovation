import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'mychairrrr_widget.dart' show MychairrrrWidget;
import 'package:flutter/material.dart';

class MychairrrrModel extends FlutterFlowModel<MychairrrrWidget> {
  // State field(s) for SpeedSlider widget.
  double? speedSliderValue;

  // State fields for joystick
  double joystickX = 0.0;
  double joystickY = 0.0;
  bool isJoystickActive = false;

  @override
  void initState(BuildContext context) {
    speedSliderValue = 50;
  }

  @override
  void dispose() {}
}
