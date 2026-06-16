import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/auth_provider.dart';
import 'package:prototipo1/cadastro.dart';
import 'package:prototipo1/carrinho.dart';
import 'package:prototipo1/chalist.dart';
import 'package:prototipo1/configuracoes.dart';
import 'package:prototipo1/home.dart';
import 'package:prototipo1/marmiteria.dart';
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
  String _username = '';

  static final List<Widget> _screens = [
    const Home(),
    const Pedido(),
    const Chatlist(),
    const Configuracoes(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded, label: 'Início'),
    _NavItem(icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded, label: 'Pedidos'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded, label: 'Chats'),
    _NavItem(icon: Icons.manage_accounts_outlined,
        activeIcon: Icons.manage_accounts_rounded, label: 'Conta'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username') ?? '');
  }

  Future<void> _logout() async {
    context.read<AuthProvider>().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      appBar: AppBar(
        toolbarHeight: 52,
        backgroundColor: AppTheme.corFundo,
        title: Text(
          'Comida & Afeto',
          style: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: AppTheme.corDestaque,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded,
                color: AppTheme.corPrimaria, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1,
              color: AppTheme.corBorda.withOpacity(0.3)),
        ),
      ),

      body: _screens[_selectedIndex],

      // ── Barra de navegação inferior ─────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.corCard,
          border: Border(
            top: BorderSide(
                color: AppTheme.corBorda.withOpacity(0.3), width: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.corPrimaria,
          unselectedItemColor: AppTheme.corSubtexto,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: _navItems
              .map((item) => BottomNavigationBarItem(
                    icon: Icon(item.icon, size: 24),
                    activeIcon: Icon(item.activeIcon, size: 24),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),

      // ── Drawer lateral ──────────────────────────────────────────────
      drawer: Drawer(
        backgroundColor: AppTheme.corSidebar,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              decoration: const BoxDecoration(
                color: AppTheme.corPrimaria,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.lunch_dining_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Comida & Afeto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_username.isNotEmpty)
                    Text(
                      _username,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Itens de navegação
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                children: [
                  _drawerItem(
                    icon: Icons.home_outlined,
                    label: 'Início',
                    index: 0,
                  ),
                  _drawerItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Pedidos',
                    index: 1,
                  ),
                  _drawerItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chats',
                    index: 2,
                  ),
                  _drawerItem(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Conta',
                    index: 3,
                  ),
                  const SizedBox(height: 8),
                  Divider(
                      color: AppTheme.corBorda.withOpacity(0.3)),
                  const SizedBox(height: 4),

                  // Logout
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.corErro.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: AppTheme.corErro, size: 18),
                    ),
                    title: const Text(
                      'Sair',
                      style: TextStyle(
                          color: AppTheme.corErro,
                          fontWeight: FontWeight.w500),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _logout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.corPrimaria.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(
                color: AppTheme.corPrimaria.withOpacity(0.25), width: 0.5)
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.corPrimaria
                : AppTheme.corPrimaria.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: isSelected ? Colors.white : AppTheme.corPrimaria,
              size: 18),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.corPrimaria : AppTheme.corTexto,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label});
}
