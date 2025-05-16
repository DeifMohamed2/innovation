import 'package:flutter/material.dart';
import 'realtime_health_monitor.dart';

class RealtimeHealthPage extends StatefulWidget {
  const RealtimeHealthPage({Key? key}) : super(key: key);

  static const String routeName = 'RealtimeHealthMonitor';
  static const String routePath = '/realtime-health-monitor';

  @override
  _RealtimeHealthPageState createState() => _RealtimeHealthPageState();
}

class _RealtimeHealthPageState extends State<RealtimeHealthPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const RealtimeHealthMonitorWidget();
  }
}
