import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:prototipo1/auth_provider.dart';
import 'package:prototipo1/cadastro.dart';
import 'package:prototipo1/chalist.dart';
import 'package:prototipo1/chat.dart';
import 'package:prototipo1/home.dart';
import 'package:prototipo1/login.dart';
import 'package:prototipo1/pedidos.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
    int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
  static final List<Widget> _widgetOptions = <Widget>[Pedido(),Home(), const Chatlist(), const Cadastro(), const Login()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text("Comida & Afeto", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
      
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      body: Center(child: _widgetOptions[_selectedIndex]),
      drawer: Drawer(
        
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.orange),
              child: Text('Adicionar Perfil'),
              
            ),
            ListTile(
              selectedTileColor: Colors.orangeAccent,
              selectedColor: Colors.black,
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                // Update the state of the app
                _onItemTapped(0);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              selectedTileColor: Colors.orangeAccent,
              selectedColor: Colors.black,
              title: const Text('Pedidos'),
              selected: _selectedIndex == 1,
              onTap: () {
                // Update the state of the app
                _onItemTapped(1);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              selectedTileColor: Colors.orangeAccent,
              selectedColor: Colors.black,
              title: const Text('Chats'),
              selected: _selectedIndex == 2,
              onTap: () {
                // Update the state of the app
                _onItemTapped(2);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              selectedTileColor: Colors.orangeAccent,
              selectedColor: Colors.black,
              title: const Text('Cadastro dev'),
              selected: _selectedIndex == 3,
              onTap: () {
                // Update the state of the app
                _onItemTapped(3);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              selectedTileColor: Colors.orangeAccent,
              selectedColor: Colors.black,
              title: const Text('Login dev'),
              selected: _selectedIndex == 4,
              onTap: () {
                // Update the state of the app
                _onItemTapped(4);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              selectedTileColor: Colors.orangeAccent,
              selectedColor: Colors.black,
              title: const Text('Logout'),
              selected: _selectedIndex == 5,
              onTap: () async {
                        // call your logout function

                        // set userinfo to null, will rebuild the consumer in main.dart
                        context.read<AuthProvider>().logout();

                        // then clear the user info from local storage
                        final preferences =
                            await SharedPreferences.getInstance();
                        await preferences.remove('username');
                        await preferences.remove('password');
                      
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}