class ChatMessage {
  final String message;
  final bool isUser;
  const ChatMessage({required this.isUser, required this.message});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(isUser: json['isUser'], message: json['message']);
  }
  Map<String, dynamic> toJson(){
    return {
      "isUser":isUser,
      "message":message
    };
  } 
}
