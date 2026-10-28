import 'package:flutter/material.dart';
import 'package:prototipo1/recorrencia_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider que gerencia pedidos recorrentes salvos localmente.
class RecorrenciaProvider extends ChangeNotifier {
  static const _prefKey = 'cna_recorrencias_v1';

  List<RecorrenciaModel> _recorrencias = [];

  List<RecorrenciaModel> get recorrencias =>
      List.unmodifiable(_recorrencias);

  List<RecorrenciaModel> get ativas =>
      _recorrencias.where((r) => r.ativo).toList();

  /// Carrega a lista persistida do SharedPreferences
  Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        _recorrencias = RecorrenciaModel.decodeList(raw);
        notifyListeners();
      }
    } catch (_) {
      // em caso de dado corrompido, reinicia
      _recorrencias = [];
    }
  }

  Future<void> _salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey, RecorrenciaModel.encodeList(_recorrencias));
  }

  /// Adiciona uma nova recorrência
  Future<void> adicionar(RecorrenciaModel r) async {
    _recorrencias.insert(0, r);
    notifyListeners();
    await _salvar();
  }

  /// Ativa ou desativa uma recorrência
  Future<void> alternarAtivo(String id) async {
    final idx = _recorrencias.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _recorrencias[idx] =
        _recorrencias[idx].copyWith(ativo: !_recorrencias[idx].ativo);
    notifyListeners();
    await _salvar();
  }

  /// Atualiza os dias da semana de uma recorrência
  Future<void> alterarDias(String id, List<int> novosDias) async {
    final idx = _recorrencias.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _recorrencias[idx] = _recorrencias[idx].copyWith(diasSemana: novosDias);
    notifyListeners();
    await _salvar();
  }

  /// Atualiza o número de semanas restantes (null = indefinido)
  Future<void> alterarSemanas(String id, int? novasSemanas) async {
    final idx = _recorrencias.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _recorrencias[idx] = RecorrenciaModel(
      id: _recorrencias[idx].id,
      nomeMarmita: _recorrencias[idx].nomeMarmita,
      nomeCardapio: _recorrencias[idx].nomeCardapio,
      cardapioId: _recorrencias[idx].cardapioId,
      nomeMarmiteria: _recorrencias[idx].nomeMarmiteria,
      ingredientes: _recorrencias[idx].ingredientes,
      diasSemana: _recorrencias[idx].diasSemana,
      semanasRestantes: novasSemanas,
      totalSemanas: novasSemanas ?? _recorrencias[idx].totalSemanas,
      valorEstimado: _recorrencias[idx].valorEstimado,
      criadoEm: _recorrencias[idx].criadoEm,
      ativo: _recorrencias[idx].ativo,
    );
    notifyListeners();
    await _salvar();
  }

  /// Remove permanentemente uma recorrência
  Future<void> remover(String id) async {
    _recorrencias.removeWhere((r) => r.id == id);
    notifyListeners();
    await _salvar();
  }

  /// Decrementa as semanas de todos os recorrentes ativos com limite definido
  /// Deve ser chamado uma vez por semana em produção (aqui apenas para demo)
  Future<void> processarSemana() async {
    bool mudou = false;
    for (int i = 0; i < _recorrencias.length; i++) {
      final r = _recorrencias[i];
      if (!r.ativo || r.semanasRestantes == null) continue;
      if (r.semanasRestantes! <= 1) {
        // Esgotou — desativa
        _recorrencias[i] = r.copyWith(ativo: false, semanasRestantes: 0);
      } else {
        _recorrencias[i] =
            r.copyWith(semanasRestantes: r.semanasRestantes! - 1);
      }
      mudou = true;
    }
    if (mudou) {
      notifyListeners();
      await _salvar();
    }
  }
}
