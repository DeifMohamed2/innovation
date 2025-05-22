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
import 'dart:math' as math;
import 'mychairrrr_model.dart';
export 'mychairrrr_model.dart';

class MychairrrrWidget extends StatefulWidget {
  const MychairrrrWidget({super.key});

  static String routeName = 'mychairrrr';
  static String routePath = '/mychairrrr';

  @override
  State<MychairrrrWidget> createState() => _MychairrrrWidgetState();
}

class _MychairrrrWidgetState extends State<MychairrrrWidget> {
  MychairrrrModel _model = MychairrrrModel();
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

  // Add a timer to periodically update the movement state from Firebase
  Timer? _stateUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadUserChairs();
    _loadAvailableChairs();

    // Start a timer to update the movement state every second
    _stateUpdateTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _updateMovementState();
    });
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

  // Method to update the current movement state from Firebase
  Future<void> _updateMovementState() async {
    if (selectedChairId == null) return;

    try {
      final movementState =
          await _database.child('chairs/$selectedChairId/movement_state').get();

      if (movementState.exists && mounted) {
        final data = movementState.value as Map<dynamic, dynamic>;
        setState(() {
          _model.currentDirection = data['direction']?.toString() ?? 'stop';
          _model.isMoving = _model.currentDirection != 'stop';
        });
      }
    } catch (e) {
      print('Error updating movement state: $e');
    }
  }

  // Update the _sendDirectionCommand method
  Future<void> _sendDirectionCommand(String direction) async {
    if (selectedChairId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No chair selected')),
      );
      return;
    }

    // Update the local model state
    setState(() {
      _model.currentDirection = direction;
      _model.isMoving = direction != 'stop';
    });

    // Send the command to Firebase
    await _database.child('chairs/$selectedChairId/commands').push().set({
      'command': 'direction',
      'value': direction,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  void dispose() {
    _stateUpdateTimer?.cancel();
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

                                    // Advanced Direction Controls - replaces joystick
                                    Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            'Directional Controls',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 24),

                                          // First row: Forward-Left, Forward, Forward-Right
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              // Forward-Left
                                              _buildDirectionButton(
                                                icon: Icons.north_west,
                                                label: "Forward-Left",
                                                onPressed: () =>
                                                    _sendDirectionCommand(
                                                        'forward-left'),
                                              ),
                                              SizedBox(width: 12),
                                              // Forward
                                              _buildDirectionButton(
                                                icon: Icons.arrow_upward,
                                                label: "Forward",
                                                onPressed: () =>
                                                    _sendCommand('forward'),
                                                size: 70.0,
                                              ),
                                              SizedBox(width: 12),
                                              // Forward-Right
                                              _buildDirectionButton(
                                                icon: Icons.north_east,
                                                label: "Forward-Right",
                                                onPressed: () =>
                                                    _sendDirectionCommand(
                                                        'forward-right'),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),

                                          // Second row: Left, Stop, Right
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              // Left
                                              _buildDirectionButton(
                                                icon: Icons.arrow_back,
                                                label: "Left",
                                                onPressed: () =>
                                                    _sendCommand('left'),
                                                size: 70.0,
                                              ),
                                              SizedBox(width: 12),
                                              // Stop
                                              _buildDirectionButton(
                                                icon:
                                                    Icons.stop_circle_outlined,
                                                label: "Stop",
                                                onPressed: () =>
                                                    _sendCommand('stop'),
                                                size: 70.0,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 12),
                                              // Right
                                              _buildDirectionButton(
                                                icon: Icons.arrow_forward,
                                                label: "Right",
                                                onPressed: () =>
                                                    _sendCommand('right'),
                                                size: 70.0,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),

                                          // Third row: Backward-Left, Backward, Backward-Right
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              // Backward-Left
                                              _buildDirectionButton(
                                                icon: Icons.south_west,
                                                label: "Back-Left",
                                                onPressed: () =>
                                                    _sendDirectionCommand(
                                                        'backward-left'),
                                              ),
                                              SizedBox(width: 12),
                                              // Backward
                                              _buildDirectionButton(
                                                icon: Icons.arrow_downward,
                                                label: "Backward",
                                                onPressed: () =>
                                                    _sendCommand('backward'),
                                                size: 70.0,
                                              ),
                                              SizedBox(width: 12),
                                              // Backward-Right
                                              _buildDirectionButton(
                                                icon: Icons.south_east,
                                                label: "Back-Right",
                                                onPressed: () =>
                                                    _sendDirectionCommand(
                                                        'backward-right'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 16),
                                    Divider(color: Colors.white24),
                                    SizedBox(height: 16),
                                    Text(
                                      'Direction: ${_formatDirectionName(_model.currentDirection)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
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

  Widget _buildDirectionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    double size = 60.0,
    Color color = const Color(0xFF4B0082),
  }) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: Colors.white,
              size: size * 0.5,
            ),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Add this helper method to format direction names for display
  String _formatDirectionName(String direction) {
    switch (direction) {
      case 'forward':
        return 'Forward';
      case 'backward':
        return 'Backward';
      case 'left':
        return 'Left';
      case 'right':
        return 'Right';
      case 'forward-left':
        return 'Forward-Left';
      case 'forward-right':
        return 'Forward-Right';
      case 'backward-left':
        return 'Backward-Left';
      case 'backward-right':
        return 'Backward-Right';
      case 'stop':
        return 'Stopped';
      default:
        return direction.isEmpty ? 'Stopped' : direction;
    }
  }
}
