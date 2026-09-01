import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/cardapio.dart';
import 'package:prototipo1/carrinho_provider.dart';
import 'package:prototipo1/marmiteria.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Página do Carrinho ───────────────────────────────────────────────────────

class Carrinho extends StatefulWidget {
  final List<ItemCarrinho>? itens;
  final CardapioModel? cardapio;
  final MarmiteriaModel? marmiteria;

  const Carrinho({
    super.key,
    this.itens,
    this.cardapio,
    this.marmiteria,
  });

  @override
  State<Carrinho> createState() => _CarrinhoState();
}

class _CarrinhoState extends State<Carrinho> {
  final _http = http.Client();

  bool _isLoading = false;
  bool _pedidoFeito = false;
  int _pedidosConcluidosCount = 0;
  double _valorTotalFinal = 0.0;
  String? _errorMsg;
  String _nomeCliente = '';

  @override
  void initState() {
    super.initState();
    _carregarNome();
    // Compatibilidade legado: se veio de cardápio via argumentos diretos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.itens != null &&
          widget.itens!.isNotEmpty &&
          widget.cardapio != null &&
          widget.marmiteria != null) {
        final carrinho = context.read<CarrinhoProvider>();
        if (carrinho.isEmpty) {
          carrinho.adicionarMarmita(
            cardapio: widget.cardapio!,
            marmiteria: widget.marmiteria!,
            ingredientes: widget.itens!,
          );
        }
      }
    });
  }

  Future<void> _carregarNome() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _nomeCliente = prefs.getString('username') ?? '');
  }

  Future<void> _confirmarPedido() async {
    final carrinho = context.read<CarrinhoProvider>();
    if (carrinho.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final url = Uri.parse('http://localhost:8080/apiPedido/inserir');

    // Prepara as requisições para cada marmita (considerando a quantidade de cada uma)
    final List<Map<String, dynamic>> requests = [];

    for (final marmita in carrinho.marmitas) {
      for (int i = 0; i < marmita.quantidade; i++) {
        requests.add({
          'username': _nomeCliente,
          'cardapioId': marmita.cardapio.id,
          'ingredientes': marmita.ingredientes
              .map((item) => {
                    'nome': item.ingrediente.nome,
                    'valorPorGramas': item.ingrediente.valorPorGramas,
                    'gramas': item.gramas,
                    'posicao': item.ingrediente.posicao,
                  })
              .toList(),
        });
      }
    }

    final totalPago = carrinho.totalGeral;

    try {
      final responses = await Future.wait(
        requests.map(
          (body) => _http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          ),
        ),
      );

      final todosSucesso = responses.every((r) => r.statusCode == 201);

      if (mounted) {
        if (todosSucesso) {
          setState(() {
            _pedidosConcluidosCount = requests.length;
            _valorTotalFinal = totalPago;
            _pedidoFeito = true;
            _isLoading = false;
          });
          carrinho.limparCarrinho();
        } else {
          final comErro = responses.where((r) => r.statusCode != 201).length;
          setState(() {
            _errorMsg =
                'Erro ao enviar $comErro de ${requests.length} marmitas. Tente novamente.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Erro de conexão ao enviar pedidos: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ── Card de Marmita Individual ─────────────────────────────────────────────

  Widget _marmitaCard(
      MarmitaItemCarrinho marmita, int index, CarrinhoProvider provider) {
    final colors = [
      AppTheme.corPrimaria,
      AppTheme.corDestaque,
      AppTheme.corSecundaria,
    ];
    final accent = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.corBorda.withOpacity(0.25), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Cabeçalho da Marmita
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                      color: accent.withOpacity(0.2), width: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lunch_dining_rounded, color: accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${marmita.nomeCustomizado}  •  ${marmita.cardapio.nome}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.corTexto,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          marmita.marmiteria.nome,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.corSubtexto),
                        ),
                      ],
                    ),
                  ),
                  // Botão Remover Marmita
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.corErro, size: 20),
                    tooltip: 'Remover marmita',
                    onPressed: () => provider.removerMarmita(index),
                  ),
                ],
              ),
            ),

            // Ingredientes da Marmita
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INGREDIENTES SELECIONADOS:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.corSubtexto,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...marmita.ingredientes.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.eco_rounded,
                                size: 12, color: AppTheme.corPrimaria),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.ingrediente.nome,
                                style: const TextStyle(
                                    fontSize: 13, color: AppTheme.corTexto),
                              ),
                            ),
                            Text(
                              '${item.gramas.toStringAsFixed(0)}g',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.corSubtexto,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'R\$ ${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.corTexto),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            Divider(height: 1, color: AppTheme.corBorda.withOpacity(0.2)),

            // Rodapé do Card com Controle de Quantidades e Subtotal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Qtd:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.corSubtexto),
                  ),
                  const SizedBox(width: 8),
                  // Botão -
                  _qtdBtn(
                    icon: Icons.remove_rounded,
                    onTap: () => provider.alterarQuantidade(index, -1),
                    color: AppTheme.corErro,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${marmita.quantidade}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.corTexto,
                      ),
                    ),
                  ),
                  // Botão +
                  _qtdBtn(
                    icon: Icons.add_rounded,
                    onTap: () => provider.alterarQuantidade(index, 1),
                    color: AppTheme.corSucesso,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${marmita.gramasTotal.toStringAsFixed(0)}g total',
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.corSubtexto),
                      ),
                      Text(
                        'R\$ ${marmita.subtotalTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.corDestaque,
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

  Widget _qtdBtn({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3), width: 0.8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  // ── Resumo Geral ───────────────────────────────────────────────────────────

  Widget _resumoCard(CarrinhoProvider carrinho) {
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
            'RESUMO GERAL DO PEDIDO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.corSubtexto,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _linhaResumo(
            Icons.lunch_dining_rounded,
            'Total de marmitas',
            '${carrinho.totalMarmitasCount} unidade${carrinho.totalMarmitasCount != 1 ? 's' : ''}',
          ),
          const SizedBox(height: 6),
          _linhaResumo(
            Icons.scale_outlined,
            'Peso total agrupado',
            '${carrinho.totalGramasGeral.toStringAsFixed(0)}g',
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.corBorda.withOpacity(0.3)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total a Pagar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.corTexto,
                ),
              ),
              Text(
                'R\$ ${carrinho.totalGeral.toStringAsFixed(2)}',
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

  Widget _rodape(CarrinhoProvider carrinho) {
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
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Mais marmitas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.corPrimaria,
                  side: const BorderSide(
                      color: AppTheme.corPrimaria, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.corPrimaria),
                      )
                    : ElevatedButton.icon(
                        onPressed:
                            carrinho.isEmpty ? null : _confirmarPedido,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text('Finalizar (${carrinho.totalMarmitasCount})'),
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

  // ── Tela de Sucesso ────────────────────────────────────────────────────────

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
                  'Seu pedido contendo $_pedidosConcluidosCount marmita${_pedidosConcluidosCount != 1 ? 's' : ''} foi enviado com sucesso.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.corSubtexto,
                      height: 1.5),
                ),
                const SizedBox(height: 16),
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
                    'Total pago: R\$ ${_valorTotalFinal.toStringAsFixed(2)}',
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
    final carrinho = context.watch<CarrinhoProvider>();

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
        title: Text(
          'Carrinho (${carrinho.totalMarmitasCount})',
          style: const TextStyle(
            color: AppTheme.corDestaque,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!carrinho.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: AppTheme.corErro),
              tooltip: 'Esvaziar carrinho',
              onPressed: () => carrinho.limparCarrinho(),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: AppTheme.corBorda.withOpacity(0.3)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: carrinho.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 56,
                            color: AppTheme.corPrimaria.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text(
                          'Seu carrinho está vazio.',
                          style: TextStyle(
                              color: AppTheme.corSubtexto, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Adicione marmitas customizadas para fazer seu pedido.',
                          style: TextStyle(
                              color: AppTheme.corSubtexto, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Voltar ao cardápio'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    children: [
                      ...List.generate(
                        carrinho.marmitas.length,
                        (i) => _marmitaCard(
                            carrinho.marmitas[i], i, carrinho),
                      ),
                      const SizedBox(height: 8),
                      _resumoCard(carrinho),
                      const SizedBox(height: 8),
                    ],
                  ),
          ),
          if (!carrinho.isEmpty) _rodape(carrinho),
        ],
      ),
    );
  }
}
