import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../common/services/app_write_service.dart';
import '../../../common/services/store.dart';

class MetaAiPage extends StatefulWidget {
  const MetaAiPage({super.key});

  @override
  State<MetaAiPage> createState() => _MetaAiPageState();
}

class _MetaAiPageState extends State<MetaAiPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meta AI'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(icon: Icon(Icons.delete), onPressed: _clearMessages),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]['role'] == 'user';
                return Row(
                  mainAxisAlignment:
                      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isUser)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: Text(
                            'AI',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    Column(
                      crossAxisAlignment:
                          isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _messages[index]['content']!,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          _messages[index]['timestamp']!,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi của bạn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMessages() async {
    final messagesJson = await Store.getMessagesChatWithAI();
    setState(() {
      _messages = List<Map<String, String>>.from(
        jsonDecode(messagesJson).map((msg) => Map<String, String>.from(msg)),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    final timestamp = DateTime.now().toString().substring(11, 16);

    setState(() {
      _messages.add({
        'role': 'user',
        'content': userMessage,
        'timestamp': timestamp,
      });
      _isLoading = true;
      _messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      List<Map<String, String>> history =
          _messages
              .map((msg) => {'role': msg['role']!, 'content': msg['content']!})
              .toList();

      final enhancedPrompt = """
    $userMessage
    Hãy đóng vai là một người bạn thân và trả lời như một người bạn thân..
    """;
      history.add({'role': 'user', 'content': enhancedPrompt});

      final responseData = await AppWriteService.callMetaAIFunction(
        history,
        5000,
      );

      if (responseData['ok'] == true) {
        setState(() {
          _messages.add({
            'role': 'ai',
            'content': responseData['completion'] ?? 'Not response from AI',
            'timestamp': timestamp,
          });
        });
      } else {
        throw Exception(
          responseData['error'] ??
              'Unknown error from AI, possibly due to unpaid operating fees',
        );
      }
    } catch (e) {
      final errorMsg =
          e is SocketException
              ? 'Lost network connection'
              : e is TimeoutException
              ? 'Timeout exceeded'
              : e.toString();

      setState(() {
        _messages.add({
          'role': 'ai',
          'content': errorMsg,
          'timestamp': timestamp,
        });
      });
    } finally {
      setState(() => _isLoading = false);
      await Store.saveMessagesWithAI(_messages);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  Future<void> _clearMessages() async {
    setState(() {
      _messages.clear();
    });
    await Store.saveMessagesWithAI(_messages);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
