import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/auth_provider.dart';
import 'package:prototipo1/cadastro.dart';
import 'package:prototipo1/home.dart';
import 'package:prototipo1/navigation.dart';
import 'package:prototipo1/user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _httpClient = http.Client();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _errorText;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String?> _verificacaoLogin(String username, String password) async {
    final url = Uri.parse('http://localhost:8080/apiUser/login');
    try {
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'senha': password}),
      );
      if (response.statusCode == 200) {
        if (!bool.parse(response.body)) {
          return 'Nome de usuário ou senha incorretos';
        }
        if (context.mounted) {
          await Provider.of<AuthProvider>(
            context,
            listen: false,
          ).login('token_$username');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);
          await prefs.setString('password', password);

          // Busca e salva o userId
          try {
            final idUrl = Uri.parse(
              'http://localhost:8080/apiUser/id?username=$username',
            );
            final idResp = await _httpClient.get(idUrl);
            if (idResp.statusCode == 200) {
              final userId = int.tryParse(idResp.body.trim());
              if (userId != null) {
                await prefs.setInt('userId', userId);
              }
            }
          } catch (_) {}
        }
        return null;
      }
      return 'Falha na requisição: ${response.statusCode}';
    } catch (e) {
      return 'Erro de conexão: $e';
    }
  }

  Future<void> _onEntrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = await _verificacaoLogin(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo / Título ────────────────────────────────────────
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.corPrimaria,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lunch_dining_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comida & Afeto',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.corPrimaria,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Faça login para continuar',
                  style: TextStyle(fontSize: 14, color: AppTheme.corSubtexto),
                ),

                const SizedBox(height: 36),

                // ── Card de login ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.corCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.corBorda.withOpacity(0.4),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.corPrimaria.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.corTexto,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Usuário
                        TextFormField(
                          controller: _usernameController,
                          maxLength: 45,
                          decoration: const InputDecoration(
                            labelText: 'Nome de usuário',
                            hintText: 'Digite seu nome de usuário',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: AppTheme.corSubtexto,
                              size: 20,
                            ),
                            counterText: '',
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Preencha o nome de usuário'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Senha
                        TextFormField(
                          controller: _passwordController,
                          maxLength: 45,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            hintText: 'Digite sua senha',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppTheme.corSubtexto,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppTheme.corSubtexto,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            counterText: '',
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Preencha sua senha'
                              : null,
                        ),

                        // Mensagem de erro
                        if (_errorText != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.corErro.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.corErro.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.corErro,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorText!,
                                    style: const TextStyle(
                                      color: AppTheme.corErro,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        // Botão Entrar
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.corPrimaria,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _onEntrar,
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text('Entrar'),
                          ),

                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Cadastro(),
                              ),
                            );
                            setState(() {});
                          },
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('Cadastro'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
