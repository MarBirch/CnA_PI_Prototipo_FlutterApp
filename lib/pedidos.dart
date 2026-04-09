import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:prototipo1/chat.dart';
import 'package:prototipo1/chat_model.dart';
import 'package:prototipo1/message.dart';
import 'package:prototipo1/pedido_mode.dart';
import 'package:prototipo1/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pedido extends StatefulWidget {
  const Pedido({super.key});

  @override
  State<Pedido> createState() => _PedidoState();
}

class _PedidoState extends State<Pedido> {
  //variaveis

  var httpClient = http.Client();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController promptController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late List<PedidoModel> pedidos = [];
  String? forceErrorText;
  bool isLoading = true;
  
   @override
  void initState() {
    super.initState();
    // Call your method here.
    pedirPedido();
  }
  

  Widget construirPedido(PedidoModel pedido){
    return ListTile(
      title: Text(pedido.user),
      leading: Icon(Icons.chat_bubble_outline),
      trailing: Text(pedido.id.toString()),
      onTap: () {
        Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Pedido'),
          // 'leading' is optional; Flutter adds the back button automatically
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Your already built class goes here
        body: Chat(pedido.id), 
      ),
    ),
  );
      },
      );
  }

   pedirPedido() async {
    final url = Uri.parse('http://localhost:8080/apiPedido/pedidos');
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
          pedidos = List<PedidoModel>.from(data.map((model)=> PedidoModel.fromJson(model)));
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
                itemCount: pedidos.length,
                itemBuilder: (_, i) => construirPedido(pedidos[i]),
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
