import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final _httpClient = http.Client();
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Controllers — identidade
  final _usernameController    = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmController     = TextEditingController();

  // Controllers — dados pessoais
  final _nomeController        = TextEditingController();
  final _emailController       = TextEditingController();
  final _celularController     = TextEditingController();

  // Controllers — localização
  final _enderecoController    = TextEditingController();
  final _cepController         = TextEditingController();

  // Controllers — saúde
  final _pesoController        = TextEditingController();
  final _alturaController      = TextEditingController();

  String? _errorText;
  bool _isLoading  = false;
  bool _done       = false;
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

  // CEP
  bool _cepLoading = false;
  String? _cepError;

  int _currentPage = 0;
  static const int _totalPages = 3;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    _enderecoController.dispose();
    _cepController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Busca CEP via ViaCEP ───────────────────────────────────────────────

  Future<void> _buscarCep() async {
    final cep = _cepController.text.trim();
    if (cep.length != 8) return;
    setState(() { _cepLoading = true; _cepError = null; });
    try {
      final res = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['erro'] == true || data['erro'] == 'true') {
          setState(() => _cepError = 'CEP não encontrado.');
        } else {
          final logradouro = data['logradouro'] ?? '';
          final bairro     = data['bairro']     ?? '';
          final localidade = data['localidade']  ?? '';
          final uf         = data['uf']          ?? '';
          final partes = <String>[
            if (logradouro.isNotEmpty) logradouro,
            if (bairro.isNotEmpty)     bairro,
            if (localidade.isNotEmpty) '$localidade/$uf',
          ];
          setState(() {
            _enderecoController.text = partes.join(', ');
            _cepError = null;
          });
        }
      } else {
        setState(() => _cepError = 'Erro ao consultar CEP.');
      }
    } catch (_) {
      setState(() => _cepError = 'Sem conexão. Verifique a internet.');
    } finally {
      setState(() => _cepLoading = false);
    }
  }

  // ── Validação da página atual ──────────────────────────────────────────
  bool _validateCurrentPage() {
    // valida apenas os campos visíveis da página
    return _formKey.currentState?.validate() ?? false;
  }

  void _nextPage() {
    if (!_validateCurrentPage()) return;
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _errorText = null;
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _onCadastrar();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _errorText = null;
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Chamada de API ─────────────────────────────────────────────────────
  Future<String?> _cadastrar() async {
    final url = Uri.parse('http://localhost:8080/apiUser/cadastro');
    try {
      final body = {
        'username':  _usernameController.text.trim(),
        'senha':  _passwordController.text,
        'nome':      _nomeController.text.trim(),
        'email':     _emailController.text.trim(),
        'celular':   int.tryParse(_celularController.text.trim()),
        'endereco':  _enderecoController.text.trim(),
        'cep':       _cepController.text.trim(),
        'peso':      double.tryParse(_pesoController.text.trim().replaceAll(',', '.')),
        'altura':    double.tryParse(_alturaController.text.trim().replaceAll(',', '.')),
      };

      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (response.body == 'username already exists') return 'Nome de usuário já existe';
        if (response.body == 'error')                   return 'Erro desconhecido. Tente novamente.';
        if (response.body == 'success')                 return null;
      }
      return 'Falha na requisição: ${response.statusCode}';
    } catch (e) {
      return 'Erro de conexão: $e';
    }
  }

  Future<void> _onCadastrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptTerms) {
      setState(() {
        _errorText = 'Você precisa aceitar os Termos de Uso para criar a conta.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = await _cadastrar();

    if (mounted) {
      if (error == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', _usernameController.text.trim());
          await prefs.setString('nome',     _nomeController.text.trim());
          await prefs.setString('email',    _emailController.text.trim());
          await prefs.setString('celular',  _celularController.text.trim());
          await prefs.setString('endereco', _enderecoController.text.trim());
          await prefs.setString('cep',      _cepController.text.trim());
          await prefs.setString('peso',     _pesoController.text.trim());
          await prefs.setString('altura',   _alturaController.text.trim());
        } catch (_) {}
        setState(() {
          _isLoading = false;
          _done      = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorText = error;
        });
      }
    }
  }

  // ── Helpers visuais ────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.corSubtexto,
        letterSpacing: 1.3,
      ),
    ),
  );

  Widget _fieldRow(List<Widget> children) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children
        .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
        .toList()
      ..removeLast(),
  );

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.corErro.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.corErro.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppTheme.corErro, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style: const TextStyle(color: AppTheme.corErro, fontSize: 13)),
        ),
      ],
    ),
  );

  bool _acceptTerms = false;

  Widget _passwordStrengthIndicator() {
    final pass = _passwordController.text;
    if (pass.isEmpty) return const SizedBox.shrink();

    double strength = 0.0;
    String label = 'Fraca';
    Color color = AppTheme.corErro;

    if (pass.length >= 6) {
      strength = 0.33;
      label = 'Fraca';
      color = AppTheme.corErro;
    }
    if (pass.length >= 8 && RegExp(r'[0-9]').hasMatch(pass)) {
      strength = 0.66;
      label = 'Média';
      color = AppTheme.corAlerta;
    }
    if (pass.length >= 8 &&
        RegExp(r'[0-9]').hasMatch(pass) &&
        RegExp(r'[A-Z]').hasMatch(pass) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>_]').hasMatch(pass)) {
      strength = 1.0;
      label = 'Forte';
      color = AppTheme.corSucesso;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength,
                  backgroundColor: AppTheme.corBorda.withOpacity(0.3),
                  color: color,
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Força: $label',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    );
  }

  // ── Páginas do formulário ──────────────────────────────────────────────

  Widget _page0() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionLabel('Acesso'),

      TextFormField(
        controller: _usernameController,
        maxLength: 45,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: const InputDecoration(
          labelText: 'Nome de usuário *',
          hintText: 'Escolha um nome de usuário único',
          prefixIcon: Icon(Icons.person_outline, color: AppTheme.corSubtexto, size: 20),
          counterText: '',
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Preencha o nome de usuário';
          if (v.trim().length < 3) return 'Deve conter pelo menos 3 caracteres';
          if (RegExp(r'\s').hasMatch(v)) return 'Não pode conter espaços';
          return null;
        },
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _passwordController,
        maxLength: 45,
        obscureText: _obscurePassword,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Senha *',
          hintText: 'Crie uma senha segura',
          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.corSubtexto, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppTheme.corSubtexto, size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          counterText: '',
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Preencha sua senha';
          if (v.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
          return null;
        },
      ),
      _passwordStrengthIndicator(),
      const SizedBox(height: 14),

      TextFormField(
        controller: _confirmController,
        maxLength: 45,
        obscureText: _obscureConfirm,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: 'Confirmar senha *',
          hintText: 'Repita a mesma senha',
          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.corSubtexto, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppTheme.corSubtexto, size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          counterText: '',
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Confirme sua senha';
          if (v != _passwordController.text) return 'As senhas não coincidem';
          return null;
        },
      ),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            );
          }
        },
        icon: const Icon(Icons.login_rounded, size: 18),
        label: const Text('Já possui uma conta? Faça login'),
      ),
    ],
  );

  Widget _page1() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionLabel('Dados pessoais'),

      TextFormField(
        controller: _nomeController,
        maxLength: 80,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: const InputDecoration(
          labelText: 'Nome completo *',
          hintText: 'Digite seu nome completo',
          prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.corSubtexto, size: 20),
          counterText: '',
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Preencha seu nome completo';
          if (v.trim().length < 3) return 'Nome muito curto';
          return null;
        },
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: const InputDecoration(
          labelText: 'E-mail *',
          hintText: 'seu@email.com',
          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.corSubtexto, size: 20),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Preencha o e-mail';
          final emailRegex = RegExp(r'^[\w\-.]+@[\w\-]+\.[a-z]{2,}$');
          return emailRegex.hasMatch(v.trim()) ? null : 'Insira um e-mail válido (ex: nome@dominio.com)';
        },
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _celularController,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 11,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: const InputDecoration(
          labelText: 'Celular / WhatsApp *',
          hintText: '11999999999 (apenas números)',
          prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.corSubtexto, size: 20),
          counterText: '',
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Preencha o celular';
          if (v.trim().length < 10) return 'Digite um número válido com DDD (10 ou 11 dígitos)';
          return null;
        },
      ),

      const SizedBox(height: 22),
      _sectionLabel('Localização'),

      StatefulBuilder(
        builder: (context, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _cepController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 8,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (v) {
                setLocal(() {});
                if (v.length == 8) _buscarCep();
              },
              decoration: InputDecoration(
                labelText: 'CEP *',
                hintText: '00000000 (8 dígitos)',
                prefixIcon: const Icon(Icons.pin_drop_outlined, color: AppTheme.corSubtexto, size: 20),
                counterText: '',
                errorText: _cepError,
                suffixIcon: _cepLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.corPrimaria),
                        ),
                      )
                    : _cepController.text.length == 8
                        ? IconButton(
                            tooltip: 'Buscar CEP',
                            icon: const Icon(Icons.search_rounded, color: AppTheme.corPrimaria),
                            onPressed: _buscarCep,
                          )
                        : null,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Preencha o CEP';
                if (v.trim().length != 8) return 'O CEP deve ter exatamente 8 dígitos';
                return null;
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _enderecoController,
        maxLength: 120,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: const InputDecoration(
          labelText: 'Endereço Completo *',
          hintText: 'Rua, número, complemento e bairro',
          prefixIcon: Icon(Icons.home_outlined, color: AppTheme.corSubtexto, size: 20),
          counterText: '',
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Preencha o endereço de entrega';
          return null;
        },
      ),
    ],
  );

  Widget _page2() {
    double? peso = double.tryParse(_pesoController.text.replaceAll(',', '.'));
    double? altura = double.tryParse(_alturaController.text.replaceAll(',', '.'));
    double? imc;
    String imcTexto = '';
    if (peso != null && altura != null && peso > 0 && altura > 0) {
      imc = peso / (altura * altura);
      if (imc < 18.5) {
        imcTexto = '${imc.toStringAsFixed(1)} (Abaixo do peso)';
      } else if (imc < 25) {
        imcTexto = '${imc.toStringAsFixed(1)} (Peso normal)';
      } else if (imc < 30) {
        imcTexto = '${imc.toStringAsFixed(1)} (Sobrepeso)';
      } else {
        imcTexto = '${imc.toStringAsFixed(1)} (Obesidade)';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('Dados de saúde'),

        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppTheme.corPrimaria.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.corPrimaria.withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppTheme.corPrimaria, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Informações nutricionais usadas pela Nutri (IA) para calcular calorias e recomendar refeições.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.corSubtexto,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),

        _fieldRow([
          TextFormField(
            controller: _pesoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Peso (kg)',
              hintText: 'Ex: 70.5',
              prefixIcon: Icon(Icons.monitor_weight_outlined,
                  color: AppTheme.corSubtexto, size: 20),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final val = double.tryParse(v.replaceAll(',', '.'));
              if (val == null || val < 20 || val > 300) return 'Peso entre 20 e 300 kg';
              return null;
            },
          ),
          TextFormField(
            controller: _alturaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Altura (m)',
              hintText: 'Ex: 1.70',
              prefixIcon: Icon(Icons.height_rounded,
                  color: AppTheme.corSubtexto, size: 20),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final val = double.tryParse(v.replaceAll(',', '.'));
              if (val == null || val < 0.5 || val > 2.5) return 'Altura entre 0.5m e 2.5m';
              return null;
            },
          ),
        ]),

        if (imcTexto.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.corPrimaria.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.corPrimaria.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, color: AppTheme.corPrimaria, size: 18),
                const SizedBox(width: 10),
                Text(
                  'IMC Estimado: ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.corTexto),
                ),
                Text(
                  imcTexto,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.corPrimaria),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Resumo antes de confirmar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.corCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.corBorda.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumo da Conta',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.corSubtexto,
                    letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              _resumoItem(Icons.person_outline, 'Usuário', _usernameController.text),
              if (_nomeController.text.isNotEmpty)
                _resumoItem(Icons.badge_outlined, 'Nome', _nomeController.text),
              if (_emailController.text.isNotEmpty)
                _resumoItem(Icons.email_outlined, 'E-mail', _emailController.text),
              if (_celularController.text.isNotEmpty)
                _resumoItem(Icons.phone_outlined, 'Celular', _celularController.text),
              if (_cepController.text.isNotEmpty)
                _resumoItem(Icons.pin_drop_outlined, 'CEP', _cepController.text),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Checkbox de Termos
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _acceptTerms,
                activeColor: AppTheme.corPrimaria,
                onChanged: (val) => setState(() => _acceptTerms = val ?? false),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Aceito os Termos de Uso e Política de Privacidade do Comida & Afeto.',
                style: TextStyle(fontSize: 12, color: AppTheme.corSubtexto, height: 1.3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _resumoItem(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.corPrimaria),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.corTexto)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, color: AppTheme.corSubtexto),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );

  // ── Stepper visual ─────────────────────────────────────────────────────

  Widget _stepper() {
    const labels = ['Acesso', 'Pessoal', 'Saúde'];
    return Row(
      children: List.generate(_totalPages, (i) {
        final done    = i < _currentPage;
        final active  = i == _currentPage;
        final color   = done || active ? AppTheme.corPrimaria : AppTheme.corBorda.withOpacity(0.4);
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width:  active ? 34 : 28,
                      height: active ? 34 : 28,
                      decoration: BoxDecoration(
                        color: done
                            ? AppTheme.corPrimaria
                            : active
                                ? AppTheme.corPrimaria
                                : AppTheme.corCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: active ? 2 : 1.2),
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: active
                                      ? Colors.white
                                      : AppTheme.corSubtexto,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        color: active ? AppTheme.corPrimaria : AppTheme.corSubtexto,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < _totalPages - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: done ? AppTheme.corPrimaria : AppTheme.corBorda.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      body: SafeArea(
        child: Column(
          children: [
            // ── Cabeçalho ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.corDestaque,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person_add_outlined,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _done ? 'Tudo certo!' : 'Criar conta',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.corPrimaria,
                            ),
                          ),
                          Text(
                            _done
                                ? 'Conta criada com sucesso'
                                : 'Preencha as informações',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.corSubtexto),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (!_done) ...[
                    const SizedBox(height: 20),
                    _stepper(),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            Divider(
                height: 1,
                color: AppTheme.corBorda.withOpacity(0.25)),

            // ── Conteúdo ─────────────────────────────────────────────
            Expanded(
              child: _done ? _successState() : _formState(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Estado de sucesso ──────────────────────────────────────────────────

  Widget _successState() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.corCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.corSucesso.withOpacity(0.35), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.corPrimaria.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.corSucesso.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.corSucesso.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppTheme.corSucesso, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              'Bem-vindo, ${_usernameController.text}!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.corTexto,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sua conta foi criada com sucesso.\nAgora você pode fazer login.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.corSubtexto,
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                  );
                }
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Ir para o Login'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ── Estado de formulário ───────────────────────────────────────────────

  Widget _formState() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _pageWrapper(_page0()),
                _pageWrapper(_page1()),
                _pageWrapper(_page2()),
              ],
            ),
          ),

          // ── Botões de navegação ─────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: AppTheme.corCard,
              border: Border(
                top: BorderSide(
                    color: AppTheme.corBorda.withOpacity(0.25), width: 0.6),
              ),
            ),
            child: Column(
              children: [
                if (_errorText != null) ...[
                  _errorBox(_errorText!),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _prevPage,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 15),
                          label: const Text('Voltar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.corPrimaria,
                            side: const BorderSide(
                                color: AppTheme.corPrimaria, width: 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.corPrimaria))
                          : ElevatedButton.icon(
                              onPressed: _nextPage,
                              icon: Icon(
                                _currentPage < _totalPages - 1
                                    ? Icons.arrow_forward_ios_rounded
                                    : Icons.check_rounded,
                                size: 17,
                              ),
                              label: Text(
                                _currentPage < _totalPages - 1
                                    ? 'Continuar'
                                    : 'Criar conta',
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageWrapper(Widget child) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    child: child,
  );
}