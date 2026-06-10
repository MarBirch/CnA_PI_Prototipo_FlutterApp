class IngredientePedido {
  final int id;
  final String nome;
  final double valorPorGramas;
  final double gramas;
  final int posicao;

  IngredientePedido({
    required this.id,
    required this.nome,
    required this.valorPorGramas,
    required this.gramas,
    required this.posicao,
  });

  double get subtotal => valorPorGramas * gramas;

  factory IngredientePedido.fromJson(Map<String, dynamic> j) =>
      IngredientePedido(
        id: (j['id'] as num?)?.toInt() ?? 0,
        nome: j['nome'] as String? ?? '',
        valorPorGramas: (j['valorPorGramas'] as num?)?.toDouble() ?? 0.0,
        gramas: (j['gramas'] as num?)?.toDouble() ?? 0.0,
        posicao: (j['posicao'] as num?)?.toInt() ?? 0,
      );
}

class PedidoModel {
  late DateTime _dataCriada;
  late int _id;
  late List<IngredientePedido> _ingredientes;
  late String _nomeMarmiteria;
  late String _status;
  late double _valor;
  late String _cardapioNome;
  late int _cardapioId;

  get dataCriada => _dataCriada;
  set dataCriada(value) => _dataCriada = value;

  get id => _id;
  set id(value) => _id = value;

  get ingredientes => _ingredientes;
  set ingredientes(value) => _ingredientes = value;

  get nomeMarmiteria => _nomeMarmiteria;
  set nomeMarmiteria(value) => _nomeMarmiteria = value;

  get status => _status;
  set status(value) => _status = value;

  get valor => _valor;
  set valor(value) => _valor = value;

  get cardapioNome => _cardapioNome;
  set cardapioNome(value) => _cardapioNome = value;

  get cardapioId => _cardapioId;
  set cardapioId(value) => _cardapioId = value;

  PedidoModel.fromJson(Map<String, dynamic> json)
      : _dataCriada = DateTime.parse(json['dataCriada']),
        _id = (json['id'] as num?)?.toInt() ?? 0,
        _ingredientes = ((json['ingredientes'] as List?) ?? [])
            .map((e) => IngredientePedido.fromJson(e as Map<String, dynamic>))
            .toList(),
        _nomeMarmiteria = json['nomeMarmiteria'] as String? ?? '',
        _status = json['status'] as String? ?? 'DESCONHECIDO',
        _valor = (json['valor'] as num?)?.toDouble() ?? 0.0,
        _cardapioNome = json['cardapioNome'] as String? ?? '',
        _cardapioId = (json['cardapioId'] as num?)?.toInt() ?? 0;
}