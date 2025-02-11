import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isLoading = false;

  Future<void> query(String prompt) async {
    _isLoading = true;
    setState(() {});

    final message = {
      "role": "user",
      "content": prompt,
    };

    _chatMessages.add(message);

    final data = {
      "model": "mistral-small",
      "messages": _chatMessages,
      "stream": false,
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:11434/api/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _chatMessages.add({
          "role": "system",
          "content": responseData['message']['content'],
        });

        _controller.clear();
        setState(() {});
      } else {
        _chatMessages.remove(message);
        setState(() {});
      }
    } catch (error) {
      _chatMessages.remove(message);
      setState(() {});
    } finally {
      _isLoading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _chatMessages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _chatMessages.length && _isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final message = _chatMessages[index];
                    return ListTile(
                      title: Text(message['content'] ?? ''),
                      leading: message['role'] == 'user'
                          ? const Icon(Icons.person)
                          : const Icon(Icons.computer),
                    );
                  },
                ),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter your message',
                  ),
                  enabled: !_isLoading,
                  onSubmitted: (value) {
                    query(value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
