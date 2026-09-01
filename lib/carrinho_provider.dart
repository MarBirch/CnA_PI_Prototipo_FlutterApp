import 'package:flutter/material.dart';
import 'package:prototipo1/cardapio.dart';
import 'package:prototipo1/marmiteria.dart';

/// Representa uma marmita customizada individual no carrinho.
class MarmitaItemCarrinho {
  final String id;
  final CardapioModel cardapio;
  final MarmiteriaModel marmiteria;
  final List<ItemCarrinho> ingredientes;
  int quantidade;
  String nomeCustomizado;

  MarmitaItemCarrinho({
    required this.id,
    required this.cardapio,
    required this.marmiteria,
    required this.ingredientes,
    this.quantidade = 1,
    this.nomeCustomizado = 'Marmita',
  });

  /// Subtotal de 1 unidade desta marmita
  double get subtotalUnidade =>
      ingredientes.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Subtotal total considerando a quantidade
  double get subtotalTotal => subtotalUnidade * quantidade;

  /// Peso em gramas de 1 unidade
  double get gramasUnidade =>
      ingredientes.fold(0.0, (sum, item) => sum + item.gramas);

  /// Peso total em gramas considerando a quantidade
  double get gramasTotal => gramasUnidade * quantidade;

  /// Cria uma cópia profunda da marmita
  MarmitaItemCarrinho copyWith({int? quantidade}) {
    return MarmitaItemCarrinho(
      id: id,
      cardapio: cardapio,
      marmiteria: marmiteria,
      ingredientes: ingredientes
          .map((i) => ItemCarrinho(ingrediente: i.ingrediente, gramas: i.gramas))
          .toList(),
      quantidade: quantidade ?? this.quantidade,
      nomeCustomizado: nomeCustomizado,
    );
  }
}

/// Provider que gerencia a lista de marmitas no carrinho de compras.
class CarrinhoProvider extends ChangeNotifier {
  final List<MarmitaItemCarrinho> _marmitas = [];

  List<MarmitaItemCarrinho> get marmitas => List.unmodifiable(_marmitas);

  /// Quantidade total de marmitas no carrinho (somando as unidades)
  int get totalMarmitasCount =>
      _marmitas.fold(0, (sum, m) => sum + m.quantidade);

  /// Valor total acumulado de todas as marmitas do carrinho
  double get totalGeral =>
      _marmitas.fold(0.0, (sum, m) => sum + m.subtotalTotal);

  /// Peso total em gramas de todas as marmitas no carrinho
  double get totalGramasGeral =>
      _marmitas.fold(0.0, (sum, m) => sum + m.gramasTotal);

  /// Indica se o carrinho está vazio
  bool get isEmpty => _marmitas.isEmpty;

  /// Adiciona uma nova marmita customizada ao carrinho
  void adicionarMarmita({
    required CardapioModel cardapio,
    required MarmiteriaModel marmiteria,
    required List<ItemCarrinho> ingredientes,
    int quantidade = 1,
    String? nomeCustomizado,
  }) {
    if (ingredientes.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final numeroMarmita = _marmitas.length + 1;
    final titulo = nomeCustomizado ?? 'Marmita #$numeroMarmita';

    _marmitas.add(
      MarmitaItemCarrinho(
        id: id,
        cardapio: cardapio,
        marmiteria: marmiteria,
        ingredientes: ingredientes
            .map((i) => ItemCarrinho(ingrediente: i.ingrediente, gramas: i.gramas))
            .toList(),
        quantidade: quantidade,
        nomeCustomizado: titulo,
      ),
    );
    notifyListeners();
  }

  /// Altera a quantidade de uma marmita existente
  void alterarQuantidade(int index, int delta) {
    if (index < 0 || index >= _marmitas.length) return;
    _marmitas[index].quantidade += delta;
    if (_marmitas[index].quantidade <= 0) {
      _marmitas.removeAt(index);
    }
    notifyListeners();
  }

  /// Remove uma marmita pelo seu índice na lista
  void removerMarmita(int index) {
    if (index < 0 || index >= _marmitas.length) return;
    _marmitas.removeAt(index);
    notifyListeners();
  }

  /// Limpa todas as marmitas do carrinho
  void limparCarrinho() {
    _marmitas.clear();
    notifyListeners();
  }
}
