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

  Widget construirPedido(PedidoModel pedido) {
    return Container(
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.orange.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.orange.withOpacity(0.15),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Title with icon
      Row(
        children: [
          Icon(Icons.store, color: Colors.deepOrange.shade600, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              pedido.nomeMarmiteria,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange.shade700,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Dates
      Row(
        children: [
          Icon(Icons.calendar_today,
              size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            "${pedido.dataCriada} / ${pedido.dataPedido}",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),

      const SizedBox(height: 10),

      // Status badge with icon
      Row(
        children: [
          Icon(Icons.info_outline,
              size: 18, color: Colors.deepOrange.shade600),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pedido.status,
              style: TextStyle(
                color: Colors.deepOrange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 10),

      // Ingredients
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.restaurant_menu,
              size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              pedido.ingredientes.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      // Price aligned right
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.attach_money,
              size: 18, color: Colors.deepOrange.shade600),
          Text(
            "R\$ ${pedido.valor}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade600,
            ),
          ),
        ],
      ),
    ],
  ),
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
        body: jsonEncode({"username": "$username", "password": "empty"}),
      );
      print("hey");
      if (response.statusCode == 200) {
        print("prompt retornado");
        print(response.statusCode);
        print(response.headers);
        print(response.body);

        Iterable data = jsonDecode(response.body);

        setState(() {
          pedidos = data.map((e) => PedidoModel.fromJson(e)).toList();
          //pedidos = List<PedidoModel>.from(data.map((model)=> PedidoModel.fromJson(model)));
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
          children: [
            SizedBox(height: 30,),
            Text(
              "Pedidos",
              style: TextStyle(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            if (isLoading)
              Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(color: Colors.orangeAccent,),
              ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: pedidos.length,
                itemBuilder: (_, i) => construirPedido(pedidos[i]),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
