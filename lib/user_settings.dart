import 'package:flutter/material.dart';
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/auth_provider.dart';
import 'package:prototipo1/configuracoes.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettings extends StatefulWidget {
  const UserSettings({super.key});

  @override
  State<UserSettings> createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  String _username = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.corPrimaria))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Perfil ─────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.corPrimaria,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 44),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _username.isEmpty ? 'Usuário' : _username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.corTexto,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Membro Comida & Afeto',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.corSubtexto),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Seção Conta ─────────────────────────────────────
                  _sectionLabel('Conta'),
                  const SizedBox(height: 8),
                  _settingsTile(
                    icon: Icons.edit_note_rounded,
                    label: 'Editar perfil e saúde',
                    value: 'Configurações',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Configuracoes(),
                        ),
                      );
                    },
                  ),
                  _settingsTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Alterar senha',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const Configuracoes(initialIndex: 2),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Seção Preferências ─────────────────────────────
                  _sectionLabel('Preferências'),
                  const SizedBox(height: 8),
                  _settingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notificações',
                    onTap: () {},
                  ),
                  _settingsTile(
                    icon: Icons.info_outline_rounded,
                    label: 'Sobre o app',
                    value: 'v1.0.0',
                    onTap: () {},
                  ),

                  const SizedBox(height: 32),

                  // ── Botão de logout ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        context.read<AuthProvider>().logout();
                        final prefs =
                            await SharedPreferences.getInstance();
                        await prefs.remove('username');
                        await prefs.remove('password');
                      },
                      icon: const Icon(Icons.logout_rounded,
                          color: AppTheme.corErro, size: 18),
                      label: const Text(
                        'Sair da conta',
                        style: TextStyle(
                            color: AppTheme.corErro,
                            fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppTheme.corErro.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.corSubtexto,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    String? value,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppTheme.corBorda.withOpacity(0.25), width: 0.5),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.corPrimaria.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.corPrimaria, size: 18),
        ),
        title: Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.corTexto),
        ),
        trailing: value != null
            ? Text(value,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.corSubtexto))
            : onTap != null
                ? const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.corSubtexto, size: 20)
                : null,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
      ),
    );
  }
}
