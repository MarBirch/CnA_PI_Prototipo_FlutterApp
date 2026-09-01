import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelo local do usuário (campos que a API retorna / aceita)
// ─────────────────────────────────────────────────────────────────────────────
class _UserProfile {
  String username;
  String nome;
  String email;
  String celular;
  String endereco;
  String cep;
  String peso;
  String altura;

  _UserProfile({
    this.username = '',
    this.nome     = '',
    this.email    = '',
    this.celular  = '',
    this.endereco = '',
    this.cep      = '',
    this.peso     = '',
    this.altura   = '',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────────────────────────────────────
class Configuracoes extends StatefulWidget {
  final int initialIndex;
  const Configuracoes({super.key, this.initialIndex = 0});

  @override
  State<Configuracoes> createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<Configuracoes>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late _UserProfile _profile;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex < 3 ? widget.initialIndex : 0,
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Carrega dados salvos em SharedPreferences e busca do servidor ─────

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';

    setState(() {
      _profile = _UserProfile(
        username: username,
        nome:     prefs.getString('nome')     ?? '',
        email:    prefs.getString('email')    ?? '',
        celular:  prefs.getString('celular')  ?? '',
        endereco: prefs.getString('endereco') ?? '',
        cep:      prefs.getString('cep')      ?? '',
        peso:     prefs.getString('peso')     ?? '',
        altura:   prefs.getString('altura')   ?? '',
      );
      _isLoading = false;
    });

    if (username.isNotEmpty) {
      try {
        final resp = await http.get(
          Uri.parse('http://localhost:8080/apiUser/perfil?username=$username'),
        ).timeout(const Duration(seconds: 5));

        if (resp.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(resp.body);
          final updated = _UserProfile(
            username: username,
            nome:     data['nome']     ?? '',
            email:    data['email']    ?? '',
            celular:  data['celular']  != null ? data['celular'].toString() : '',
            endereco: data['endereco'] ?? '',
            cep:      data['cep']      ?? '',
            peso:     data['peso']     != null ? data['peso'].toString() : '',
            altura:   data['altura']   != null ? data['altura'].toString() : '',
          );

          await prefs.setString('nome',     updated.nome);
          await prefs.setString('email',    updated.email);
          await prefs.setString('celular',  updated.celular);
          await prefs.setString('endereco', updated.endereco);
          await prefs.setString('cep',      updated.cep);
          await prefs.setString('peso',     updated.peso);
          await prefs.setString('altura',   updated.altura);

          if (mounted) {
            setState(() {
              _profile = updated;
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<bool> _saveProfileToServer(_UserProfile updated) async {
    try {
      final body = {
        'username': updated.username,
        'nome':     updated.nome,
        'email':    updated.email,
        'celular':  int.tryParse(updated.celular),
        'endereco': updated.endereco,
        'cep':      updated.cep,
        'peso':     double.tryParse(updated.peso.replaceAll(',', '.')),
        'altura':   double.tryParse(updated.altura.replaceAll(',', '.')),
      };

      final response = await http.put(
        Uri.parse('http://localhost:8080/apiUser/atualizar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && response.body.trim() == 'true') {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Header com avatar + nome ───────────────────────────────────────────

  Widget _profileHeader() {
    final initials = _profile.nome.isNotEmpty
        ? _profile.nome.trim().split(' ').map((w) => w[0]).take(2).join()
        : (_profile.username.isNotEmpty ? _profile.username[0].toUpperCase() : '?');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.corPrimaria,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.corPrimaria.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _profile.nome.isNotEmpty ? _profile.nome : _profile.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_profile.nome.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '@${_profile.username}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Badges de info
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (_profile.email.isNotEmpty)
                _headerBadge(Icons.email_outlined, _profile.email),
              if (_profile.celular.isNotEmpty)
                _headerBadge(Icons.phone_outlined, _profile.celular),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerBadge(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 12),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      );

  // ── Tabs ───────────────────────────────────────────────────────────────

  Widget _tabBar() => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: AppTheme.corCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.corBorda.withOpacity(0.3), width: 0.6),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.corPrimaria,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.corSubtexto,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.person_outline_rounded, size: 18), text: 'Perfil'),
            Tab(icon: Icon(Icons.health_and_safety_outlined, size: 18), text: 'Saúde'),
            Tab(icon: Icon(Icons.settings_outlined, size: 18), text: 'Conta'),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 0 — Dados Pessoais
  // ─────────────────────────────────────────────────────────────────────────

  Widget _tabPerfil() => _EditPerfil(
        profile: _profile,
        onSaved: (updated) async {
          final serverOk = await _saveProfileToServer(updated);
          if (!serverOk) {
            if (mounted) {
              _showError('Erro ao atualizar o perfil no servidor. Verifique a conexão.');
            }
            throw Exception('Falha ao atualizar perfil no servidor');
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('nome',     updated.nome);
          await prefs.setString('email',    updated.email);
          await prefs.setString('celular',  updated.celular);
          await prefs.setString('endereco', updated.endereco);
          await prefs.setString('cep',      updated.cep);
          setState(() => _profile = updated);
          if (mounted) {
            _showSuccess('Perfil atualizado com sucesso no banco de dados!');
          }
        },
      );

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1 — Saúde
  // ─────────────────────────────────────────────────────────────────────────

  Widget _tabSaude() => _EditSaude(
        profile: _profile,
        onSaved: (updated) async {
          final serverOk = await _saveProfileToServer(updated);
          if (!serverOk) {
            if (mounted) {
              _showError('Erro ao atualizar dados de saúde no servidor. Verifique a conexão.');
            }
            throw Exception('Falha ao atualizar dados de saúde no servidor');
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('peso',   updated.peso);
          await prefs.setString('altura', updated.altura);
          setState(() => _profile = updated);
          if (mounted) {
            _showSuccess('Dados de saúde atualizados no banco de dados!');
          }
        },
      );

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2 — Conta / Segurança
  // ─────────────────────────────────────────────────────────────────────────

  Widget _tabConta() => _ContaTab(
        profile: _profile,
        onLogout: _logout,
      );

  // ── Helpers ────────────────────────────────────────────────────────────

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppTheme.corSucesso,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppTheme.corErro,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.corCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair da conta?',
            style: TextStyle(
                color: AppTheme.corTexto,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        content: const Text(
          'Você precisará fazer login novamente para acessar o aplicativo.',
          style: TextStyle(color: AppTheme.corSubtexto, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.corSubtexto)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.corErro,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    context.read<AuthProvider>().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.corFundo,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.corPrimaria)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      body: Column(
        children: [
          _profileHeader(),
          _tabBar(),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _tabPerfil(),
                _tabSaude(),
                _tabConta(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — Editar Perfil
// ─────────────────────────────────────────────────────────────────────────────
class _EditPerfil extends StatefulWidget {
  final _UserProfile profile;
  final Future<void> Function(_UserProfile) onSaved;

  const _EditPerfil({required this.profile, required this.onSaved});

  @override
  State<_EditPerfil> createState() => _EditPerfilState();
}

class _EditPerfilState extends State<_EditPerfil> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nome;
  late TextEditingController _email;
  late TextEditingController _celular;
  late TextEditingController _endereco;
  late TextEditingController _cep;

  bool _isEditing = false;
  bool _isSaving  = false;
  bool _dirty     = false;
  bool _cepLoading = false;
  String? _cepError;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nome     = TextEditingController(text: p.nome);
    _email    = TextEditingController(text: p.email);
    _celular  = TextEditingController(text: p.celular);
    _endereco = TextEditingController(text: p.endereco);
    _cep      = TextEditingController(text: p.cep);
    for (final c in [_nome, _email, _celular, _endereco, _cep]) {
      c.addListener(() => setState(() => _dirty = true));
    }
  }

  @override
  void didUpdateWidget(covariant _EditPerfil oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) {
      final p = widget.profile;
      _nome.text     = p.nome;
      _email.text    = p.email;
      _celular.text  = p.celular;
      _endereco.text = p.endereco;
      _cep.text      = p.cep;
    }
  }

  @override
  void dispose() {
    for (final c in [_nome, _email, _celular, _endereco, _cep]) {
      c.dispose();
    }
    super.dispose();
  }

  void _cancelarEdicao() {
    final p = widget.profile;
    _nome.text     = p.nome;
    _email.text    = p.email;
    _celular.text  = p.celular;
    _endereco.text = p.endereco;
    _cep.text      = p.cep;
    setState(() {
      _isEditing = false;
      _dirty     = false;
      _cepError  = null;
    });
  }

  // ── Busca CEP via ViaCEP ───────────────────────────────────────────────

  Future<void> _buscarCep() async {
    final cep = _cep.text.trim();
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
            _endereco.text = partes.join(', ');
            _cepError = null;
            _dirty = true;
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

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final updated = _UserProfile(
      username: widget.profile.username,
      nome:     _nome.text.trim(),
      email:    _email.text.trim(),
      celular:  _celular.text.trim(),
      endereco: _endereco.text.trim(),
      cep:      _cep.text.trim(),
      peso:     widget.profile.peso,
      altura:   widget.profile.altura,
    );

    await widget.onSaved(updated);

    if (mounted) {
      setState(() {
        _isSaving  = false;
        _dirty     = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informações salvas com sucesso!'),
          backgroundColor: AppTheme.corSucesso,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Banner informativo Modo Leitura / Edição ───────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _isEditing
                    ? AppTheme.corDestaque.withOpacity(0.1)
                    : AppTheme.corPrimaria.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isEditing
                      ? AppTheme.corDestaque.withOpacity(0.3)
                      : AppTheme.corPrimaria.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_note_rounded : Icons.lock_outline_rounded,
                    color: _isEditing ? AppTheme.corDestaque : AppTheme.corPrimaria,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'Modo de edição ativo. Altere os campos desejados.'
                          : 'Informações salvas. Habilite a edição para alterar.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.corTexto,
                      ),
                    ),
                  ),
                  if (!_isEditing)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: const Text('Editar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            // ── Campo readonly: username ──────────────────────────────
            _sectionLabel('Identidade'),
            const SizedBox(height: 8),
            _readonlyField(
              icon: Icons.alternate_email_rounded,
              label: 'Nome de usuário',
              value: widget.profile.username,
              hint: 'Não é possível alterar o nome de usuário',
            ),

            const SizedBox(height: 20),
            _sectionLabel('Dados Pessoais'),
            const SizedBox(height: 8),

            // Nome
            _formField(
              controller: _nome,
              enabled: _isEditing,
              icon: Icons.badge_outlined,
              label: 'Nome completo',
              hint: 'Seu nome completo',
              maxLength: 80,
              validator: (v) {
                if (v != null && v.isNotEmpty && v.trim().length < 3) {
                  return 'Nome deve conter pelo menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // E-mail
            _formField(
              controller: _email,
              enabled: _isEditing,
              icon: Icons.email_outlined,
              label: 'E-mail',
              hint: 'seu@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final regex = RegExp(r'^[\w\-.]+@[\w\-]+\.[a-z]{2,}$');
                return regex.hasMatch(v.trim()) ? null : 'Insira um e-mail válido (ex: nome@dominio.com)';
              },
            ),
            const SizedBox(height: 12),

            // Celular
            _formField(
              controller: _celular,
              enabled: _isEditing,
              icon: Icons.phone_outlined,
              label: 'Celular',
              hint: '11999999999',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 11,
              validator: (v) {
                if (v != null && v.isNotEmpty && v.trim().length < 10) {
                  return 'Celular deve conter 10 ou 11 dígitos';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),
            _sectionLabel('Localização'),
            const SizedBox(height: 8),

            // CEP
            TextFormField(
              controller: _cep,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 8,
              onChanged: (v) {
                setState(() => _dirty = true);
                if (v.length == 8) _buscarCep();
              },
              decoration: InputDecoration(
                labelText: 'CEP',
                hintText: '00000000',
                prefixIcon: const Icon(Icons.pin_drop_outlined,
                    color: AppTheme.corSubtexto, size: 20),
                counterText: '',
                errorText: _cepError,
                suffixIcon: _cepLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.corPrimaria),
                        ),
                      )
                    : (_isEditing && _cep.text.length == 8)
                        ? IconButton(
                            tooltip: 'Buscar CEP',
                            icon: const Icon(Icons.search_rounded,
                                color: AppTheme.corPrimaria),
                            onPressed: _buscarCep,
                          )
                        : null,
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty && v.trim().length != 8) {
                  return 'CEP deve ter exatamente 8 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Endereço
            _formField(
              controller: _endereco,
              enabled: _isEditing,
              icon: Icons.home_outlined,
              label: 'Endereço',
              hint: 'Rua, número, bairro',
              maxLength: 120,
            ),

            const SizedBox(height: 28),

            // ── Botões de ação ───────────────────────────────────────
            _isSaving
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.corPrimaria))
                : !_isEditing
                    ? ElevatedButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Habilitar edição'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _cancelarEdicao,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('Cancelar'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                foregroundColor: AppTheme.corSubtexto,
                                side: BorderSide(
                                    color: AppTheme.corBorda.withOpacity(0.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _dirty ? _salvar : null,
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: const Text('Salvar alterações'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                disabledBackgroundColor:
                                    AppTheme.corPrimaria.withOpacity(0.35),
                                disabledForegroundColor: Colors.white60,
                              ),
                            ),
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Saúde
// ─────────────────────────────────────────────────────────────────────────────
class _EditSaude extends StatefulWidget {
  final _UserProfile profile;
  final Future<void> Function(_UserProfile) onSaved;

  const _EditSaude({required this.profile, required this.onSaved});

  @override
  State<_EditSaude> createState() => _EditSaudeState();
}

class _EditSaudeState extends State<_EditSaude> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _peso;
  late TextEditingController _altura;

  bool _isEditing = false;
  bool _isSaving  = false;
  bool _dirty     = false;

  @override
  void initState() {
    super.initState();
    _peso   = TextEditingController(text: widget.profile.peso);
    _altura = TextEditingController(text: widget.profile.altura);
    for (final c in [_peso, _altura]) {
      c.addListener(() => setState(() => _dirty = true));
    }
  }

  @override
  void didUpdateWidget(covariant _EditSaude oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) {
      _peso.text   = widget.profile.peso;
      _altura.text = widget.profile.altura;
    }
  }

  @override
  void dispose() {
    _peso.dispose();
    _altura.dispose();
    super.dispose();
  }

  void _cancelarEdicao() {
    _peso.text   = widget.profile.peso;
    _altura.text = widget.profile.altura;
    setState(() {
      _isEditing = false;
      _dirty     = false;
    });
  }

  double? get _imc {
    final p = double.tryParse(_peso.text.replaceAll(',', '.'));
    final a = double.tryParse(_altura.text.replaceAll(',', '.'));
    if (p == null || a == null || a <= 0) return null;
    return p / (a * a);
  }

  String _imcClassificacao(double imc) {
    if (imc < 18.5) return 'Abaixo do peso';
    if (imc < 25.0) return 'Peso normal';
    if (imc < 30.0) return 'Sobrepeso';
    if (imc < 35.0) return 'Obesidade grau I';
    if (imc < 40.0) return 'Obesidade grau II';
    return 'Obesidade grau III';
  }

  Color _imcColor(double imc) {
    if (imc < 18.5) return const Color(0xFF1565C0);
    if (imc < 25.0) return AppTheme.corSucesso;
    if (imc < 30.0) return AppTheme.corDestaque;
    return AppTheme.corErro;
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final updated = _UserProfile(
      username: widget.profile.username,
      nome:     widget.profile.nome,
      email:    widget.profile.email,
      celular:  widget.profile.celular,
      endereco: widget.profile.endereco,
      cep:      widget.profile.cep,
      peso:     _peso.text.trim(),
      altura:   _altura.text.trim(),
    );

    await widget.onSaved(updated);

    if (mounted) {
      setState(() {
        _isSaving  = false;
        _dirty     = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados de saúde salvos com sucesso!'),
          backgroundColor: AppTheme.corSucesso,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imc = _imc;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Info banner ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _isEditing
                    ? AppTheme.corDestaque.withOpacity(0.1)
                    : AppTheme.corPrimaria.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isEditing
                        ? AppTheme.corDestaque.withOpacity(0.3)
                        : AppTheme.corPrimaria.withOpacity(0.25),
                    width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_note_rounded : Icons.info_outline_rounded,
                    color: _isEditing ? AppTheme.corDestaque : AppTheme.corPrimaria,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'Modo de edição ativo. Altere peso e altura.'
                          : 'Seus dados de saúde são usados pela assistente nutricional para personalizar suas recomendações.',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.corSubtexto,
                          height: 1.4),
                    ),
                  ),
                  if (!_isEditing)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: const Text('Editar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            _sectionLabel('Medidas'),
            const SizedBox(height: 8),

            // Peso + Altura lado a lado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _formField(
                    controller: _peso,
                    enabled: _isEditing,
                    icon: Icons.monitor_weight_outlined,
                    label: 'Peso (kg)',
                    hint: 'Ex: 70,5',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final val = double.tryParse(v.replaceAll(',', '.'));
                      if (val == null || val <= 0 || val > 500) {
                        return 'Peso inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _formField(
                    controller: _altura,
                    enabled: _isEditing,
                    icon: Icons.height_rounded,
                    label: 'Altura (m)',
                    hint: 'Ex: 1,70',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final val = double.tryParse(v.replaceAll(',', '.'));
                      if (val == null || val <= 0 || val > 3) {
                        return 'Altura inválida';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            // ── Card IMC ────────────────────────────────────────────────
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: imc != null
                  ? _imcCard(imc)
                  : Container(
                      key: const ValueKey('empty'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.corCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.corBorda.withOpacity(0.25),
                            width: 0.6),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.calculate_outlined,
                              color: AppTheme.corSubtexto, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Preencha peso e altura para calcular o IMC',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.corSubtexto),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 28),

            // ── Botões de ação ───────────────────────────────────────
            _isSaving
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.corPrimaria))
                : !_isEditing
                    ? ElevatedButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Habilitar edição'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _cancelarEdicao,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('Cancelar'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                foregroundColor: AppTheme.corSubtexto,
                                side: BorderSide(
                                    color: AppTheme.corBorda.withOpacity(0.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _dirty ? _salvar : null,
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: const Text('Salvar dados de saúde'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                disabledBackgroundColor:
                                    AppTheme.corPrimaria.withOpacity(0.35),
                                disabledForegroundColor: Colors.white60,
                              ),
                            ),
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  Widget _imcCard(double imc) {
    final color = _imcColor(imc);
    final label = _imcClassificacao(imc);
    // Progress bar: faixa 15–40
    final progress = ((imc - 15) / 25).clamp(0.0, 1.0);

    return Container(
      key: const ValueKey('imc'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calculate_outlined, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Índice de Massa Corporal',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.corSubtexto,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      imc.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: color.withOpacity(0.4), width: 0.7),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Barra de progresso IMC
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.corBorda.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: 8),

          // Legenda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('15', style: TextStyle(fontSize: 10, color: AppTheme.corSubtexto)),
              Text('18.5', style: TextStyle(fontSize: 10, color: AppTheme.corSubtexto)),
              Text('25', style: TextStyle(fontSize: 10, color: AppTheme.corSubtexto)),
              Text('30', style: TextStyle(fontSize: 10, color: AppTheme.corSubtexto)),
              Text('40', style: TextStyle(fontSize: 10, color: AppTheme.corSubtexto)),
            ],
          ),
          const SizedBox(height: 16),
          _dashboardNutricional(),
        ],
      ),
    );
  }

  Widget _dashboardNutricional() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.corCard.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.corBorda.withOpacity(0.25), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: AppTheme.corPrimaria, size: 18),
              SizedBox(width: 8),
              Text(
                'Metas Nutricionais Estimadas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.corTexto),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _macroBar('Calorias', '1.850 / 2.000 kcal', 0.82, AppTheme.corPrimaria),
          const SizedBox(height: 8),
          _macroBar('Proteínas', '110g / 130g', 0.85, AppTheme.corDestaque),
          const SizedBox(height: 8),
          _macroBar('Carboidratos', '190g / 220g', 0.75, AppTheme.corSecundaria),
          const SizedBox(height: 8),
          _macroBar('Gorduras', '52g / 65g', 0.68, Colors.brown),
        ],
      ),
    );
  }

  Widget _macroBar(String label, String value, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.corTexto)),
            Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppTheme.corBorda.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Conta / Segurança
// ─────────────────────────────────────────────────────────────────────────────
class _ContaTab extends StatefulWidget {
  final _UserProfile profile;
  final VoidCallback onLogout;

  const _ContaTab({required this.profile, required this.onLogout});

  @override
  State<_ContaTab> createState() => _ContaTabState();
}

class _ContaTabState extends State<_ContaTab> {
  // ── Alterar senha ──────────────────────────────────────────────────────

  void _abrirAlterarSenha() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlterarSenhaSheet(username: widget.profile.username),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Segurança ──────────────────────────────────────────────
          _sectionLabel('Segurança'),
          const SizedBox(height: 8),

          _actionTile(
            icon: Icons.lock_reset_rounded,
            title: 'Alterar senha',
            subtitle: 'Atualize sua senha de acesso',
            color: AppTheme.corPrimaria,
            onTap: _abrirAlterarSenha,
          ),
          const SizedBox(height: 8),
          _actionTile(
            icon: Icons.alternate_email_rounded,
            title: 'Nome de usuário',
            subtitle: widget.profile.username,
            color: AppTheme.corSecundaria,
            onTap: null,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.corBorda.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Fixo',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.corSubtexto,
                      fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 24),

          // ── Preferências ───────────────────────────────────────────
          _sectionLabel('Preferências'),
          const SizedBox(height: 8),

          _actionTile(
            icon: Icons.notifications_outlined,
            title: 'Notificações',
            subtitle: 'Alertas de status dos pedidos',
            color: AppTheme.corDestaque,
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // ── Sobre ──────────────────────────────────────────────────
          _sectionLabel('Sobre'),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.corCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.corBorda.withOpacity(0.25), width: 0.6),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Image.asset(
                        'assets/images/logo_icone.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comida & Afeto',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.corTexto)),
                          Text('Versão 1.0.0',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.corSubtexto)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                    height: 1, color: AppTheme.corBorda.withOpacity(0.25)),
                const SizedBox(height: 12),
                const Text(
                  'Sistema de pedido de marmitas congeladas com assistente nutricional de IA. Desenvolvido como Trabalho de Conclusão de Curso.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.corSubtexto,
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Logout ─────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded,
                color: AppTheme.corErro, size: 18),
            label: const Text(
              'Sair da conta',
              style: TextStyle(
                  color: AppTheme.corErro, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.corErro.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.corBorda.withOpacity(0.2), width: 0.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.corTexto)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.corSubtexto)),
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.corSubtexto, size: 20)
                : null),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet — Alterar Senha
// ─────────────────────────────────────────────────────────────────────────────
class _AlterarSenhaSheet extends StatefulWidget {
  final String username;

  const _AlterarSenhaSheet({required this.username});

  @override
  State<_AlterarSenhaSheet> createState() => _AlterarSenhaSheetState();
}

class _AlterarSenhaSheetState extends State<_AlterarSenhaSheet> {
  final _formKey       = GlobalKey<FormState>();
  final _atualCtrl     = TextEditingController();
  final _novaCtrl      = TextEditingController();
  final _confirmaCtrl  = TextEditingController();

  bool _obscureAtual    = true;
  bool _obscureNova     = true;
  bool _obscureConfirma = true;
  bool _isSaving        = false;
  String? _errorMsg;
  bool _success         = false;

  @override
  void dispose() {
    _atualCtrl.dispose();
    _novaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _errorMsg = null;
    });

    final prefs = await SharedPreferences.getInstance();
    String username = widget.username.trim();
    if (username.isEmpty) {
      username = prefs.getString('username') ?? '';
    }

    if (username.isEmpty) {
      setState(() {
        _errorMsg = 'Nome de usuário não identificado.';
        _isSaving = false;
      });
      return;
    }

    // 1. Verifica senha atual via /apiUser/login
    try {
      final loginResp = await http.post(
        Uri.parse('http://localhost:8080/apiUser/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'senha': _atualCtrl.text,
        }),
      );

      if (loginResp.statusCode != 200 ||
          loginResp.body.trim() == 'false') {
        setState(() {
          _errorMsg = 'Senha atual incorreta.';
          _isSaving = false;
        });
        return;
      }

      // 2. Atualiza a senha no servidor via PUT /apiUser/alterar-senha
      final updateResp = await http.put(
        Uri.parse('http://localhost:8080/apiUser/alterar-senha'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'novaSenha': _novaCtrl.text,
        }),
      );

      if (updateResp.statusCode != 200 ||
          updateResp.body.trim() == 'false') {
        setState(() {
          _errorMsg = 'Erro ao atualizar a senha no servidor.';
          _isSaving = false;
        });
        return;
      }

      // 3. Atualiza localmente em SharedPreferences se salva anteriormente
      if (prefs.containsKey('password')) {
        await prefs.setString('password', _novaCtrl.text);
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _success  = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Erro de conexão: $e';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: _success ? _successView() : _formView(),
    );
  }

  Widget _successView() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.corSucesso.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.corSucesso.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.check_rounded,
                color: AppTheme.corSucesso, size: 32),
          ),
          const SizedBox(height: 14),
          const Text('Senha atualizada!',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.corTexto)),
          const SizedBox(height: 6),
          const Text(
            'Sua senha foi alterada com sucesso.',
            style:
                TextStyle(fontSize: 13, color: AppTheme.corSubtexto),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46)),
            child: const Text('Fechar'),
          ),
        ],
      );

  Widget _formView() => Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _handle(),
            const SizedBox(height: 12),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.corPrimaria.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: AppTheme.corPrimaria, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Alterar senha',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.corTexto)),
              ],
            ),

            const SizedBox(height: 20),

            _passField(
              controller: _atualCtrl,
              label: 'Senha atual',
              obscure: _obscureAtual,
              onToggle: () =>
                  setState(() => _obscureAtual = !_obscureAtual),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Informe a senha atual' : null,
            ),
            const SizedBox(height: 12),
            _passField(
              controller: _novaCtrl,
              label: 'Nova senha',
              obscure: _obscureNova,
              onToggle: () =>
                  setState(() => _obscureNova = !_obscureNova),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a nova senha';
                if (v.length < 4) return 'Mínimo de 4 caracteres';
                if (v == _atualCtrl.text) {
                  return 'A nova senha deve ser diferente da atual';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _passField(
              controller: _confirmaCtrl,
              label: 'Confirmar nova senha',
              obscure: _obscureConfirma,
              onToggle: () =>
                  setState(() => _obscureConfirma = !_obscureConfirma),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirme a nova senha';
                if (v != _novaCtrl.text) return 'As senhas não coincidem';
                return null;
              },
            ),

            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.corErro.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.corErro.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.corErro, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMsg!,
                          style: const TextStyle(
                              color: AppTheme.corErro, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            _isSaving
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.corPrimaria))
                : ElevatedButton.icon(
                    onPressed: _salvar,
                    icon: const Icon(Icons.save_rounded, size: 17),
                    label: const Text('Salvar senha'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48)),
                  ),
          ],
        ),
      );

  Widget _handle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.corBorda.withOpacity(0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _passField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline,
              color: AppTheme.corSubtexto, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.corSubtexto,
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ),
        validator: validator,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de UI compartilhados (funções de nível de arquivo)
// ─────────────────────────────────────────────────────────────────────────────
Widget _sectionLabel(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.corSubtexto,
          letterSpacing: 1.2,
        ),
      ),
    );

Widget _formField({
  required TextEditingController controller,
  required IconData icon,
  required String label,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
  String? Function(String?)? validator,
  bool enabled = true,
}) =>
    TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon:
            Icon(icon, color: AppTheme.corSubtexto, size: 20),
      ),
      validator: validator,
    );

Widget _readonlyField({
  required IconData icon,
  required String label,
  required String value,
  String? hint,
}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.corBorda.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppTheme.corBorda.withOpacity(0.3), width: 0.6),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.corSubtexto, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.corSubtexto)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? '—' : value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.corTexto)),
                if (hint != null)
                  Text(hint,
                      style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.corSubtexto.withOpacity(0.6),
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded,
              color: AppTheme.corSubtexto, size: 16),
        ],
      ),
    );