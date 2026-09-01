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

  bool _rememberMe = true;

  void _esqueciSenha() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.corCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: AppTheme.corPrimaria),
            SizedBox(width: 10),
            Text('Recuperar Senha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.corTexto)),
          ],
        ),
        content: const Text(
          'Para redefinir sua senha, entre em contato com o suporte do Comida & Afeto ou utilize o e-mail cadastrado na sua conta.',
          style: TextStyle(color: AppTheme.corSubtexto, fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

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
          if (_rememberMe) {
            await prefs.setString('password', password);
          } else {
            await prefs.remove('password');
          }

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

          // Retorna para a rota raiz (home) se a tela de login foi aberta via push
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
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
                Image.asset(
                  'assets/images/logo_completa.png',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
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
                          'Entrar na sua conta',
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
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Nome de usuário *',
                            hintText: 'Digite seu nome de usuário',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: AppTheme.corSubtexto,
                              size: 20,
                            ),
                            counterText: '',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Preencha o nome de usuário';
                            }
                            if (v.trim().length < 3) {
                              return 'O usuário deve ter ao menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Senha
                        TextFormField(
                          controller: _passwordController,
                          maxLength: 45,
                          obscureText: _obscurePassword,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: 'Senha *',
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
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Preencha sua senha';
                            }
                            if (v.length < 4) {
                              return 'A senha deve ter ao menos 4 caracteres';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        // Lembrar de mim & Esqueceu a senha
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppTheme.corPrimaria,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (val) =>
                                          setState(() => _rememberMe = val ?? true),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Lembrar-me',
                                    style: TextStyle(
                                        fontSize: 12, color: AppTheme.corSubtexto),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: TextButton(
                                onPressed: _esqueciSenha,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Esqueceu a senha?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.corPrimaria,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
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
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(child: Divider(color: AppTheme.corBorda.withOpacity(0.3))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'ou',
                                style: TextStyle(fontSize: 12, color: AppTheme.corSubtexto),
                              ),
                            ),
                            Expanded(child: Divider(color: AppTheme.corBorda.withOpacity(0.3))),
                          ],
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Cadastro(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add_outlined, size: 18),
                          label: const Text('Criar nova conta'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            foregroundColor: AppTheme.corPrimaria,
                            side: BorderSide(color: AppTheme.corPrimaria.withOpacity(0.6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
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
