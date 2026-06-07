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
        final Iterable data = jsonDecode(response.body);
        setState(() {
          _chats = data.map((m) => ChatModel.fromJson(m)).toList();
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

  void _abrirChat(ChatModel chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppTheme.corFundo,
          appBar: AppBar(
            title: Text(
              chat.title as String,
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

  Widget _buildChatTile(ChatModel chat, int index) {
    final colors = [
      AppTheme.corPrimaria,
      AppTheme.corDestaque,
      AppTheme.corSecundaria,
    ];
    final accentColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: BorderSide(color: AppTheme.corBorda.withOpacity(0.25), width: 0.5),
          right: BorderSide(color: AppTheme.corBorda.withOpacity(0.25), width: 0.5),
          bottom: BorderSide(color: AppTheme.corBorda.withOpacity(0.25), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.corPrimaria.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.chat_bubble_outline_rounded,
              color: accentColor, size: 20),
        ),
        title: Text(
          chat.title as String,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.corTexto,
          ),
        ),
        subtitle: Text(
          'Chat #${chat.id}',
          style: const TextStyle(
              fontSize: 12, color: AppTheme.corSubtexto),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.corSubtexto,
          size: 22,
        ),
        onTap: () => _abrirChat(chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ────────────────────────────────────────────────
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
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppTheme.corSecundaria),
                  tooltip: 'Atualizar',
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _pedirChatList();
                  },
                ),
              ],
            ),
          ),

          Divider(
              height: 1,
              color: AppTheme.corBorda.withOpacity(0.3),
              indent: 20,
              endIndent: 20),

          const SizedBox(height: 8),

          // ── Conteúdo ─────────────────────────────────────────────────
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
                                size: 48,
                                color: AppTheme.corSubtexto),
                            const SizedBox(height: 12),
                            Text(
                              _errorMsg!,
                              style: const TextStyle(
                                  color: AppTheme.corSubtexto,
                                  fontSize: 14),
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
                                    color: AppTheme.corPrimaria
                                        .withOpacity(0.3)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Nenhum chat encontrado.',
                                  style: TextStyle(
                                      color: AppTheme.corSubtexto,
                                      fontSize: 14),
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
