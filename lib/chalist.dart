import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:prototipo1/chat.dart';
import 'package:prototipo1/chat_model.dart';
import 'package:prototipo1/message.dart';
import 'package:prototipo1/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chatlist extends StatefulWidget {
  const Chatlist({super.key});

  @override
  State<Chatlist> createState() => _ChatlistState();
}

class _ChatlistState extends State<Chatlist> {
  //variaveis

  var httpClient = http.Client();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController promptController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late List<ChatModel> chats = [];
  String? forceErrorText;
  bool isLoading = true;
  
   @override
  void initState() {
    super.initState();
    // Call your method here.
    pedirChatList();
  }
  

  Widget construirChatList(ChatModel cht){
    return ListTile(
      title: Text(cht.title),
      leading: Icon(Icons.chat_bubble_outline),
      trailing: Text(cht.id.toString()),
      onTap: () {
        Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          // 'leading' is optional; Flutter adds the back button automatically
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Your already built class goes here
        body: Chat(cht.id), 
      ),
    ),
  );
      },
      );
  }

   pedirChatList() async {
    final url = Uri.parse('http://localhost:8080/apiOllama/chatlist');
    print(url);
    try {
      final preferences = await SharedPreferences.getInstance();
      String? username = await preferences.getString('username');
      //userId
      http.Response response = await httpClient.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": "$username", "password" : "empty"}),
      );
      print("hey");
      if (response.statusCode == 200) {
          print("prompt retornado");
        print(response.statusCode);
        print(response.headers);
        print(response.body);
        
        Iterable data =jsonDecode(response.body);
        
          setState(() {
          chats = List<ChatModel>.from(data.map((model)=> ChatModel.fromJson(model)));
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
              "Chats",
              style: TextStyle(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 100),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: chats.length,
                itemBuilder: (_, i) => construirChatList(chats[i]),
              ),
            ),

            if (isLoading)
              Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(),
              ),

            SizedBox(height: 10)
          ],
        ),
      ),
    );
  }
}
