import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/app_theme.dart';

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

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = await _cadastrar();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (error == null) {
          _done = true;
        } else {
          _errorText = error;
        }
      });
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

  // ── Páginas do formulário ──────────────────────────────────────────────

  Widget _page0() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionLabel('Acesso'),

      TextFormField(
        controller: _usernameController,
        maxLength: 45,
        decoration: const InputDecoration(
          labelText: 'Nome de usuário *',
          hintText: 'Escolha um nome de usuário',
          prefixIcon: Icon(Icons.person_outline, color: AppTheme.corSubtexto, size: 20),
          //counterText: '',
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Preencha o nome de usuário' : null,
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _passwordController,
        maxLength: 45,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: 'Senha *',
          hintText: 'Crie uma senha',
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
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Preencha sua senha' : null,
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _confirmController,
        maxLength: 45,
        obscureText: _obscureConfirm,
        decoration: InputDecoration(
          labelText: 'Confirmar senha *',
          hintText: 'Repita a senha',
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
    ],
  );

  Widget _page1() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionLabel('Dados pessoais'),

      TextFormField(
        controller: _nomeController,
        maxLength: 80,
        decoration: const InputDecoration(
          labelText: 'Nome completo',
          hintText: 'Seu nome completo',
          prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.corSubtexto, size: 20),
          counterText: '',
        ),
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'E-mail',
          hintText: 'seu@email.com',
          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.corSubtexto, size: 20),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return null; // campo opcional
          final emailRegex = RegExp(r'^[\w\-.]+@[\w\-]+\.[a-z]{2,}$');
          return emailRegex.hasMatch(v) ? null : 'E-mail inválido';
        },
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _celularController,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 11,
        decoration: const InputDecoration(
          labelText: 'Celular',
          hintText: '11999999999',
          prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.corSubtexto, size: 20),
          counterText: '',
        ),
      ),

      const SizedBox(height: 22),
      _sectionLabel('Localização'),

      TextFormField(
        controller: _cepController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 8,
        decoration: const InputDecoration(
          labelText: 'CEP',
          hintText: '00000000',
          prefixIcon: Icon(Icons.pin_drop_outlined, color: AppTheme.corSubtexto, size: 20),
          counterText: '',
        ),
      ),
      const SizedBox(height: 14),

      TextFormField(
        controller: _enderecoController,
        maxLength: 120,
        decoration: const InputDecoration(
          labelText: 'Endereço',
          hintText: 'Rua, número, bairro',
          prefixIcon: Icon(Icons.home_outlined, color: AppTheme.corSubtexto, size: 20),
          counterText: '',
        ),
      ),
    ],
  );

  Widget _page2() => Column(
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
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: AppTheme.corPrimaria, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Informações opcionais usadas para personalizar suas recomendações nutricionais.',
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
          decoration: const InputDecoration(
            labelText: 'Peso (kg)',
            hintText: 'Ex: 70,5',
            prefixIcon: Icon(Icons.monitor_weight_outlined,
                color: AppTheme.corSubtexto, size: 20),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final val = double.tryParse(v.replaceAll(',', '.'));
            if (val == null || val <= 0 || val > 500) return 'Peso inválido';
            return null;
          },
        ),
        TextFormField(
          controller: _alturaController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Altura (m)',
            hintText: 'Ex: 1,70',
            prefixIcon: Icon(Icons.height_rounded,
                color: AppTheme.corSubtexto, size: 20),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final val = double.tryParse(v.replaceAll(',', '.'));
            if (val == null || val <= 0 || val > 3) return 'Altura inválida';
            return null;
          },
        ),
      ]),

      const SizedBox(height: 32),

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
              'Resumo',
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
          ],
        ),
      ),
    ],
  );

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
              onPressed: () => Navigator.pop(context),
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