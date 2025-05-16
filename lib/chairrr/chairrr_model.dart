import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'chairrr_widget.dart' show ChairrrWidget;
import 'package:flutter/material.dart';

class ChairrrModel extends FlutterFlowModel<ChairrrWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
