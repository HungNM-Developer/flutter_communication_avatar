import 'package:flutter/material.dart';
import 'package:flutter_communication_avatar/flutter_communication_avatar.dart';

void main() {
  runApp(const CommunicationAvatarExampleApp());
}

class CommunicationAvatarExampleApp extends StatelessWidget {
  const CommunicationAvatarExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Communication Avatar Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _senderNameController = TextEditingController(text: 'Alice Smith');
  final _senderIdController = TextEditingController(text: 'user_alice_123');
  final _avatarUrlController = TextEditingController(
    text: 'https://i.pravatar.cc/300?img=5',
  );
  final _bodyController = TextEditingController(
    text: 'Hey! Are we still meeting for coffee at 3 PM?',
  );
  final _conversationTitleController = TextEditingController(text: 'Project Alpha');

  bool _isGroup = false;
  bool _hasPermission = false;
  bool _isLoadingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _createDefaultChannel();
  }

  Future<void> _checkPermission() async {
    final granted = await FlutterCommunicationAvatar.instance.hasPermissions();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _isLoadingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final granted = await FlutterCommunicationAvatar.instance.requestPermissions();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Notification permissions granted!'
                : 'Notification permissions denied.',
          ),
          backgroundColor: granted ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _createDefaultChannel() async {
    await FlutterCommunicationAvatar.instance.createNotificationChannel(
      const NotificationChannelConfig(
        id: 'communication_channel',
        name: 'Chat & Communication',
        description: 'Notifications for incoming chat messages with user avatars.',
        importance: 4,
      ),
    );
  }

  Future<void> _sendNotification() async {
    final sender = CommunicationPerson(
      id: _senderIdController.text.trim(),
      name: _senderNameController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim().isNotEmpty
          ? _avatarUrlController.text.trim()
          : null,
    );

    final notification = CommunicationNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: _isGroup ? _conversationTitleController.text : _senderNameController.text,
      body: _bodyController.text.trim(),
      sender: sender,
      conversationId: 'conversation_${_senderIdController.text.trim()}',
      conversationTitle: _isGroup ? _conversationTitleController.text : null,
      isGroupConversation: _isGroup,
    );

    try {
      final success = await FlutterCommunicationAvatar.instance.showNotification(notification);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Communication notification sent successfully!'
                  : 'Failed to post notification.',
            ),
            backgroundColor: success ? Colors.deepPurple : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyPreset(String name, String id, String url, String body) {
    setState(() {
      _senderNameController.text = name;
      _senderIdController.text = id;
      _avatarUrlController.text = url;
      _bodyController.text = body;
    });
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderIdController.dispose();
    _avatarUrlController.dispose();
    _bodyController.dispose();
    _conversationTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Communication Avatar Demo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All Notifications',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await FlutterCommunicationAvatar.instance.cancelAllNotifications();
              messenger.showSnackBar(
                const SnackBar(content: Text('Cleared all notifications.')),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permission Banner Card
            Card(
              color: _hasPermission
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _hasPermission ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: _hasPermission
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasPermission
                                ? 'Notifications Enabled'
                                : 'Permission Required',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _hasPermission
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onErrorContainer,
                            ),
                          ),
                          Text(
                            _hasPermission
                                ? 'Ready to send communication push notifications with avatars.'
                                : 'Grant permission to enable communication push notifications.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _hasPermission
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_hasPermission && !_isLoadingPermission)
                      ElevatedButton(
                        onPressed: _requestPermission,
                        child: const Text('Grant'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Presets Section
            const Text(
              'Quick Presets:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: const CircleAvatar(child: Text('A')),
                    label: const Text('Alice (Avatar URL)'),
                    onPressed: () => _applyPreset(
                      'Alice Smith',
                      'user_alice',
                      'https://i.pravatar.cc/300?img=5',
                      'Hey team! The design review is starting in 5 minutes.',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const CircleAvatar(child: Text('B')),
                    label: const Text('Bob (Avatar URL 2)'),
                    onPressed: () => _applyPreset(
                      'Bob Johnson',
                      'user_bob',
                      'https://i.pravatar.cc/300?img=12',
                      'Pull request #42 is ready for code review.',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const CircleAvatar(child: Text('F')),
                    label: const Text('Fallback (No URL)'),
                    onPressed: () => _applyPreset(
                      'Charlie Brown',
                      'user_charlie',
                      '',
                      'Testing automatic letter badge fallback generation!',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Section
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configure Communication Notification:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _senderNameController,
                      decoration: const InputDecoration(
                        labelText: 'Sender Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _senderIdController,
                      decoration: const InputDecoration(
                        labelText: 'Sender User ID',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _avatarUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Avatar Image URL (HTTP/HTTPS)',
                        prefixIcon: Icon(Icons.image),
                        helperText: 'Leave empty to test initial letter avatar fallback',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bodyController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Message Body',
                        prefixIcon: Icon(Icons.message),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Group Conversation'),
                      value: _isGroup,
                      onChanged: (val) => setState(() => _isGroup = val),
                    ),
                    if (_isGroup) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _conversationTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Group Title',
                          prefixIcon: Icon(Icons.group),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            FilledButton.icon(
              onPressed: _sendNotification,
              icon: const Icon(Icons.send),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Text(
                  'Send Communication Notification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Architecture Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Native Platform Features',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text(
                      '• iOS: Uses INSendMessageIntent + INPerson + INInteraction for native iOS 15+ Communication Notification layout (Avatar on LEFT overlaying app icon).\n'
                      '• Android: Uses NotificationCompat.MessagingStyle + Person + Icon.createWithBitmap (Avatar on LEFT side).\n'
                      '• Fallback: Asynchronously downloads HTTP/HTTPS avatars. Automatically generates circular letter avatar if URL fails or is omitted.\n'
                      '• CLI Tool: Run "dart run flutter_communication_avatar:setup_ios --apply" to automate Xcode Info.plist setup.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
