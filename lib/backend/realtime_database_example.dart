import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'realtime_database_service.dart';

class RealtimeDataExample extends StatefulWidget {
  const RealtimeDataExample({Key? key}) : super(key: key);

  @override
  _RealtimeDataExampleState createState() => _RealtimeDataExampleState();
}

class _RealtimeDataExampleState extends State<RealtimeDataExample> {
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final String _path = 'messages';
  Stream<DatabaseEvent>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = _dbService.listenToData(_path);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final message = {
        'text': _messageController.text,
        'timestamp': ServerValue.timestamp,
        'sender': 'User', // In a real app, use the authenticated user's ID
      };

      await _dbService.pushData(_path, message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Database Example'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No messages yet'));
                }

                // Convert the data to a usable format
                final messagesData = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);

                final messages = messagesData.entries.map((entry) {
                  final data = Map<String, dynamic>.from(entry.value as Map);
                  return MessageItem(
                    id: entry.key,
                    text: data['text'] as String,
                    timestamp: data['timestamp'] as int,
                    sender: data['sender'] as String,
                  );
                }).toList();

                // Sort by timestamp
                messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message.text),
                      subtitle: Text(message.sender),
                      trailing: Text(
                        DateTime.fromMillisecondsSinceEpoch(message.timestamp)
                            .toString(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageItem {
  final String id;
  final String text;
  final int timestamp;
  final String sender;

  MessageItem({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.sender,
  });
}
