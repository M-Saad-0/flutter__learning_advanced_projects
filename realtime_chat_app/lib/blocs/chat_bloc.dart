import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:realtime_chat_app/models/chat_message.dart';
import 'package:realtime_chat_app/utils/websocket_utils.dart';


//States
class ChatState extends Equatable {
  @override
  List<Object> get props => [];
}
class ChatInitial extends ChatState {}
class ChatError extends ChatState {
  final String error;
  ChatError({required this.error});
  @override
  List<Object> get props => [error]; 
}
class ChatMessageReceived extends ChatState {
  final List<ChatMessage> messages;
  ChatMessageReceived({required this.messages});
  @override
  List<Object> get props => [messages]; 
}








//Events
class ChatEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class ChatTakeMessageEvent extends ChatEvent{
  final ChatMessage message;
  ChatTakeMessageEvent({required this.message});
  @override
  List<Object> get props => [message];
}
class ChatSendMessageEvent extends ChatEvent{
  final ChatMessage message;
  ChatSendMessageEvent({required this.message});
  @override
  List<Object> get props => [message];
}

class ChatStartEvent extends ChatEvent{}





class ChatBloc extends Bloc<ChatEvent, ChatState> {
  WebsocketUtils ws;
  final List<ChatMessage> _messages = [];
  ChatBloc({required this.ws}) : super(ChatInitial()) {
    on<ChatStartEvent>((event, emit) {
      emit(ChatMessageReceived(messages: []));
      ws.connectToChatStream().listen((message){
        add(ChatTakeMessageEvent(message: message));
      });
    });

    on<ChatTakeMessageEvent>((event, emit){
      _messages.add(event.message);
      emit(ChatMessageReceived(messages: List.from(_messages)));
    });


  on<ChatSendMessageEvent>((event, emit){
      _messages.add(event.message);
      ws.sendMessage(event.message.message);
      print(_messages);
      emit(ChatMessageReceived(messages: List.from(_messages)));
  });
  }

}


