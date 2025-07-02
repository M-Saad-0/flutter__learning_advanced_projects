import 'dart:convert';

import 'package:realtime_chat_app/models/chat_message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketUtils {
    final _channel = WebSocketChannel.connect(Uri.parse("ws://localhost:8080/ws"));

  Stream<ChatMessage> connectToChatStream() {
    return _channel.stream.map((data){
      final decoder = jsonDecode(data);
      return ChatMessage(message: decoder["data"], isUser: decoder["isUser"]??false);
    });

  } 

  void sendMessage(String text){
    _channel.sink.add(text);
  }

   void dispose() {
    _channel.sink.close();
  }
}