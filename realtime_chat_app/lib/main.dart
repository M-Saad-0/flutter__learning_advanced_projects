import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import 'package:realtime_chat_app/blocs/chat_bloc.dart';
import 'package:realtime_chat_app/models/chat_message.dart';
import 'package:realtime_chat_app/utils/websocket_utils.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: DarkTheme.theme,
      darkTheme: DarkTheme.theme,
      themeMode: ThemeMode.dark,
      home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScrollController _scrollController;
  final TextEditingController _textController = TextEditingController();
  late ChatBloc _chatBloc;
  final GlobalKey _key = GlobalKey<FormState>();
  @override
  void initState() {
    _chatBloc = ChatBloc(ws: WebsocketUtils());
    _scrollController = ScrollController();
    _chatBloc.add(ChatStartEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("bg.jpg", fit: BoxFit.cover)),
          BlocBuilder<ChatBloc, ChatState>(
            bloc: _chatBloc,
            builder: (context, state) {
              if (state is ChatInitial) {
                return Center(child: CircularProgressIndicator());
              } else if (state is ChatError) {
                return Center(child: Text("Error"));
              }
              List<ChatMessage> messages =
                  (state as ChatMessageReceived).messages;
              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      
                      controller: _scrollController,
                      slivers: [
                        SliverAppBar(
                          title: Text("Broadcast Messages"),
                          floating: true,
                        ),
                        SliverList.builder(itemBuilder: (context, index){
                          return Align(
                            alignment: messages[index].isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: LiquidGlassContainer(
                                padding:  const EdgeInsets.all(8.0),
                                child: Text(messages[index].message),
                              ),
                            ),
                          );
                        }, itemCount: messages.length,),
                      
                        
                      ],
                    ),
                  ),
                  Container(
                          height: 75,
                          width: MediaQuery.sizeOf(context).width,
                          padding: EdgeInsets.all(16.0),
                          margin: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Form(
                                key: _key,
                                child: SizedBox(
                          width: MediaQuery.sizeOf(context).width-112,
                                  child: TextFormField(
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return "Please write some message";
                                      }
                                      return null;
                                    },
                                    onEditingComplete: (){if ((_key.currentState! as FormState)
                                      .validate()) {
                                    _chatBloc.add(
                                      ChatSendMessageEvent(
                                        message: ChatMessage(
                                          message: _textController.text,
                                          isUser: true,
                                        ),
                                      ),
                                    );
                                    _textController.clear();
                                  }},
                                    controller: _textController,
                                    decoration: InputDecoration(
                                      hintText: 'Type a message...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(25.0),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.0),
                              FloatingActionButton(
                                onPressed: () {
                                  if ((_key.currentState! as FormState)
                                      .validate()) {
                                    _chatBloc.add(
                                      ChatSendMessageEvent(
                                        message: ChatMessage(
                                          message: _textController.text,
                                          isUser: true,
                                        ),
                                      ),
                                    );
                                    _textController.clear();
                                  }
                                },
                                mini: true,
                                child: const Icon(Icons.send),
                              ),
                            ],
                          ),
                        ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class DarkTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Color(0xFF0F0F0F),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1C1C1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1C1C1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Color(0xFF8E8E93)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF007AFF),
        foregroundColor: Colors.white,
      ),
      listTileTheme: ListTileThemeData(textColor: Colors.white),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
    );
  }
}
