import 'package:flutter/material.dart';
import 'package:frontend/screens/conversations_list_screen.dart';

/// Wrapper screen for ConversationsListScreen to maintain compatibility
/// with bottom navigation and other parts of the app that reference ChatListScreen
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConversationsListScreen();
  }
}
