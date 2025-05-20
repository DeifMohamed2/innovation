import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'chairrr_model.dart';
export 'chairrr_model.dart';

class ChairrrWidget extends StatefulWidget {
  const ChairrrWidget({super.key});

  static String routeName = 'chairrr';
  static String routePath = '/chairrr';

  @override
  State<ChairrrWidget> createState() => _ChairrrWidgetState();
}

class _ChairrrWidgetState extends State<ChairrrWidget> {
  late ChairrrModel _model;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? selectedChairId;
  Map<String, dynamic> chairs = {};

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChairrrModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _loadChairs();
  }

  Future<void> _loadChairs() async {
    final chairsRef = _database.child('chairs');
    chairsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          chairs = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  Future<void> _addNewChair() async {
    if (_model.textController?.text.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a chair name')),
      );
      return;
    }

    final newChairRef = _database.child('chairs').push();
    await newChairRef.set({
      'name': _model.textController?.text,
      'code': _generateChairCode(),
      'createdAt': ServerValue.timestamp,
    });

    _model.textController?.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chair added successfully')),
    );
  }

  String _generateChairCode() {
    // Generate a unique 6-character code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return List.generate(
            6,
            (index) =>
                chars[int.parse(random[index % random.length]) % chars.length])
        .join();
  }

  Future<void> _controlChair(String command) async {
    if (selectedChairId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a chair first')),
      );
      return;
    }

    await _database.child('chairs/$selectedChairId/commands').push().set({
      'command': command,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  void dispose() {
    _model.dispose();
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
                              'Chair Management',
                              style: FlutterFlowTheme.of(context)
                                  .headlineLarge
                                  .override(
                                    fontFamily: 'Inter Tight',
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(width: 40),
                          ],
                        ),
                        SizedBox(height: 24),
                        // Add New Chair Section
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
                                    'Add New Chair',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          fontFamily: 'Inter Tight',
                                          color: Colors.white,
                                        ),
                                  ),
                                  SizedBox(height: 16),
                                  TextFormField(
                                    controller: _model.textController,
                                    focusNode: _model.textFieldFocusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Chair Name',
                                      labelStyle:
                                          TextStyle(color: Colors.white70),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(0xFF4B0082)),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(0xFF4B0082)),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                    ),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(height: 16),
                                  FFButtonWidget(
                                    onPressed: _addNewChair,
                                    text: 'Add Chair',
                                    options: FFButtonOptions(
                                      width: double.infinity,
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
                          ),
                        ),
                        SizedBox(height: 24),
                        // Chair List Section
                        Text(
                          'Your Chairs',
                          style: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .override(
                                fontFamily: 'Inter Tight',
                                color: Colors.white,
                              ),
                        ),
                        SizedBox(height: 16),
                        ...chairs.entries.map((entry) {
                          final chair = entry.value as Map<String, dynamic>;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: Colors.transparent,
                              elevation: 4.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: ListTile(
                                  title: Text(
                                    chair['name'] ?? 'Unnamed Chair',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    'Code: ${chair['code']}',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.control_camera,
                                        color: Color(0xFF4B0082)),
                                    onPressed: () {
                                      setState(() {
                                        selectedChairId = entry.key;
                                      });
                                      context.pushNamed('mychairrrr');
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
}
