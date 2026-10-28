import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/chat.dart';
import 'package:prototipo1/chat_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chatlist extends StatefulWidget {
  const Chatlist({super.key});

  @override
  State<Chatlist> createState() => _ChatlistState();
}

class _ChatlistState extends State<Chatlist> {
  final _httpClient = http.Client();
  final _scrollController = ScrollController();

  List<ChatModel> _chats = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _pedirChatList();
  }

  // ── Carrega lista de chats do usuário ────────────────────────────────────

  Future<void> _pedirChatList() async {
    final url = Uri.parse('http://localhost:8080/apiOllama/chatlist');
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': 'empty'}),
      );
      if (response.statusCode == 200) {
        // DEBUG: mostra o JSON bruto para diagnóstico
        debugPrint('[Chatlist] JSON bruto da API: ${response.body}');
        final Iterable data = jsonDecode(response.body);
        final chats = data.map((m) {
          debugPrint('[Chatlist] item: $m');
          return ChatModel.fromJson(m as Map<String, dynamic>);
        }).toList();
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg = 'Erro ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Cria novo chat com o primeiro prompt ─────────────────────────────────

  Future<void> _criarNovoChat() async {
    final promptController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.corCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.corPrimaria.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_comment_rounded,
                  color: AppTheme.corPrimaria, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Novo Chat',
              style: TextStyle(
                color: AppTheme.corTexto,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Envie a primeira mensagem para iniciar uma nova conversa com a assistente nutricional.',
              style: TextStyle(color: AppTheme.corSubtexto, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: promptController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ex: Quais são os benefícios da aveia?',
                hintStyle: TextStyle(
                    color: AppTheme.corSubtexto.withOpacity(0.6), fontSize: 13),
                filled: true,
                fillColor: AppTheme.corFundo,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: AppTheme.corBorda.withOpacity(0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: AppTheme.corBorda.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppTheme.corPrimaria, width: 1.4),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.corSubtexto)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: 15),
            label: const Text('Iniciar'),
          ),
        ],
      ),
    );

    promptController.dispose();

    if (confirmed != true) return;

    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Digite uma mensagem para iniciar o chat.'),
          backgroundColor: AppTheme.corErro,
        ));
      }
      return;
    }

    // Mostra loading
    if (mounted) setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';

      final url = Uri.parse('http://localhost:8080/apiOllama/chat');
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'prompt': prompt,
          'chatId': null,
        }),
      );

      if (response.statusCode == 200) {
        // Recarrega lista para pegar o novo chat
        await _pedirChatList();

        // Abre o chat mais recente (último da lista)
        if (mounted && _chats.isNotEmpty) {
          final novoChat = _chats.last;
          _abrirChat(novoChat);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao criar chat: ${response.statusCode}'),
            backgroundColor: AppTheme.corErro,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: AppTheme.corErro,
        ));
      }
    }
  }

  // ── Abre chat existente ──────────────────────────────────────────────────

  void _abrirChat(ChatModel chat) {
    final titulo = chat.title as String;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppTheme.corFundo,
          appBar: AppBar(
            title: Text(
              titulo,
              style: const TextStyle(
                color: AppTheme.corDestaque,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppTheme.corFundo,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.corPrimaria, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: AppTheme.corBorda.withOpacity(0.3),
              ),
            ),
          ),
          body: Chat(chat.id as int),
        ),
      ),
    );
  }

  // ── Card de cada chat ────────────────────────────────────────────────────

  Widget _buildChatTile(ChatModel chat, int index) {
    final colors = [
      AppTheme.corPrimaria,
      AppTheme.corDestaque,
      AppTheme.corSecundaria,
    ];
    final accentColor = colors[index % colors.length];
    final titulo = chat.title as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.corBorda.withOpacity(0.25),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.corPrimaria.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _abrirChat(chat),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    color: accentColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Ícone
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.chat_bubble_outline_rounded,
                                color: accentColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          // Título + subtítulo
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titulo,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Assistente Nutri',
                                  style: TextStyle(
                                      fontSize: 11.5, color: Color(0xFF8D6E63)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF8D6E63),
                            size: 20,
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
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chats',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.corTexto,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_chats.length} conversa${_chats.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.corSubtexto),
                      ),
                    ],
                  ),
                ),
                // Botão atualizar
                SizedBox(
                  width: 34,
                  height: 34,
                  child: IconButton.outlined(
                    padding: EdgeInsets.zero,
                    iconSize: 17,
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppTheme.corSecundaria),
                    tooltip: 'Atualizar',
                    style: IconButton.styleFrom(
                      side: BorderSide(
                          color: AppTheme.corSecundaria.withOpacity(0.4),
                          width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _pedirChatList();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Botão novo chat
                ElevatedButton.icon(
                  onPressed: _criarNovoChat,
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('Novo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          Divider(
              height: 1,
              color: AppTheme.corBorda.withOpacity(0.3),
              indent: 20,
              endIndent: 20),

          // ── Disclaimer da IA ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.corPrimaria.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.corPrimaria.withOpacity(0.2), width: 0.7),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: AppTheme.corPrimaria),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'A Nutri é uma IA e pode cometer erros. '
                    'Consulte sempre um nutricionista qualificado.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.corPrimaria,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Conteúdo ───────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.corPrimaria),
                  )
                : _errorMsg != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                size: 48, color: AppTheme.corSubtexto),
                            const SizedBox(height: 12),
                            Text(
                              _errorMsg!,
                              style: const TextStyle(
                                  color: AppTheme.corSubtexto, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _errorMsg = null;
                                });
                                _pedirChatList();
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : _chats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded,
                                    size: 52,
                                    color:
                                        AppTheme.corPrimaria.withOpacity(0.3)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Nenhuma conversa ainda.',
                                  style: TextStyle(
                                      color: AppTheme.corSubtexto,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _criarNovoChat,
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Iniciar primeiro chat'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _chats.length,
                            itemBuilder: (_, i) =>
                                _buildChatTile(_chats[i], i),
                          ),
          ),
        ],
      ),
    );
  }
}