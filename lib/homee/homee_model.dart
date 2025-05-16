import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'homee_widget.dart' show HomeeWidget;
import 'package:flutter/material.dart';
import '../backend/models/room.dart';

class HomeeModel extends FlutterFlowModel<HomeeWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Switch widget.
  bool? switchValue1;
  // State field(s) for Switch widget.
  bool? switchValue2;
  // State field(s) for Switch widget.
  bool? switchValue3;
  // State field(s) for Switch widget.
  bool? switchValue4;

  // State for rooms list
  List<Room> rooms = [];
  bool isLoading = true;

  // State for add room form
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  String selectedIcon = 'living';

  // State for pin selection in add room form
  bool hasLights = true;
  bool hasDoor = true;
  int selectedLightPin = 13; // Default GPIO pin for light
  int selectedDoorPin = 15; // Default GPIO pin for door servo

  // Available GPIO pins for selection
  List<int> availableLightPins = [13, 12, 14, 27, 26, 25, 33];
  List<int> availableDoorPins = [15, 2, 4, 5, 18, 19, 21];

  // State for showing/hiding add room form
  bool showAddRoomForm = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
