import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:prototipo1/message.dart';
import 'package:prototipo1/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chat extends StatefulWidget {
  int chatId;
  Chat(this.chatId,{super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  //variaveis

  var httpClient = http.Client();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController promptController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  List<ChatMessage> messages = [];
  String? forceErrorText;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Call your method here.
    pedirChatMessages();
  }

  pedirChatMessages() async {
    final url = Uri.parse('http://localhost:8080/apiOllama/chat/messages');
    print(url);
    try {
      final preferences = await SharedPreferences.getInstance();
      String? username = await preferences.getString('username');
      //userId
      http.Response response = await httpClient.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": "$username", "prompt" : "empty", "chatId": widget.chatId}),
      );
      print("hey");
      if (response.statusCode == 200) {
          print("prompt retornado");
        print(response.statusCode);
        print(response.headers);
        print(response.body);
        
        Iterable data =jsonDecode(response.body);
        
          setState(() {
          messages = List<ChatMessage>.from(data.map((model)=> ChatMessage.fromJson(model)));
          for (var i = 0; i < messages.length; i++){
            if(messages[i].role == "USER"){
              messages[i].isUser = true;
            } else {
              messages[i].isUser = false;
            }
          }
            isLoading = false;
          });
          setState(() {});
          return null;
        } else {
        print(response.statusCode);
        print(response.headers);
        print(response.body);
        return 'request failed with status: ${response.statusCode}';
      }
    } on Exception catch (e) {
      return e.toString();
    }
  }
  

  Widget buildMessage(ChatMessage msg){
    return Container(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: EdgeInsets.symmetric(horizontal: 1, vertical: 2),
      decoration: BoxDecoration(
        color: msg.isUser ? Colors.orange : Colors.deepOrange,
        borderRadius: BorderRadius.circular(14)),
      child: 
       MarkdownBlock(data: msg.message,),
      // Text(msg.message, style: TextStyle(color: msg.isUser ? Colors.white : Colors.white, fontSize: 16),), 
    );
  }

  enviarPrompt(String prompt) async {
    final url = Uri.parse('http://localhost:8080/apiOllama/prompt');
    print(url);
    try {
      http.Response response = await httpClient.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": prompt}),
      );
      print("hey");
      if (response.statusCode == 200) {
          print("prompt retornado");
          
        print(response.statusCode);
        print(response.headers);
        print(response.body);
        
        final data =jsonDecode(response.body) as Map<String, dynamic>;
        
          setState(() {
            messages.add(ChatMessage(data['content'], "ASSISTANT", false));

            isLoading = false;
          });
          setState(() {});
          return null;
        } else {
        print(response.statusCode);
        print(response.headers);
        print(response.body);
        return 'request failed with status: ${response.statusCode}';
      }
    } on Exception catch (e) {
      return e.toString();
    }
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  //UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Chat",
              style: TextStyle(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 100),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: messages.length,
                itemBuilder: (_, i) => buildMessage(messages[i]),
              ),
            ),

            if (isLoading)
              Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(),
              ),

            SizedBox(height: 10),
            Form(
              key: this._formKey,
              child: Center(
                child: Column(
                  children: [
                    TextFormField(
                      forceErrorText: forceErrorText,
                      controller: promptController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Color.fromARGB(123, 221, 87, 15),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 221, 87, 15),
                            width: 0.8,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: Color.fromARGB(255, 221, 87, 15),
                        ),
                        hintStyle: TextStyle(
                          color: Color.fromARGB(104, 0, 0, 0),
                        ),
                        labelText: 'Prompt',
                        hintText: 'Digite um prompt',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Preencha o prompt';
                        }
                        return null;
                      },
                    ),
                    if (!isLoading)
                      ElevatedButton(
                        onPressed: () async {
                          print("button");
                          String prompt = promptController.text;

                          bool isValid =
                              _formKey.currentState?.validate() ?? false;
                          print(isValid);
                          if (!isValid) {
                            print("what");
                            return;
                          }

                          print(promptController.text);
                          promptController.clear();

                          setState(() {
                            isLoading = true;
                            messages.add(ChatMessage(prompt, "USER", true));
                          });

                          scrollToBottom();

                          String? errorText = await enviarPrompt(prompt);
                          print(errorText);

                          if (context.mounted) {
                            setState(() {
                              isLoading =false;
                              scrollToBottom();
                            });

                            if (errorText != null) {
                              setState(() {
                                forceErrorText = errorText;
                              });
                            }
                          }
                        },
                        child: Text('Enviar'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
