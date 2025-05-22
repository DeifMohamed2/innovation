import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'mychairrrr_widget.dart' show MychairrrrWidget;
import 'package:flutter/material.dart';

class MychairrrrModel extends FlutterFlowModel<MychairrrrWidget> {
  // State field(s) for SpeedSlider widget.
  double? speedSliderValue;

  // Movement state fields to track current direction
  String currentDirection = 'stop';
  bool isMoving = false;

  @override
  void initState(BuildContext context) {
    speedSliderValue = 50;
  }

  @override
  void dispose() {}
}
