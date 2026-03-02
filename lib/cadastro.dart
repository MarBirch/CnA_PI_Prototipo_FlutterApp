import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/user.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  var httpClient = http.Client();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? forceErrorText;
  bool isLoading = false;
  bool isLoggedIn = false;
  User user = User();

  cadastrar(String username, String password) async {
    final url = Uri.parse('http://localhost:8080/apiUser/cadastro');
    print(url);
    http.Response response = await httpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      var data = response.body;
      print(data);
      if (data == "username already exists") {
        print("username error");
        return 'Nome de usuario ja existe';
      } else if (data == "error") {
        return 'unknown error';
      } else if (data == "success"){
        print("logged");
        setState(() {
          forceErrorText = null;
          isLoggedIn = true;
          isLoading = false;
        });
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Sucesso!", style: TextStyle(color: Colors.green)),
            content: Text("Cadastro feito com sucesso!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
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
                "Cadastro",
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

                          String? errorText = await cadastrar(
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
                        onPressed: () {
                          //Navigator.push(context, Home());
                        },
                        child: Text('Continuar'),
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
