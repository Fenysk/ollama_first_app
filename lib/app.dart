import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ollama_dart/ollama_dart.dart';
import 'package:ollama_first_app/chat_message.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:ollama_first_app/constants.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _selectedModel = defaultSelectedModel;
  final List<String> _pendingBase64Images = [];
  final List<Widget> _pendingImageWidgets = [];

  final client = OllamaClient(baseUrl: ollamaBaseUrl);

  final List<Map<String, dynamic>> _models = availableModels;

  Future<String?> networkImageToBase64(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
    } catch (e) {
      print('Error converting image to base64: $e');
    }
    return null;
  }

  Future<String?> fileToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<Image> base64ToImage(String base64Image) async {
    final bytes = base64Decode(base64Image);
    return Image.memory(bytes);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty && _pendingBase64Images.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    final request = GenerateCompletionRequest(
      model: _selectedModel,
      prompt: text,
      images: _pendingBase64Images,
      stream: true,
    );

    try {
      String responseText = '';
      await for (final chunk
          in client.generateCompletionStream(request: request)) {
        setState(() {
          responseText += chunk.response ?? '';
          if (_messages.last.isUser) {
            _messages.add(ChatMessage(text: responseText, isUser: false));
          } else {
            _messages.last = ChatMessage(text: responseText, isUser: false);
          }
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: 'Error: $e', isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
        _pendingBase64Images.clear();
        _pendingImageWidgets.clear();
      });
    }

    _controller.clear();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final base64Image = await fileToBase64(image);
      final imageWidget = await base64ToImage(base64Image!);

      setState(() {
        _pendingBase64Images.add(base64Image);
        _pendingImageWidgets.add(imageWidget);
        _messages.add(
            ChatMessage(text: null, isUser: true, imageWidget: imageWidget));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Ollama Chat'),
          actions: [
            DropdownButton<String>(
              value: _selectedModel,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedModel = newValue;
                  });
                }
              },
              items: _models
                  .map<DropdownMenuItem<String>>((Map<String, dynamic> value) {
                return DropdownMenuItem<String>(
                  value: value['name'],
                  child: Text(value['name']),
                );
              }).toList(),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatBubble(message: message);
                },
              ),
            ),
            if (_isLoading) LinearProgressIndicator(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      enabled: !_isLoading,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Enter your message',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                  if (_models.firstWhere((model) =>
                      model['name'] == _selectedModel)['supportsImages'])
                    IconButton(
                      icon: Icon(Icons.image),
                      onPressed: _pickImage,
                    ),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
