import 'package:flutter/material.dart';
import 'package:prototipo1/cadastro.dart';
import 'package:prototipo1/chat.dart';
import 'package:prototipo1/home.dart';
import 'package:prototipo1/login.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final List<Widget> _tela = [Cadastro(), Login(), Home(), Chat()];

  int _indiceAtual = 0;

  void onTapTapped(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 123, 0),
        title: Text("Comida & Afeto", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
      ),
      body: _tela[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: onTapTapped,
        selectedItemColor: Colors.deepOrangeAccent,
        unselectedItemColor: Colors.grey,
        unselectedLabelStyle: TextStyle(color: Colors.grey),
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.add_shopping_cart), label: "Pedir"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Pedidos"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Alterar"),
        ],
      ),
    );
  }
}
