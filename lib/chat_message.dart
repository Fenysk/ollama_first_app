import 'package:flutter/material.dart';

class ChatMessage {
  final String? text;
  final bool isUser;
  final Image? imageWidget;

  ChatMessage({this.text, required this.isUser, this.imageWidget});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = message.isUser ? Colors.blue[100] : Colors.grey[200];
    final textColor = Colors.black;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 4.0),
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.imageWidget != null) 
                Container(
                  constraints: BoxConstraints(maxHeight: 200, maxWidth: 200),
                  child: message.imageWidget!,
                ),
              if (message.text != null && message.text!.isNotEmpty)
                SelectableText(
                  message.text!.trim(),
                  style: TextStyle(color: textColor),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
