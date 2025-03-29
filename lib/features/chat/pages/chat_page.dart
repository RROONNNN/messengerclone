import 'package:flutter/material.dart';

import '../../../common/services/app_write_service.dart';
import 'package:appwrite/models.dart' as models;

class ChatPage extends StatefulWidget {

  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Future<models.User>? _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = AppWriteService.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<models.User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return Center(child: Text('User ID: ${snapshot.data!.$id}'));
        },
      ),
    );
  }
}