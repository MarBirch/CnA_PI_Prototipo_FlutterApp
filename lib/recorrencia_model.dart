import 'dart:convert';

/// Modelo de um pedido recorrente salvo localmente.
class RecorrenciaModel {
  final String id;

  /// Nome customizado da marmita
  final String nomeMarmita;

  /// Nome do cardápio
  final String nomeCardapio;

  /// ID do cardápio
  final int cardapioId;

  /// Nome da marmiteria
  final String nomeMarmiteria;

  /// Ingredientes serializados como lista de mapas
  final List<Map<String, dynamic>> ingredientes;

  /// Dias da semana para entrega (1 = segunda … 7 = domingo — ISO 8601).
  /// Permite múltiplos dias, ex.: [1, 3, 5] = Seg, Qua, Sex.
  final List<int> diasSemana;

  /// Número de semanas restantes; null = indefinido (até o usuário desativar)
  final int? semanasRestantes;

  /// Total de semanas configuradas originalmente (para exibição)
  final int? totalSemanas;

  /// Valor estimado por pedido (por unidade / por dia)
  final double valorEstimado;

  /// Data de criação da recorrência
  final DateTime criadoEm;

  /// Indica se a recorrência está ativa
  final bool ativo;

  const RecorrenciaModel({
    required this.id,
    required this.nomeMarmita,
    required this.nomeCardapio,
    required this.cardapioId,
    required this.nomeMarmiteria,
    required this.ingredientes,
    required this.diasSemana,
    this.semanasRestantes,
    this.totalSemanas,
    required this.valorEstimado,
    required this.criadoEm,
    this.ativo = true,
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  static const _nomesDia = [
    '',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  /// Nomes curtos de cada dia selecionado, ex.: "Seg, Qua, Sex"
  String get nomeDias {
    if (diasSemana.isEmpty) return '—';
    final sorted = [...diasSemana]..sort();
    return sorted
        .map((d) => _nomesDia[d.clamp(1, 7)])
        .join(', ');
  }

  String get resumoSemanas {
    if (semanasRestantes == null) return 'Indefinido';
    return '$semanasRestantes semana${semanasRestantes != 1 ? 's' : ''} '
        'restante${semanasRestantes != 1 ? 's' : ''}';
  }

  // ── copyWith ─────────────────────────────────────────────────────────────

  RecorrenciaModel copyWith({
    String? nomeMarmita,
    List<int>? diasSemana,
    int? semanasRestantes,
    bool? ativo,
    bool clearSemanas = false,
  }) {
    return RecorrenciaModel(
      id: id,
      nomeMarmita: nomeMarmita ?? this.nomeMarmita,
      nomeCardapio: nomeCardapio,
      cardapioId: cardapioId,
      nomeMarmiteria: nomeMarmiteria,
      ingredientes: ingredientes,
      diasSemana: diasSemana ?? this.diasSemana,
      semanasRestantes:
          clearSemanas ? null : (semanasRestantes ?? this.semanasRestantes),
      totalSemanas: totalSemanas,
      valorEstimado: valorEstimado,
      criadoEm: criadoEm,
      ativo: ativo ?? this.ativo,
    );
  }

  // ── Serialização ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomeMarmita': nomeMarmita,
        'nomeCardapio': nomeCardapio,
        'cardapioId': cardapioId,
        'nomeMarmiteria': nomeMarmiteria,
        'ingredientes': ingredientes,
        'diasSemana': diasSemana,
        'semanasRestantes': semanasRestantes,
        'totalSemanas': totalSemanas,
        'valorEstimado': valorEstimado,
        'criadoEm': criadoEm.toIso8601String(),
        'ativo': ativo,
      };

  factory RecorrenciaModel.fromJson(Map<String, dynamic> j) {
    // Suporte a dados antigos com campo 'diaSemana' (int singular)
    List<int> dias;
    if (j.containsKey('diasSemana')) {
      dias = (j['diasSemana'] as List).map((e) => (e as num).toInt()).toList();
    } else if (j.containsKey('diaSemana')) {
      dias = [(j['diaSemana'] as num).toInt()];
    } else {
      dias = [];
    }

    return RecorrenciaModel(
      id: j['id'] as String,
      nomeMarmita: j['nomeMarmita'] as String,
      nomeCardapio: j['nomeCardapio'] as String,
      cardapioId: (j['cardapioId'] as num).toInt(),
      nomeMarmiteria: j['nomeMarmiteria'] as String,
      ingredientes: (j['ingredientes'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      diasSemana: dias,
      semanasRestantes: (j['semanasRestantes'] as num?)?.toInt(),
      totalSemanas: (j['totalSemanas'] as num?)?.toInt(),
      valorEstimado: (j['valorEstimado'] as num).toDouble(),
      criadoEm: DateTime.parse(j['criadoEm'] as String),
      ativo: j['ativo'] as bool? ?? true,
    );
  }

  static String encodeList(List<RecorrenciaModel> list) =>
      jsonEncode(list.map((r) => r.toJson()).toList());

  static List<RecorrenciaModel> decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => RecorrenciaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
