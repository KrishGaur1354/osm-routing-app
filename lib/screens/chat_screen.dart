import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart';

import '../services/chat_service.dart';
import '../services/route_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final RouteService _routeService = RouteService();
  bool _isInitialized = false;
  
  // User for the chat UI
  final _user = const types.User(id: 'user');
  final _assistant = const types.User(id: 'ai', firstName: 'Assistant');
  
  // API key for Gemini
  final String _apiKey = "ADD_YOUR_GEMINI_API_KEY_HERE"; // Replace with your actual API key for testing
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    // Wait for route service to initialize if it hasn't already
    await _routeService.initialize();
    
    // Initialize chat service with route data
    await _chatService.initialize(
      _apiKey,
      routes: _routeService.savedRoutes,
    );
    
    // Listen for route changes
    _routeService.savedRoutesStream.listen((routes) {
      _chatService.updateRoutes(routes);
    });
    
    setState(() {
      _isInitialized = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: _isInitialized 
        ? _buildChatUI() 
        : const Center(child: CircularProgressIndicator()),
    );
  }
  
  Widget _buildChatUI() {
    return StreamBuilder<List<types.Message>>(
      stream: _chatService.messagesStream,
      initialData: _chatService.messages,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? [];
        
        return Chat(
          messages: messages,
          onSendPressed: _handleSendPressed,
          user: _user,
          showUserAvatars: true,
          showUserNames: true,
          theme: DefaultChatTheme(
            backgroundColor: Theme.of(context).colorScheme.background,
            primaryColor: Theme.of(context).colorScheme.primary,
            secondaryColor: Theme.of(context).colorScheme.primaryContainer,
            userAvatarNameColors: [
              Theme.of(context).colorScheme.primary,
              Colors.green,
              Colors.orange,
            ],
          ),
          avatarBuilder: (userId) {
            if (userId == _assistant.id) {
              return CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.assistant, color: Colors.white),
              );
            }
            return CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white),
            );
          },
          emptyState: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ask me anything about your routes!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _handleSendPressed(types.PartialText message) {
    _chatService.sendMessage(message.text);
  }
  
  Future<void> _clearChat() async {
    await _chatService.clearChat();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
} 