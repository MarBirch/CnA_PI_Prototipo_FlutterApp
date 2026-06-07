import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/cardapio.dart';
// ── Modelos locais ─────────────────────────────────────────────────────────

class IngredienteModel {
  final int id;
  final String nome;
  final double valorPorGramas;
  final int posicao;

  IngredienteModel({
    required this.id,
    required this.nome,
    required this.valorPorGramas,
    required this.posicao,
  });

  factory IngredienteModel.fromJson(Map<String, dynamic> j) => IngredienteModel(
        id: j['id'] as int,
        nome: j['nome'] as String,
        valorPorGramas: (j['valorPorGramas'] as num).toDouble(),
        posicao: j['posicao'] as int,
      );
}

class CardapioModel {
  final int id;
  final String nome;
  final bool aberto;
  final List<IngredienteModel> ingredientes;

  CardapioModel({
    required this.id,
    required this.nome,
    required this.aberto,
    required this.ingredientes,
  });

  factory CardapioModel.fromJson(Map<String, dynamic> j) => CardapioModel(
        id: j['id'] as int,
        nome: j['nome'] as String,
        aberto: (j['aberto'] as bool?) ?? true,
        ingredientes: ((j['ingredientes'] as List?) ?? [])
            .map((i) => IngredienteModel.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class MarmiteriaModel {
  final int id;
  final String nome;
  final String? telefone;
  final String? cep;
  final bool status;

  MarmiteriaModel({
    required this.id,
    required this.nome,
    this.telefone,
    this.cep,
    required this.status,
  });

  factory MarmiteriaModel.fromJson(Map<String, dynamic> j) => MarmiteriaModel(
        id: j['id'] as int,
        nome: j['nome'] as String,
        telefone: j['telefone'] as String?,
        cep: j['cep'] as String?,
        status: (j['status'] as bool?) ?? false,
      );
}

// ── Página ─────────────────────────────────────────────────────────────────

class Marmiteria extends StatefulWidget {
  final MarmiteriaModel marmiteria;
  const Marmiteria({super.key, required this.marmiteria});

  @override
  State<Marmiteria> createState() => _MarmiteriaState();
}

class _MarmiteriaState extends State<Marmiteria> {
  final _http = http.Client();

  List<CardapioModel> _cardapios = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _carregarCardapios();
  }

  Future<void> _carregarCardapios() async {
    final url = Uri.parse(
        'http://localhost:8080/apiCardapio/todos?marmiteriaId=${widget.marmiteria.id}');
    try {
      final response = await _http.get(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body) as List;
        setState(() {
          _cardapios = data
              .map((e) => CardapioModel.fromJson(e as Map<String, dynamic>))
              .toList();
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

  void _abrirCardapio(CardapioModel cardapio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Cardapio(
          cardapio: cardapio,
          marmiteria: widget.marmiteria,
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _header() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.corPrimaria,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone da loja
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.store_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            widget.marmiteria.nome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          // Status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.marmiteria.status
                      ? AppTheme.corSucesso.withOpacity(0.25)
                      : Colors.red.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.marmiteria.status
                        ? AppTheme.corSucesso
                        : Colors.red,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.marmiteria.status
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: widget.marmiteria.status
                          ? AppTheme.corSucesso
                          : Colors.red,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.marmiteria.status ? 'Aberto' : 'Fechado',
                      style: TextStyle(
                        color: widget.marmiteria.status
                            ? AppTheme.corSucesso
                            : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.marmiteria.telefone != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.phone_outlined, color: Colors.white70, size: 13),
                const SizedBox(width: 4),
                Text(
                  widget.marmiteria.telefone!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardapioCard(CardapioModel cardapio, int index) {
    final colors = [
      AppTheme.corPrimaria,
      AppTheme.corDestaque,
      AppTheme.corSecundaria,
    ];
    final accent = colors[index % colors.length];
    final totalIngredientes = cardapio.ingredientes.length;

    return GestureDetector(
      onTap: cardapio.aberto ? () => _abrirCardapio(cardapio) : null,
      child: Opacity(
        opacity: cardapio.aberto ? 1.0 : 0.55,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.corCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.corBorda.withOpacity(0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Barra de acento esquerda
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: accent),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Ícone
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.menu_book_rounded,
                                color: accent, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cardapio.nome,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.corTexto,
                              ),
                            ),
                          ),
                          // Badge aberto/fechado
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cardapio.aberto
                                  ? AppTheme.corSucesso.withOpacity(0.1)
                                  : AppTheme.corErro.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cardapio.aberto
                                    ? AppTheme.corSucesso.withOpacity(0.4)
                                    : AppTheme.corErro.withOpacity(0.4),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              cardapio.aberto ? 'Disponível' : 'Indisponível',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cardapio.aberto
                                    ? AppTheme.corSucesso
                                    : AppTheme.corErro,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (totalIngredientes > 0) ...[
                        const SizedBox(height: 10),
                        Divider(
                            height: 1,
                            color: AppTheme.corBorda.withOpacity(0.2)),
                        const SizedBox(height: 10),
                        // Preview dos ingredientes
                        Row(
                          children: [
                            const Icon(Icons.restaurant_menu_rounded,
                                size: 13, color: AppTheme.corSubtexto),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                cardapio.ingredientes
                                    .take(4)
                                    .map((i) => i.nome)
                                    .join(', ') +
                                    (totalIngredientes > 4
                                        ? ' +${totalIngredientes - 4} mais'
                                        : ''),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.corSubtexto,
                                    height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.list_alt_rounded,
                                  size: 13, color: AppTheme.corSubtexto),
                              const SizedBox(width: 4),
                              Text(
                                '$totalIngredientes ingrediente${totalIngredientes != 1 ? 's' : ''}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.corSubtexto),
                              ),
                            ],
                          ),
                          if (cardapio.aberto)
                            Row(
                              children: [
                                Text(
                                  'Montar pedido',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 11, color: accent),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      appBar: AppBar(
        backgroundColor: AppTheme.corPrimaria,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Marmiteria',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _carregarCardapios();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _header(),
          const SizedBox(height: 4),
          // Título da seção
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                const Text(
                  'Cardápios',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.corTexto,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.corPrimaria.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_cardapios.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.corPrimaria,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Lista
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
                            Text(_errorMsg!,
                                style: const TextStyle(
                                    color: AppTheme.corSubtexto,
                                    fontSize: 14)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _errorMsg = null;
                                });
                                _carregarCardapios();
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : _cardapios.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.menu_book_rounded,
                                    size: 52,
                                    color: AppTheme.corPrimaria
                                        .withOpacity(0.3)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Nenhum cardápio disponível.',
                                  style: TextStyle(
                                      color: AppTheme.corSubtexto,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.only(top: 4, bottom: 20),
                            itemCount: _cardapios.length,
                            itemBuilder: (_, i) =>
                                _cardapioCard(_cardapios[i], i),
                          ),
          ),
        ],
      ),
    );
  }
}