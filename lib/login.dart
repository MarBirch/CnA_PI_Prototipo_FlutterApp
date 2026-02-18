import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/user.dart';

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
    final url = Uri.parse('http://172.31.0.1:8080/apiUser/login');
    print(url);
    http.Response response = await httpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = response.body;
      if (!bool.parse(data)) {
        return 'Nome de usuario ou senha incorretos';
      } else {
        forceErrorText = null;
        
        // Map<String, dynamic> userData = jsonDecode(data);
        // user = User.fromJson(userData);
        setState(() {
          isLoggedIn = true;
          isLoading = false;
        });
        showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            "Sucesso!",
            style: TextStyle(color: Colors.green),
          ),
          content: Text("Marmita inserida com sucesso!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        )
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
            Text(
              "Iniciar Sessão",
              style: TextStyle(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 100,),
            Form(
              key: this._formKey,
              child: Center(
                child: Column(
                  children: [
                    TextFormField(
                      maxLength: 45,
                      forceErrorText: forceErrorText,
                      controller: usernameController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder( 
                          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color.fromARGB(123, 221, 87, 15), width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder( 
                          borderSide: BorderSide(color: Color.fromARGB(255, 221, 87, 15), width: 0.8),
                        ),
                        labelStyle: TextStyle(
                          color: Color.fromARGB(255, 221, 87, 15),
                        ),
                        hintStyle: TextStyle(color: Color.fromARGB(104, 0, 0, 0)),
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
                    TextFormField(
                      maxLength: 45,
                      obscureText: true,
                      forceErrorText: forceErrorText,
                      controller: passwordController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder( 
                          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color.fromARGB(123, 221, 87, 15), width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder( 
                          borderSide: BorderSide(color: Color.fromARGB(255, 221, 87, 15), width: 0.8),
                        ),
                        labelStyle: TextStyle(
                          color: Color.fromARGB(255, 221, 87, 15),
                        ),
                        hintStyle: TextStyle(color: Color.fromARGB(104, 0, 0, 0)),
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
                    else
                      ElevatedButton(
                        onPressed: () async {
                          String username = usernameController.text;
                          String password = passwordController.text;

                          final bool isValid =
                              _formKey.currentState?.validate() ?? false;
                          if (!isValid) {
                            return;
                          }

                          print(
                            usernameController.text +
                                "" +
                                passwordController.text,
                          );

                          setState(() => isLoading = true);
                          
                          final String? errorText = await verificacaoLogin(
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
