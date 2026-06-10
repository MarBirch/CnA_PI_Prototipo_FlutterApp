import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/marmiteria.dart';
import 'package:prototipo1/cardapio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Página ─────────────────────────────────────────────────────────────────

class Carrinho extends StatefulWidget {
  final List<ItemCarrinho> itens;
  final CardapioModel cardapio;
  final MarmiteriaModel marmiteria;

  const Carrinho({
    super.key,
    required this.itens,
    required this.cardapio,
    required this.marmiteria,
  });

  @override
  State<Carrinho> createState() => _CarrinhoState();
}

class _CarrinhoState extends State<Carrinho> {
  final _http = http.Client();

  late List<ItemCarrinho> _itens;
  bool _isLoading = false;
  bool _pedidoFeito = false;
  String? _errorMsg;
  String _nomeCliente = '';

  @override
  void initState() {
    super.initState();
    // cópia mutável para poder remover itens
    _itens = List.from(widget.itens);
    _carregarNome();
  }

  Future<void> _carregarNome() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _nomeCliente = prefs.getString('username') ?? '');
  }

  double get _total =>
      _itens.fold(0.0, (sum, item) => sum + item.subtotal);

  double get _totalGramas =>
      _itens.fold(0.0, (sum, item) => sum + item.gramas);

  void _removerItem(int index) {
    setState(() => _itens.removeAt(index));
  }

  Future<void> _confirmarPedido() async {
    if (_itens.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final url = Uri.parse('http://localhost:8080/apiPedido/inserir');
    try {
      final body = {
        'username': _nomeCliente,
        'cardapioId': widget.cardapio.id,
        'ingredientes': _itens
            .map((item) => {
                  'nome': item.ingrediente.nome,
                  'valorPorGramas': item.ingrediente.valorPorGramas,
                  'gramas': item.gramas,
                  'posicao': item.ingrediente.posicao,
                })
            .toList(),
      };

      final response = await _http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (mounted) {
        if (response.statusCode == 201) {
          setState(() {
            _pedidoFeito = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMsg =
                'Erro ao enviar pedido (${response.statusCode}). Tente novamente.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Erro de conexão: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _itemCard(ItemCarrinho item, int index) {
    final colors = [
      AppTheme.corPrimaria,
      AppTheme.corDestaque,
      AppTheme.corSecundaria,
    ];
    final accent = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.corBorda.withOpacity(0.2), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.corPrimaria.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  // Ícone
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.eco_outlined, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.ingrediente.nome,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.corTexto,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.gramas.toStringAsFixed(0)}g  •  R\$ ${item.ingrediente.valorPorGramas.toStringAsFixed(2)}/g',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.corSubtexto),
                        ),
                      ],
                    ),
                  ),
                  // Subtotal
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R\$ ${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.corDestaque,
                        ),
                      ),
                      // Botão remover
                      GestureDetector(
                        onTap: () => _removerItem(index),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Remover',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.corErro,
                                fontWeight: FontWeight.w500),
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
      ),
    );
  }

  Widget _resumoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.corBorda.withOpacity(0.3), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: AppTheme.corPrimaria.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMO DO PEDIDO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.corSubtexto,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _linhaResumo(
            Icons.store_rounded,
            'Marmiteria',
            widget.marmiteria.nome,
          ),
          const SizedBox(height: 6),
          _linhaResumo(
            Icons.menu_book_rounded,
            'Cardápio',
            widget.cardapio.nome,
          ),
          const SizedBox(height: 6),
          _linhaResumo(
            Icons.list_alt_rounded,
            'Ingredientes',
            '${_itens.length} item${_itens.length != 1 ? 'ns' : ''}',
          ),
          const SizedBox(height: 6),
          _linhaResumo(
            Icons.scale_outlined,
            'Peso total',
            '${_totalGramas.toStringAsFixed(0)}g',
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.corBorda.withOpacity(0.3)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.corTexto,
                ),
              ),
              Text(
                'R\$ ${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.corDestaque,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linhaResumo(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.corPrimaria),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.corSubtexto),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.corTexto),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _rodape() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        border: Border(
          top: BorderSide(
              color: AppTheme.corBorda.withOpacity(0.3), width: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.corErro.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.corErro.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.corErro, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMsg!,
                        style: const TextStyle(
                            color: AppTheme.corErro, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              // Voltar e editar
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text('Editar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.corPrimaria,
                  side: const BorderSide(
                      color: AppTheme.corPrimaria, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              // Confirmar pedido
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.corPrimaria),
                      )
                    : ElevatedButton.icon(
                        onPressed:
                            _itens.isEmpty ? null : _confirmarPedido,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Confirmar pedido'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Estado de sucesso ──────────────────────────────────────────────────

  Widget _sucessoState() => Center(
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
                        color: AppTheme.corSucesso.withOpacity(0.4),
                        width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppTheme.corSucesso, size: 38),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pedido realizado!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.corTexto,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Seu pedido em ${widget.marmiteria.nome} foi enviado com sucesso.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.corSubtexto,
                      height: 1.5),
                ),
                const SizedBox(height: 16),
                // Total pago
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.corDestaque.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.corDestaque.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Total: R\$ ${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.corDestaque,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () {
                    // Volta até a tela inicial (navigation)
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: const Text('Ir para o início'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_pedidoFeito) {
      return Scaffold(
        backgroundColor: AppTheme.corFundo,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Pedido confirmado'),
          backgroundColor: AppTheme.corFundo,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
                height: 1, color: AppTheme.corBorda.withOpacity(0.3)),
          ),
        ),
        body: _sucessoState(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      appBar: AppBar(
        backgroundColor: AppTheme.corFundo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.corPrimaria, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Carrinho',
          style: TextStyle(
            color: AppTheme.corDestaque,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: AppTheme.corBorda.withOpacity(0.3)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _itens.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 52,
                            color: AppTheme.corPrimaria.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text(
                          'Seu carrinho está vazio.',
                          style: TextStyle(
                              color: AppTheme.corSubtexto, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Voltar e adicionar'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    children: [
                      // Cards dos itens
                      ...List.generate(
                        _itens.length,
                        (i) => _itemCard(_itens[i], i),
                      ),
                      const SizedBox(height: 8),
                      // Card de resumo
                      _resumoCard(),
                      const SizedBox(height: 8),
                    ],
                  ),
          ),
          if (_itens.isNotEmpty) _rodape(),
        ],
      ),
    );
  }
}
