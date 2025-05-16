import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../backend/health_data_service.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../flutter_flow/flutter_flow_widgets.dart';

class RealtimeHealthMonitorWidget extends StatefulWidget {
  const RealtimeHealthMonitorWidget({Key? key}) : super(key: key);

  @override
  _RealtimeHealthMonitorWidgetState createState() =>
      _RealtimeHealthMonitorWidgetState();
}

class _RealtimeHealthMonitorWidgetState
    extends State<RealtimeHealthMonitorWidget> {
  final HealthDataService _healthService = HealthDataService();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();

  @override
  void dispose() {
    _heartRateController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  Future<void> _addHeartRateReading() async {
    if (_heartRateController.text.isNotEmpty) {
      final bpm = int.tryParse(_heartRateController.text);
      if (bpm != null) {
        await _healthService.addHeartRateReading(bpm);
        _heartRateController.clear();
      }
    }
  }

  Future<void> _addTemperatureReading() async {
    if (_temperatureController.text.isNotEmpty) {
      final temperature = double.tryParse(_temperatureController.text);
      if (temperature != null) {
        await _healthService.addTemperatureReading(temperature);
        _temperatureController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryColor,
        title: Text(
          'Health Monitor',
          style: FlutterFlowTheme.of(context).title2.override(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 22,
              ),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                child: Card(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Heart Rate',
                          style: FlutterFlowTheme.of(context).subtitle1,
                        ),
                        SizedBox(height: 8),
                        _buildHeartRateStream(),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _heartRateController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Add Heart Rate (BPM)',
                                  hintText: 'Enter BPM',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            FFButtonWidget(
                              onPressed: _addHeartRateReading,
                              text: 'Add',
                              options: FFButtonOptions(
                                width: 80,
                                height: 40,
                                color:
                                    FlutterFlowTheme.of(context).primaryColor,
                                textStyle: FlutterFlowTheme.of(context)
                                    .subtitle2
                                    .override(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                    ),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                child: Card(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temperature',
                          style: FlutterFlowTheme.of(context).subtitle1,
                        ),
                        SizedBox(height: 8),
                        _buildTemperatureStream(),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _temperatureController,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Add Temperature (°C)',
                                  hintText: 'Enter temperature',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            FFButtonWidget(
                              onPressed: _addTemperatureReading,
                              text: 'Add',
                              options: FFButtonOptions(
                                width: 80,
                                height: 40,
                                color:
                                    FlutterFlowTheme.of(context).primaryColor,
                                textStyle: FlutterFlowTheme.of(context)
                                    .subtitle2
                                    .override(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                    ),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeartRateStream() {
    return StreamBuilder<DatabaseEvent>(
      stream: _healthService.streamHeartRateReadings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Text('No heart rate data available');
        }

        try {
          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          final readings = data.entries.map((entry) {
            final readingData = Map<String, dynamic>.from(entry.value as Map);
            return HeartRateReading(
              id: entry.key,
              bpm: readingData['bpm'] as int,
              timestamp: readingData['timestamp'] as int,
            );
          }).toList();

          // Sort by timestamp (newest first)
          readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: readings.length,
              itemBuilder: (context, index) {
                final reading = readings[index];
                final dateTime =
                    DateTime.fromMillisecondsSinceEpoch(reading.timestamp);

                return ListTile(
                  title: Text('${reading.bpm} BPM'),
                  subtitle:
                      Text(DateFormat('MMM d, yyyy h:mm a').format(dateTime)),
                  leading: Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
                );
              },
            ),
          );
        } catch (e) {
          return Text('Error parsing data: $e');
        }
      },
    );
  }

  Widget _buildTemperatureStream() {
    return StreamBuilder<DatabaseEvent>(
      stream: _healthService.streamTemperatureReadings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Text('No temperature data available');
        }

        try {
          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          final readings = data.entries.map((entry) {
            final readingData = Map<String, dynamic>.from(entry.value as Map);
            return TemperatureReading(
              id: entry.key,
              temperature: readingData['temperature'] as double,
              timestamp: readingData['timestamp'] as int,
            );
          }).toList();

          // Sort by timestamp (newest first)
          readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: readings.length,
              itemBuilder: (context, index) {
                final reading = readings[index];
                final dateTime =
                    DateTime.fromMillisecondsSinceEpoch(reading.timestamp);

                return ListTile(
                  title: Text('${reading.temperature}°C'),
                  subtitle:
                      Text(DateFormat('MMM d, yyyy h:mm a').format(dateTime)),
                  leading: Icon(
                    Icons.thermostat,
                    color: Colors.orange,
                  ),
                );
              },
            ),
          );
        } catch (e) {
          return Text('Error parsing data: $e');
        }
      },
    );
  }
}

class HeartRateReading {
  final String id;
  final int bpm;
  final int timestamp;

  HeartRateReading({
    required this.id,
    required this.bpm,
    required this.timestamp,
  });
}

class TemperatureReading {
  final String id;
  final double temperature;
  final int timestamp;

  TemperatureReading({
    required this.id,
    required this.temperature,
    required this.timestamp,
  });
}
