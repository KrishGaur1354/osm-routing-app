import 'dart:async';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/route.dart';

class ChatService {
  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // The Gemini model to use for chat
  late GenerativeModel _model;
  late ChatSession _chatSession;
  
  // Messages storage
  final List<types.Message> _messages = [];
  final StreamController<List<types.Message>> _messagesController = StreamController<List<types.Message>>.broadcast();
  
  // Routes reference
  List<RouteTrack>? _routes;
  
  // Getters
  Stream<List<types.Message>> get messagesStream => _messagesController.stream;
  List<types.Message> get messages => List.unmodifiable(_messages);

  // Initialize the service with Gemini API key
  Future<void> initialize(String apiKey, {List<RouteTrack>? routes}) async {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
    
    // Set routes if provided
    _routes = routes;
    
    // Initialize chat session with system prompt
    final systemPrompt = _createSystemPrompt();
    _chatSession = _model.startChat(
      history: [
        Content.text(systemPrompt),
      ],
    );
    
    // Add AI welcome message
    await _addAIMessage('Hello! I can help you with information about your routes and provide navigation assistance. What would you like to know?');
  }
  
  // Update routes data
  void updateRoutes(List<RouteTrack> routes) {
    _routes = routes;
  }
  
  // Send a message and get a response
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    // Add user message to the list
    final userMessage = types.TextMessage(
      id: const Uuid().v4(),
      author: const types.User(id: 'user'),
      text: text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    _messages.add(userMessage);
    _messagesController.add(_messages);
    
    // Send to Gemini and get response
    try {
      final response = await _chatSession.sendMessage(
        Content.text(text),
      );
      
      if (response.text != null) {
        await _addAIMessage(response.text!);
      } else {
        await _addAIMessage('I\'m sorry, I couldn\'t generate a response.');
      }
    } catch (e) {
      await _addAIMessage('I encountered an error: $e');
    }
  }
  
  // Add an AI message to the chat
  Future<void> _addAIMessage(String text) async {
    final aiMessage = types.TextMessage(
      id: const Uuid().v4(),
      author: const types.User(id: 'ai'),
      text: text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    _messages.add(aiMessage);
    _messagesController.add(_messages);
  }
  
  // Create a system prompt with route data
  String _createSystemPrompt() {
    String systemPrompt = '''
You are an AI assistant for OSM Explorer, a location and route tracking app. 
Your job is to help users understand their routes, provide navigation advice, 
and answer questions about their tracked activities.

Please be helpful, courteous, and precise in your responses.
''';

    // Add route data if available
    if (_routes != null && _routes!.isNotEmpty) {
      systemPrompt += '\n\nHere are the user\'s recent routes:\n';
      
      for (int i = 0; i < _routes!.length && i < 5; i++) {
        final route = _routes![i];
        final distance = (route.totalDistance / 1000).toStringAsFixed(1);
        
        systemPrompt += '''
Route: ${route.name}
Date: ${route.startTime.toLocal().toString().split(' ')[0]}
Distance: $distance km
Duration: ${_formatDuration(route.duration)}
Average speed: ${route.averageSpeed.toStringAsFixed(1)} km/h
${route.description != null ? 'Description: ${route.description}' : ''}
''';
      }
    }
    
    // Add location info
    systemPrompt += '''
The user's default location is in Pitampura, Rohini, Delhi.
''';
    
    return systemPrompt;
  }
  
  // Format duration for system prompt
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours hours ${minutes > 0 ? '$minutes minutes' : ''}';
    } else {
      return '$minutes minutes';
    }
  }
  
  // Clear chat history
  Future<void> clearChat() async {
    _messages.clear();
    
    // Reinitialize chat session
    final systemPrompt = _createSystemPrompt();
    _chatSession = _model.startChat(
      history: [
        Content.text(systemPrompt),
      ],
    );
    
    // Add welcome message
    await _addAIMessage('Chat history cleared. How can I help you today?');
  }
  
  // Dispose resources
  void dispose() {
    _messagesController.close();
  }
} 