import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/auth_provider.dart';
import 'package:prototipo1/home.dart';
import 'package:prototipo1/user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  //variaveis

  var httpClient = http.Client();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? forceErrorText;
  bool isLoading = false;
  bool isLoggedIn = false;
  User user = User();

  verificacaoLogin(String username, String password) async {
    final url = Uri.parse('http://localhost:8080/apiUser/login');
    print(url);
    http.Response response = await httpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "senha": password}),
    );

    if (response.statusCode == 200) {
      final data = response.body;
      if (!bool.parse(data)) {
        print("wwrong");
        return 'Nome de usuario ou senha incorretos';
      } else {
        print("logged");

        String fakeToken = "abc123"; // Replace with real token

        setState(() {
          forceErrorText = null;
          isLoggedIn = true;
          isLoading = false;
        });
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Sucesso!", style: TextStyle(color: Colors.green)),
            content: Text("Login feito com sucesso!"),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).login(fakeToken);

                  // then save the user info
                  final preferences = await SharedPreferences.getInstance();
                  await preferences.setString('username', username);
                  await preferences.setString('password', password);
                },
                child: Text("Continuar"),
              ),
            ],
          ),
        );
        return null;
      }
    } else {
      return 'request failed with status: ${response.statusCode}';
    }
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
            if (!isLoggedIn)
              Text(
                "Iniciar Sessão",
                style: TextStyle(fontSize: 28),
                textAlign: TextAlign.center,
              )
            else
              Text(
                "Bem Vindo",
                style: TextStyle(fontSize: 28),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 100),
            Form(
              key: this._formKey,
              child: Center(
                child: Column(
                  children: [
                    if (!isLoggedIn)
                      TextFormField(
                        maxLength: 45,
                        forceErrorText: forceErrorText,
                        controller: usernameController,
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
                          labelText: 'Nome de usuario',
                          hintText: 'Digite seu nome de usuario',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Preencha o nome de usuario';
                          }
                          return null;
                        },
                      ),
                    if (!isLoggedIn)
                      TextFormField(
                        maxLength: 45,
                        obscureText: true,
                        forceErrorText: forceErrorText,
                        controller: passwordController,
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
                          labelText: 'Senha',
                          hintText: 'Digite a sua senha',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Preencha sua senha';
                          }
                          return null;
                        },
                      ),
                    if (isLoading)
                      CircularProgressIndicator()
                    else if (!isLoggedIn)
                      ElevatedButton(
                        onPressed: () async {
                          print("button");
                          String username = usernameController.text;
                          String password = passwordController.text;

                          // bool isValid =
                          //     _formKey.currentState?.validate() ?? false;
                          // print(isValid);
                          // if (!isValid) {
                          // print("what");
                          //   return;
                          // }

                          print(
                            usernameController.text +
                                "" +
                                passwordController.text,
                          );

                          setState(() => isLoading = true);

                          String? errorText = await verificacaoLogin(
                            username,
                            password,
                          );

                          if (context.mounted) {
                            setState(() => isLoading = false);
                            if (errorText != null) {
                              setState(() {
                                forceErrorText = errorText;
                              });
                            }
                          }
                        },
                        child: Text('Entrar'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          final preferences =
                              await SharedPreferences.getInstance();
                          await preferences.setBool('showOnboard', true);
                        },
                        child: Text('Continuar'),
                      ),

                    ElevatedButton(
                      onPressed: () async {
                        // call your logout function

                        // set userinfo to null, will rebuild the consumer in main.dart
                        context.read<AuthProvider>().logout();

                        // then clear the user info from local storage
                        final preferences =
                            await SharedPreferences.getInstance();
                        await preferences.remove('username');
                        await preferences.remove('password');
                      },
                      child: Text("logout"),
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
