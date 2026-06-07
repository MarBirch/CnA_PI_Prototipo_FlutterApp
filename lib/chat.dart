import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chat extends StatefulWidget {
  final int chatId;
  const Chat(this.chatId, {super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final _httpClient = http.Client();
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pedirChatMessages();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pedirChatMessages() async {
    final url =
        Uri.parse('http://localhost:8080/apiOllama/chat/messages');
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'prompt': 'empty',
          'chatId': widget.chatId,
        }),
      );
      if (response.statusCode == 200) {
        final Iterable data = jsonDecode(response.body);
        setState(() {
          _messages = data.map((m) => ChatMessage.fromJson(m)).toList();
          for (final msg in _messages) {
            msg.isUser = msg.role == 'USER' ? true : false;
          }
        });
      }
    } catch (_) {}
  }

  Future<String?> _enviarPrompt(String prompt) async {
    final url = Uri.parse('http://localhost:8080/apiOllama/prompt');
    try {
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt, 'chatId': widget.chatId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() => _messages.add(
            ChatMessage(data['content'] as String, 'ASSISTANT', false)));
        return null;
      }
      return 'Erro: ${response.statusCode}';
    } catch (e) {
      return e.toString();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        // constraints: BoxConstraints(
        //   maxWidth: MediaQuery.of(context).size.width * 0.78,
        // ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.corPrimaria : AppTheme.corCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 14),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: AppTheme.corBorda.withOpacity(0.35), width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isUser
            ? Text(
                msg.message as String,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.4),
              )
            : MarkdownBlock(
                data: msg.message as String,
                selectable: true,
              ),
      ),
    );
  }

  Future<void> _onEnviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final prompt = _promptController.text.trim();
    _promptController.clear();

    setState(() {
      _isLoading = true;
      _errorText = null;
      _messages.add(ChatMessage(prompt, 'USER', true));
    });
    _scrollToBottom();

    final error = await _enviarPrompt(prompt);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorText = error;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      body: Column(
        children: [
          // ── Lista de mensagens ─────────────────────────────────────────
          Expanded(
            child: _messages.isEmpty && !_isLoading
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
                          'Nenhuma mensagem ainda.\nEnvie um prompt para começar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.corSubtexto, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildMessage(_messages[i]),
                  ),
          ),

          // ── Indicador de loading ───────────────────────────────────────
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.corCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.corBorda.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.corPrimaria,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Gerando resposta...',
                          style: TextStyle(
                              color: AppTheme.corSubtexto, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Campo de entrada ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: AppTheme.corCard,
              border: Border(
                top: BorderSide(
                    color: AppTheme.corBorda.withOpacity(0.3), width: 0.6),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _promptController,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Digite um prompt...',
                        errorText: _errorText,
                        filled: true,
                        fillColor: AppTheme.corFundo,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppTheme.corBorda.withOpacity(0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppTheme.corBorda.withOpacity(0.35)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.corPrimaria, width: 1.4),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '' : null,
                      onFieldSubmitted: (_) =>
                          _isLoading ? null : _onEnviar(),
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTheme.corPrimaria),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppTheme.corPrimaria,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: _onEnviar,
                            icon: const Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                            tooltip: 'Enviar',
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
