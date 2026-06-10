import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/carrinho.dart';
import 'package:prototipo1/marmiteria.dart';

// ── Modelo de item no carrinho ─────────────────────────────────────────────

class ItemCarrinho {
  final IngredienteModel ingrediente;
  double gramas;

  ItemCarrinho({required this.ingrediente, required this.gramas});

  double get subtotal => ingrediente.valorPorGramas * gramas;
}

// ── Página ─────────────────────────────────────────────────────────────────

class Cardapio extends StatefulWidget {
  final CardapioModel cardapio;
  final MarmiteriaModel marmiteria;

  const Cardapio({
    super.key,
    required this.cardapio,
    required this.marmiteria,
  });

  @override
  State<Cardapio> createState() => _CardapioState();
}

class _CardapioState extends State<Cardapio> {
  // Map: ingredienteId → gramas escolhidas (0 = não selecionado)
  late Map<int, double> _gramas;

  // Controladores de texto para cada campo
  late Map<int, TextEditingController> _controllers;

  static const double _passo = 50.0; // incremento dos botões +/-
  static const double _minGramas = 50.0;
  static const double _maxGramas = 500.0;

  @override
  void initState() {
    super.initState();
    _gramas = {for (final i in widget.cardapio.ingredientes) i.id: 0.0};
    _controllers = {
      for (final i in widget.cardapio.ingredientes)
        i.id: TextEditingController(text: '0')
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  double get _totalGramas =>
      _gramas.values.fold(0, (sum, v) => sum + v);

  double get _totalValor => widget.cardapio.ingredientes.fold(0.0, (sum, ing) {
        final g = _gramas[ing.id] ?? 0.0;
        return sum + ing.valorPorGramas * g;
      });

  int get _qtdSelecionados =>
      _gramas.values.where((v) => v > 0).length;

  List<ItemCarrinho> get _itensSelecionados => widget.cardapio.ingredientes
      .where((i) => (_gramas[i.id] ?? 0) > 0)
      .map((i) => ItemCarrinho(ingrediente: i, gramas: _gramas[i.id]!))
      .toList();

  void _setGramas(IngredienteModel ing, double valor) {
    setState(() {
      _gramas[ing.id] = valor.clamp(0, _maxGramas);
      _controllers[ing.id]!.text = _gramas[ing.id]!.toStringAsFixed(0);
    });
  }

  void _incrementar(IngredienteModel ing) {
    final atual = _gramas[ing.id] ?? 0.0;
    final novo = atual == 0 ? _minGramas : atual + _passo;
    _setGramas(ing, novo);
  }

  void _decrementar(IngredienteModel ing) {
    final atual = _gramas[ing.id] ?? 0.0;
    if (atual <= _minGramas) {
      _setGramas(ing, 0);
    } else {
      _setGramas(ing, atual - _passo);
    }
  }

  void _irParaCarrinho() {
    if (_itensSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um ingrediente.'),
          backgroundColor: AppTheme.corErro,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Carrinho(
          itens: _itensSelecionados,
          cardapio: widget.cardapio,
          marmiteria: widget.marmiteria,
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _ingredienteCard(IngredienteModel ing, int index) {
    final gramas = _gramas[ing.id] ?? 0.0;
    final selecionado = gramas > 0;
    final subtotal = ing.valorPorGramas * gramas;
    final colors = [
      AppTheme.corPrimaria,
      AppTheme.corDestaque,
      AppTheme.corSecundaria,
    ];
    final accent = colors[index % colors.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: selecionado
            ? AppTheme.corCard
            : AppTheme.corCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selecionado
              ? accent.withOpacity(0.5)
              : AppTheme.corBorda.withOpacity(0.2),
          width: selecionado ? 1.2 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: selecionado
                ? accent.withOpacity(0.1)
                : Colors.black.withOpacity(0.03),
            blurRadius: selecionado ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Barra lateral colorida quando selecionado
            if (selecionado)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: accent),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  selecionado ? 16 : 12, 12, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Ícone + nome
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: selecionado
                              ? accent.withOpacity(0.15)
                              : AppTheme.corPrimaria.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.eco_outlined,
                          color: selecionado
                              ? accent
                              : AppTheme.corSubtexto,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ing.nome,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: selecionado
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: AppTheme.corTexto,
                              ),
                            ),
                            Text(
                              'R\$ ${ing.valorPorGramas.toStringAsFixed(2)}/g',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.corSubtexto),
                            ),
                          ],
                        ),
                      ),
                      // Subtotal (só quando selecionado)
                      if (selecionado)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.corDestaque.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'R\$ ${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.corDestaque,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Controle de gramas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botão –
                      _ctrlBtn(
                        icon: Icons.remove_rounded,
                        onTap: () => _decrementar(ing),
                        enabled: gramas > 0,
                        color: AppTheme.corErro,
                      ),
                      const SizedBox(width: 8),
                      // Campo de texto com gramas
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _controllers[ing.id],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.corTexto),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                            filled: true,
                            fillColor: AppTheme.corFundo,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: AppTheme.corBorda.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: selecionado
                                      ? accent.withOpacity(0.5)
                                      : AppTheme.corBorda.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: accent, width: 1.4),
                            ),
                            suffix: const Text('g',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.corSubtexto)),
                          ),
                          onChanged: (v) {
                            final val = double.tryParse(v) ?? 0.0;
                            setState(() {
                              _gramas[ing.id] =
                                  val.clamp(0, _maxGramas);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botão +
                      _ctrlBtn(
                        icon: Icons.add_rounded,
                        onTap: () => _incrementar(ing),
                        enabled: gramas < _maxGramas,
                        color: AppTheme.corSucesso,
                      ),
                    ],
                  ),
                  // Hint quando não selecionado
                  if (!selecionado) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Toque + para adicionar (mín. ${_minGramas.toInt()}g)',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.corSubtexto),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctrlBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
    required Color color,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
            width: 0.8,
          ),
        ),
        child: Icon(icon,
            color: enabled ? color : Colors.grey.withOpacity(0.4), size: 18),
      ),
    );
  }

  Widget _rodape() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resumo
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_qtdSelecionados ingrediente${_qtdSelecionados != 1 ? 's' : ''} • '
                    '${_totalGramas.toStringAsFixed(0)}g total',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.corSubtexto),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total: R\$ ${_totalValor.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.corTexto,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _irParaCarrinho,
                icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                label: const Text('Adicionar ao carrinho'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: Column(
          children: [
            Text(
              widget.cardapio.nome,
              style: const TextStyle(
                color: AppTheme.corDestaque,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.marmiteria.nome,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.corSubtexto),
            ),
          ],
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
          // Cabeçalho informativo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.corPrimaria.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.corPrimaria.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.corPrimaria, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ajuste a quantidade de cada ingrediente. Use + e – ou digite o valor em gramas.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.corSubtexto,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Lista de ingredientes
          Expanded(
            child: widget.cardapio.ingredientes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.no_food_rounded,
                            size: 52,
                            color: AppTheme.corPrimaria.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhum ingrediente neste cardápio.',
                          style: TextStyle(
                              color: AppTheme.corSubtexto, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    itemCount: widget.cardapio.ingredientes.length,
                    itemBuilder: (_, i) => _ingredienteCard(
                      widget.cardapio.ingredientes[i],
                      i,
                    ),
                  ),
          ),
          _rodape(),
        ],
      ),
    );
  }
}