import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui' as ui;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'dart:math' as math;
import 'mychairrrr_model.dart';
export 'mychairrrr_model.dart';

// Custom painter for joystick background with grid lines
class JoystickBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw crosshair lines
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Horizontal line
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );

    // Draw concentric circles
    for (double i = 0.3; i <= 0.9; i += 0.3) {
      canvas.drawCircle(
        center,
        radius * i,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for direction indicator line
class DirectionIndicatorPainter extends CustomPainter {
  final double x;
  final double y;

  DirectionIndicatorPainter({required this.x, required this.y});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Calculate magnitude for color intensity
    final magnitude = math.sqrt(x * x + y * y);
    final normalizedMagnitude = math.min(1.0, magnitude);

    // Calculate end point with increased visibility at edges
    final endPoint = Offset(
      center.dx + (x * size.width / 2 * 0.8),
      center.dy + (y * size.height / 2 * 0.8),
    );

    // Draw direction line with gradient for better visibility
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7 * normalizedMagnitude)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center, endPoint, paint);

    // Draw arrow at the end of the line
    final arrowSize = 12.0;
    final angle = math.atan2(endPoint.dy - center.dy, endPoint.dx - center.dx);

    final arrowPath = Path();
    arrowPath.moveTo(endPoint.dx, endPoint.dy);
    arrowPath.lineTo(
      endPoint.dx - arrowSize * math.cos(angle - math.pi / 6),
      endPoint.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    arrowPath.lineTo(
      endPoint.dx - arrowSize * math.cos(angle + math.pi / 6),
      endPoint.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    arrowPath.close();

    final arrowPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * normalizedMagnitude)
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);

    // Add direction text for clarity
    final directionText = _getDirectionText(x, y);
    if (directionText.isNotEmpty && magnitude > 0.3) {
      final textSpan = TextSpan(
        text: directionText,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9 * normalizedMagnitude),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      // Position text near the arrow but not on top of it
      final textOffset = Offset(
        center.dx + (x * size.width / 4),
        center.dy + (y * size.height / 4) - 15,
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  String _getDirectionText(double x, double y) {
    if (x.abs() < 0.3 && y.abs() < 0.3) return '';

    List<String> directions = [];

    if (y < -0.3)
      directions.add('Forward');
    else if (y > 0.3) directions.add('Backward');

    if (x < -0.3)
      directions.add('Left');
    else if (x > 0.3) directions.add('Right');

    return directions.join(' + ');
  }

  @override
  bool shouldRepaint(DirectionIndicatorPainter oldDelegate) {
    return x != oldDelegate.x || y != oldDelegate.y;
  }
}

class MychairrrrWidget extends StatefulWidget {
  const MychairrrrWidget({super.key});

  static String routeName = 'mychairrrr';
  static String routePath = '/mychairrrr';

  @override
  State<MychairrrrWidget> createState() => _MychairrrrWidgetState();
}

class _MychairrrrWidgetState extends State<MychairrrrWidget> {
  late MychairrrrModel _model;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? selectedChairId;
  Map<String, dynamic>? selectedChair;
  Map<String, dynamic> availableChairs = {};
  final TextEditingController _chairCodeController = TextEditingController();
  final TextEditingController _chairNameController = TextEditingController();

  // Stream subscriptions to manage listeners
  StreamSubscription? _chairsSubscription;
  StreamSubscription? _userChairsSubscription;
  StreamSubscription? _selectedChairSubscription;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MychairrrrModel());
    _loadUserChairs();
    _loadAvailableChairs();
  }

  Future<void> _loadAvailableChairs() async {
    final chairsRef = _database.child('chairs');
    _chairsSubscription = chairsRef.onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          availableChairs =
              Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  Future<void> _loadUserChairs() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userChairsRef = _database.child('users/${user.uid}/chairs');
    _userChairsSubscription = userChairsRef.onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final chairs = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (chairs.isNotEmpty) {
          // Select the first chair by default if none is selected
          if (selectedChairId == null) {
            selectedChairId = chairs.keys.first;
            _loadSelectedChair();
          }
        }
      }
    });
  }

  Future<void> _loadSelectedChair() async {
    if (selectedChairId == null) return;

    // Cancel any existing subscription first
    _selectedChairSubscription?.cancel();

    final chairsRef = _database.child('chairs/$selectedChairId');
    _selectedChairSubscription = chairsRef.onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          selectedChair =
              Map<String, dynamic>.from(event.snapshot.value as Map);

          // Update the speed slider to match the chair's current speed
          if (selectedChair!.containsKey('current_speed')) {
            _model.speedSliderValue =
                selectedChair!['current_speed'].toDouble();
          }
        });
      }
    });
  }

  Future<void> _addNewChair() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login first')),
      );
      return;
    }

    final chairCode = _chairCodeController.text.trim();
    final chairName = _chairNameController.text.trim();

    if (chairCode.isEmpty || chairName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both chair code and name')),
      );
      return;
    }

    // Check if chair exists with the given code
    String? foundChairId;
    for (var entry in availableChairs.entries) {
      final chairData = entry.value as Map<dynamic, dynamic>;
      if (chairData['code'] == chairCode) {
        foundChairId = entry.key;
        break;
      }
    }

    if (foundChairId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid chair code')),
      );
      return;
    }

    // Add chair to user's chairs
    await _database.child('users/${user.uid}/chairs/$foundChairId').set(true);

    // Update chair name
    await _database.child('chairs/$foundChairId/name').set(chairName);

    // Set this as the selected chair
    setState(() {
      selectedChairId = foundChairId;
      _loadSelectedChair();
    });

    _chairCodeController.clear();
    _chairNameController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chair added successfully')),
    );
  }

  Future<void> _showAddChairDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('Add New Chair', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _chairCodeController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Chair Code',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Enter the chair code',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4B0082)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4B0082), width: 2),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _chairNameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Chair Name',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Enter a name for your chair',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4B0082)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4B0082), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addNewChair();
            },
            child: Text('Add', style: TextStyle(color: Color(0xFF4B0082))),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCommand(String command) async {
    if (selectedChairId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No chair selected')),
      );
      return;
    }

    await _database.child('chairs/$selectedChairId/commands').push().set({
      'command': command,
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> _sendJoystickCommand(double x, double y) async {
    if (selectedChairId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No chair selected')),
      );
      return;
    }

    // Convert joystick values from -1.0 to 1.0 to -100 to 100 range
    int xValue = (x * 100).round();
    int yValue = (y * -100).round(); // Invert Y axis so up is positive

    await _database.child('chairs/$selectedChairId/commands').push().set({
      'command': 'joystick',
      'value': {
        'x': xValue,
        'y': yValue,
      },
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> _sendSpeedCommand(double speed) async {
    if (selectedChairId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No chair selected')),
      );
      return;
    }

    await _database.child('chairs/$selectedChairId/commands').push().set({
      'command': 'speed',
      'value': speed.round(),
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions
    _chairsSubscription?.cancel();
    _userChairsSubscription?.cancel();
    _selectedChairSubscription?.cancel();

    _model.dispose();
    _chairCodeController.dispose();
    _chairNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFF020202),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width * 1.0,
                height: MediaQuery.sizeOf(context).height * 1.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4B0082), Colors.black],
                    stops: [0.0, 1.0],
                    begin: AlignmentDirectional(0.0, -1.0),
                    end: AlignmentDirectional(0, 1.0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => context.pop(),
                            ),
                            Text(
                              selectedChair?['name'] ?? 'Chair Control',
                              style: FlutterFlowTheme.of(context)
                                  .headlineLarge
                                  .override(
                                    fontFamily: 'Inter Tight',
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.white),
                              onPressed: _showAddChairDialog,
                            ),
                          ],
                        ),
                        if (selectedChair != null) ...[
                          SizedBox(height: 8),
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    _getStatusColor(selectedChair!['status']),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Status: ${_formatStatus(selectedChair!['status'])}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (selectedChair == null) ...[
                          SizedBox(height: 24),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'No Chair Selected',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .override(
                                        fontFamily: 'Inter Tight',
                                        color: Colors.white,
                                      ),
                                ),
                                SizedBox(height: 16),
                                FFButtonWidget(
                                  onPressed: _showAddChairDialog,
                                  text: 'Add a Chair',
                                  options: FFButtonOptions(
                                    width: 200.0,
                                    height: 50.0,
                                    color: Color(0xFF4B0082),
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          fontFamily: 'Inter Tight',
                                          color: Colors.white,
                                        ),
                                    borderRadius: BorderRadius.circular(25.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          SizedBox(height: 24),
                          // Speed Controls
                          Material(
                            color: Colors.transparent,
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Speed Controls',
                                      style: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .override(
                                            fontFamily: 'Inter Tight',
                                            color: Colors.white,
                                          ),
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.speed_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Slider(
                                            activeColor: Color(0xFF4B0082),
                                            inactiveColor: Colors.grey.shade800,
                                            min: 20,
                                            max: 100,
                                            divisions: 8,
                                            value:
                                                _model.speedSliderValue ?? 50,
                                            onChanged: (newValue) {
                                              setState(() => _model
                                                  .speedSliderValue = newValue);
                                            },
                                            onChangeEnd: (newValue) {
                                              _sendSpeedCommand(newValue);
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '${_model.speedSliderValue?.round() ?? 50}%',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        FFButtonWidget(
                                          onPressed: () =>
                                              _sendCommand('start'),
                                          text: 'START',
                                          options: FFButtonOptions(
                                            width: 120.0,
                                            height: 50.0,
                                            color: Colors.green,
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .override(
                                                      fontFamily: 'Inter Tight',
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                            borderRadius:
                                                BorderRadius.circular(25.0),
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        FFButtonWidget(
                                          onPressed: () => _sendCommand('stop'),
                                          text: 'STOP',
                                          options: FFButtonOptions(
                                            width: 120.0,
                                            height: 50.0,
                                            color: Colors.red,
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .override(
                                                      fontFamily: 'Inter Tight',
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                            borderRadius:
                                                BorderRadius.circular(25.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          // Movement Controls
                          Material(
                            color: Colors.transparent,
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Movement Controls',
                                      style: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .override(
                                            fontFamily: 'Inter Tight',
                                            color: Colors.white,
                                          ),
                                    ),
                                    SizedBox(height: 24),

                                    // Joystick Control
                                    Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            'Joystick Control',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Container(
                                            height: 200,
                                            width: 200,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF2A2A2A),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: Stack(
                                              children: [
                                                // Joystick background with grid
                                                Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Color(0xFF333333),
                                                  ),
                                                  child: CustomPaint(
                                                    painter:
                                                        JoystickBackgroundPainter(),
                                                  ),
                                                ),

                                                // Center dot (fixed reference point)
                                                Center(
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.5),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),

                                                // Direction indicator line
                                                if (_model.isJoystickActive)
                                                  CustomPaint(
                                                    size: Size(200, 200),
                                                    painter:
                                                        DirectionIndicatorPainter(
                                                      x: _model.joystickX,
                                                      y: _model.joystickY,
                                                    ),
                                                  ),

                                                // Position indicator that moves with joystick
                                                Center(
                                                  child: Transform.translate(
                                                    offset: Offset(
                                                      _model.joystickX * 70,
                                                      _model.joystickY * 70,
                                                    ),
                                                    child: Container(
                                                      width: 30,
                                                      height: 30,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Color(0xFF4B0082),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 2,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color:
                                                                Colors.black45,
                                                            blurRadius: 8,
                                                            spreadRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Center(
                                                        child: Container(
                                                          width: 10,
                                                          height: 10,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // Invisible Joystick for touch detection
                                                Positioned.fill(
                                                  child: Joystick(
                                                    mode: JoystickMode.all,
                                                    period: Duration(
                                                        milliseconds: 50),
                                                    listener: (details) {
                                                      setState(() {
                                                        _model.joystickX =
                                                            details.x;
                                                        _model.joystickY =
                                                            details.y;
                                                        _model.isJoystickActive =
                                                            details.x != 0 ||
                                                                details.y != 0;
                                                      });

                                                      if (details.x.abs() >
                                                              0.05 ||
                                                          details.y.abs() >
                                                              0.05) {
                                                        _sendJoystickCommand(
                                                            details.x,
                                                            details.y);
                                                      } else {
                                                        _sendCommand('stop');
                                                      }
                                                    },
                                                    base: Container(
                                                      color: Colors.transparent,
                                                    ),
                                                    stick: Container(
                                                      color: Colors.transparent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            _model.isJoystickActive
                                                ? 'Moving: ${_getDirectionText(_model.joystickX, _model.joystickY)}'
                                                : 'Centered',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 32),
                                    Center(
                                      child: Text(
                                        'Quick Controls',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),

                                    // Quick Control Buttons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            FlutterFlowIconButton(
                                              borderRadius: 35.0,
                                              buttonSize: 60.0,
                                              fillColor: Color(0xFF4B0082),
                                              icon: Icon(
                                                Icons.keyboard_arrow_up,
                                                color: Colors.white,
                                                size: 30.0,
                                              ),
                                              onPressed: () =>
                                                  _sendCommand('forward'),
                                            ),
                                            SizedBox(height: 16),
                                            Row(
                                              children: [
                                                FlutterFlowIconButton(
                                                  borderRadius: 35.0,
                                                  buttonSize: 60.0,
                                                  fillColor: Color(0xFF4B0082),
                                                  icon: Icon(
                                                    Icons.keyboard_arrow_left,
                                                    color: Colors.white,
                                                    size: 30.0,
                                                  ),
                                                  onPressed: () =>
                                                      _sendCommand('left'),
                                                ),
                                                SizedBox(width: 16),
                                                FlutterFlowIconButton(
                                                  borderRadius: 35.0,
                                                  buttonSize: 60.0,
                                                  fillColor: Color(0xFF4B0082),
                                                  icon: Icon(
                                                    Icons.stop,
                                                    color: Colors.white,
                                                    size: 30.0,
                                                  ),
                                                  onPressed: () =>
                                                      _sendCommand('stop'),
                                                ),
                                                SizedBox(width: 16),
                                                FlutterFlowIconButton(
                                                  borderRadius: 35.0,
                                                  buttonSize: 60.0,
                                                  fillColor: Color(0xFF4B0082),
                                                  icon: Icon(
                                                    Icons.keyboard_arrow_right,
                                                    color: Colors.white,
                                                    size: 30.0,
                                                  ),
                                                  onPressed: () =>
                                                      _sendCommand('right'),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 16),
                                            FlutterFlowIconButton(
                                              borderRadius: 35.0,
                                              buttonSize: 60.0,
                                              fillColor: Color(0xFF4B0082),
                                              icon: Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Colors.white,
                                                size: 30.0,
                                              ),
                                              onPressed: () =>
                                                  _sendCommand('backward'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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

  String _getDirectionText(double x, double y) {
    String direction = '';

    if (y < -0.3) {
      direction += 'Forward';
    } else if (y > 0.3) {
      direction += 'Backward';
    }

    if (direction.isNotEmpty && (x < -0.3 || x > 0.3)) {
      direction += ' + ';
    }

    if (x < -0.3) {
      direction += 'Left';
    } else if (x > 0.3) {
      direction += 'Right';
    }

    return direction.isEmpty ? 'Centered' : direction;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'ready':
        return Colors.blue;
      case 'moving':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Unknown';

    // Convert first letter to uppercase
    return status.substring(0, 1).toUpperCase() + status.substring(1);
  }
}
