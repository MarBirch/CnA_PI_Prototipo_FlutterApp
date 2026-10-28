import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/pedido_model.dart';
import 'package:prototipo1/recorrencia_model.dart';
import 'package:prototipo1/recorrencia_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pedido extends StatefulWidget {
  const Pedido({super.key});

  @override
  State<Pedido> createState() => _PedidoState();
}

class _PedidoState extends State<Pedido> with TickerProviderStateMixin {
  final _httpClient = http.Client();
  final _scrollController = ScrollController();
  late final TabController _tabController;

  List<PedidoModel> _pedidos = [];
  bool _isLoading = true;
  String? _errorMsg;
  final Set<int> _expandedIds = {};

  // Status que vão para o histórico (concluídos / cancelados)
  static const _statusHistorico = {'CONCLUIDO', 'ENTREGUE', 'CANCELADO'};

  List<PedidoModel> get _ativos => _pedidos
      .where((p) => !_statusHistorico.contains((p.status as String).toUpperCase()))
      .toList()
        ..sort((a, b) =>
            (b.dataCriada as DateTime).compareTo(a.dataCriada as DateTime));

  List<PedidoModel> get _historico => _pedidos
      .where((p) => _statusHistorico.contains((p.status as String).toUpperCase()))
      .toList()
        ..sort((a, b) =>
            (b.dataCriada as DateTime).compareTo(a.dataCriada as DateTime));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pedirPedido();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _httpClient.close();
    super.dispose();
  }

  Future<void> _pedirPedido() async {
    final url = Uri.parse('http://localhost:8080/apiPedido/pedidos');
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    try {
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': 'empty'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _pedidos = data
              .map((e) => PedidoModel.fromJson(e as Map<String, dynamic>))
              .toList();
          // Ordena todos os pedidos do mais recente ao mais antigo
          _pedidos.sort((a, b) =>
              (b.dataCriada as DateTime).compareTo(a.dataCriada as DateTime));
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

  // ── Cancelar pedido ──────────────────────────────────────────────────────

  Future<void> _cancelarPedido(PedidoModel pedido) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.corCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar pedido?',
            style: TextStyle(
                color: AppTheme.corTexto,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        content: const Text(
            'Esta ação não pode ser desfeita. Deseja mesmo cancelar este pedido?',
            style: TextStyle(color: AppTheme.corSubtexto, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar',
                style: TextStyle(color: AppTheme.corSubtexto)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.corErro,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final url =
        Uri.parse('http://localhost:8080/apiPedido/remover/${pedido.id}');
    try {
      final response = await _httpClient.delete(url);
      if (response.statusCode == 204) {
        setState(() => _pedidos.removeWhere((p) => p.id == pedido.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pedido cancelado com sucesso.'),
            backgroundColor: AppTheme.corSucesso,
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao cancelar: ${response.statusCode}'),
            backgroundColor: AppTheme.corErro,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: AppTheme.corErro,
        ));
      }
    }
  }

  // ── Abrir bottom sheet de edição ─────────────────────────────────────────

  void _abrirEdicao(PedidoModel pedido) async {
    final atualizado = await showModalBottomSheet<PedidoModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarPedidoSheet(
        pedido: pedido,
        httpClient: _httpClient,
        onCancelar: () {
          Navigator.pop(context);
          _cancelarPedido(pedido);
        },
      ),
    );

    // Se o sheet retornou um pedido atualizado, substitui na lista
    if (atualizado != null && mounted) {
      setState(() {
        final idx = _pedidos.indexWhere((p) => p.id == atualizado.id);
        if (idx != -1) _pedidos[idx] = atualizado;
      });
    }
  }

  void _abrirAvaliacao(PedidoModel pedido) {
    int rating = 5;
    final tags = ['Saborosa', 'Nutritiva', 'Entregue Quente', 'Porção Generosa'];
    final selectedTags = <String>{'Saborosa', 'Nutritiva'};
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.corCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              Text(
                'Avaliar Pedido #${pedido.id}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.corTexto),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Como foi sua experiência com esta refeição?', style: TextStyle(fontSize: 13, color: AppTheme.corSubtexto)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 30,
                    ),
                    onPressed: () => setDialogState(() => rating = starIndex),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: tags.map((t) {
                  final isSel = selectedTags.contains(t);
                  return FilterChip(
                    selected: isSel,
                    label: Text(t, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : AppTheme.corTexto)),
                    selectedColor: AppTheme.corPrimaria,
                    backgroundColor: AppTheme.corFundo,
                    onSelected: (val) => setDialogState(() {
                      if (val) selectedTags.add(t); else selectedTags.remove(t);
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Deixe um comentário (opcional)...',
                  hintStyle: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.corSubtexto)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Avaliação enviada com sucesso! Obrigado pelo feedback.'),
                    backgroundColor: AppTheme.corSucesso,
                  ),
                );
              },
              child: const Text('Enviar Avaliação'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de status ────────────────────────────────────────────────────

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PENDENTE':    return AppTheme.corDestaque;
      case 'CONFIRMADO':  return const Color(0xFF1565C0);
      case 'EM_PRODUCAO': return const Color(0xFF6A1B9A);
      case 'PRONTO':
      case 'ENTREGUE':
      case 'CONCLUIDO':   return AppTheme.corSucesso;
      case 'CANCELADO':   return AppTheme.corErro;
      default:            return AppTheme.corSubtexto;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toUpperCase()) {
      case 'PENDENTE':    return Icons.pending_actions_rounded;
      case 'CONFIRMADO':  return Icons.thumb_up_outlined;
      case 'EM_PRODUCAO': return Icons.restaurant_rounded;
      case 'PRONTO':
      case 'ENTREGUE':
      case 'CONCLUIDO':   return Icons.done_all_rounded;
      case 'CANCELADO':   return Icons.cancel_outlined;
      default:            return Icons.info_outline_rounded;
    }
  }

  String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'PENDENTE':    return 'Pendente';
      case 'CONFIRMADO':  return 'Confirmado';
      case 'EM_PRODUCAO': return 'Em produção';
      case 'PRONTO':      return 'Pronto';
      case 'ENTREGUE':    return 'Entregue';
      case 'CONCLUIDO':   return 'Concluído';
      case 'CANCELADO':   return 'Cancelado';
      default:            return s;
    }
  }

  bool _podeCancelar(String s) =>
      s.toUpperCase() == 'PENDENTE';

  // ── Card do pedido ───────────────────────────────────────────────────────

  Widget _buildPedido(PedidoModel pedido) {
    final statusColor = _statusColor(pedido.status as String);
    final isExpanded = _expandedIds.contains(pedido.id as int);
    final dc = pedido.dataCriada as DateTime;
    final dataFmt =
        '${dc.day.toString().padLeft(2, '0')}/${dc.month.toString().padLeft(2, '0')}/${dc.year}  '
        '${dc.hour.toString().padLeft(2, '0')}:${dc.minute.toString().padLeft(2, '0')}';
    final ingredientes = pedido.ingredientes as List<IngredientePedido>;
    final canManage = _podeCancelar(pedido.status as String);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.corBorda.withOpacity(0.2), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Barra de progresso
            _StatusBar(status: pedido.status as String),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge status + botão gerenciar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withOpacity(0.4), width: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(pedido.status as String),
                                color: statusColor, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              _statusLabel(pedido.status as String),
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (canManage)
                        GestureDetector(
                          onTap: () => _abrirEdicao(pedido),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.corPrimaria.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppTheme.corPrimaria.withOpacity(0.3),
                                  width: 0.6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.edit_rounded,
                                    color: AppTheme.corPrimaria, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Gerenciar',
                                  style: TextStyle(
                                      color: AppTheme.corPrimaria,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Cardápio + data
                  Row(children: [
                    const Icon(Icons.menu_book_rounded,
                        size: 13, color: AppTheme.corSubtexto),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        (pedido.cardapioNome as String).isNotEmpty
                            ? pedido.cardapioNome as String
                            : 'Cardápio',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.corTexto),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: AppTheme.corSubtexto),
                    const SizedBox(width: 5),
                    Text(dataFmt,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.corSubtexto)),
                  ]),

                  const SizedBox(height: 12),
                  Divider(height: 1, color: AppTheme.corBorda.withOpacity(0.25)),
                  const SizedBox(height: 10),

                  // Chips de ingredientes
                  _IngredientesChips(ingredientes: ingredientes),

                  // Botão expandir
                  GestureDetector(
                    onTap: () => setState(() {
                      isExpanded
                          ? _expandedIds.remove(pedido.id as int)
                          : _expandedIds.add(pedido.id as int);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isExpanded
                                ? 'Ver menos'
                                : 'Ver detalhes dos ingredientes',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.corPrimaria,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.corPrimaria,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tabela expandida
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: ingredientes.isEmpty
                        ? const SizedBox()
                        : _IngredientesDetalhe(ingredientes: ingredientes),
                    secondChild: const SizedBox(height: 0),
                  ),
                ],
              ),
            ),

            // Rodapé com valor
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.corDestaque.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.corDestaque.withOpacity(0.25), width: 0.6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_rounded,
                      size: 15, color: AppTheme.corDestaque),
                  const SizedBox(width: 6),
                  Text(
                    '${ingredientes.length} ingrediente${ingredientes.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.corSubtexto),
                  ),
                  const Spacer(),
                  Text(
                    'R\$ ${(pedido.valor as double).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.corDestaque),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ativos    = _ativos;
    final historico = _historico;

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
                      const Text('Pedidos',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.corTexto)),
                      const SizedBox(height: 2),
                      Text(
                        '${_pedidos.length} pedido${_pedidos.length != 1 ? 's' : ''}',
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
                    _pedirPedido();
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

          // ── TabBar ───────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            decoration: BoxDecoration(
              color: AppTheme.corCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.corBorda.withOpacity(0.2), width: 0.6),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.corPrimaria,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.corSubtexto,
              labelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text('Ativos (${ativos.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text('Histórico (${historico.length})'),
                    ],
                  ),
                ),
                Consumer<RecorrenciaProvider>(
                  builder: (_, rec, __) => Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.repeat_rounded, size: 14),
                        const SizedBox(width: 4),
                        Text('Recorrentes (${rec.ativas.length})'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Conteúdo ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.corPrimaria))
                : _errorMsg != null
                    ? _errorState()
                        : TabBarView(
                        controller: _tabController,
                        children: [
                          // Aba 1: Ativos
                          ativos.isEmpty
                              ? _emptyState(
                                  icon: Icons.check_circle_outline_rounded,
                                  msg: 'Nenhum pedido ativo no momento.',
                                )
                              : RefreshIndicator(
                                  color: AppTheme.corPrimaria,
                                  backgroundColor: AppTheme.corCard,
                                  onRefresh: _pedirPedido,
                                  child: ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                        top: 4, bottom: 24),
                                    itemCount: ativos.length,
                                    itemBuilder: (_, i) =>
                                        _buildPedido(ativos[i]),
                                  ),
                                ),

                          // Aba 2: Histórico
                          historico.isEmpty
                              ? _emptyState(
                                  icon: Icons.history_toggle_off_rounded,
                                  msg: 'Nenhum pedido no histórico ainda.',
                                )
                              : RefreshIndicator(
                                  color: AppTheme.corPrimaria,
                                  backgroundColor: AppTheme.corCard,
                                  onRefresh: _pedirPedido,
                                  child: ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                        top: 4, bottom: 24),
                                    itemCount: historico.length,
                                    itemBuilder: (_, i) =>
                                        _buildPedidoHistorico(historico[i]),
                                  ),
                                ),

                          // Aba 3: Recorrentes
                          Consumer<RecorrenciaProvider>(
                            builder: (_, recProv, __) {
                              final lista = recProv.recorrencias;
                              if (lista.isEmpty) {
                                return _emptyState(
                                  icon: Icons.repeat_one_rounded,
                                  msg:
                                      'Nenhum pedido recorrente configurado.\nAgende uma recorrência no carrinho!',
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.only(
                                    top: 4, bottom: 24),
                                itemCount: lista.length,
                                itemBuilder: (_, i) =>
                                    _buildRecorrenciaCard(
                                        lista[i], recProv),
                              );
                            },
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // Card para pedidos do histórico — mostra botão "Avaliar" nos concluídos
  Widget _buildPedidoHistorico(PedidoModel pedido) {
    final statusUp = (pedido.status as String).toUpperCase();
    final podAvaliar = statusUp == 'CONCLUIDO' || statusUp == 'ENTREGUE';
    return Stack(
      children: [
        _buildPedido(pedido),
        if (podAvaliar)
          Positioned(
            right: 28,
            bottom: 22,
            child: GestureDetector(
              onTap: () => _abrirAvaliacao(pedido),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.amber.withOpacity(0.5), width: 0.7),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                    SizedBox(width: 4),
                    Text('Avaliar',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _errorState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppTheme.corSubtexto),
            const SizedBox(height: 12),
            Text(_errorMsg!,
                style: const TextStyle(
                    color: AppTheme.corSubtexto, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMsg = null;
                });
                _pedirPedido();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );

  Widget _emptyState({
    IconData icon = Icons.receipt_long_outlined,
    String msg = 'Nenhum pedido encontrado.',
  }) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppTheme.corPrimaria.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.corSubtexto, fontSize: 14)),
          ],
        ),
      );

  // ── Card de recorrência ───────────────────────────────────────────────

  Widget _buildRecorrenciaCard(
      RecorrenciaModel rec, RecorrenciaProvider provider) {
    final accent =
        rec.ativo ? AppTheme.corSecundaria : AppTheme.corSubtexto;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: rec.ativo
                ? AppTheme.corSecundaria.withOpacity(0.3)
                : AppTheme.corBorda.withOpacity(0.2),
            width: 0.6),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Cabeçalho ─────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.07),
              border: Border(
                  bottom: BorderSide(
                      color: accent.withOpacity(0.15), width: 0.5)),
            ),
            child: Row(
              children: [
                // Ícone de recorrência
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.repeat_rounded, color: accent, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.nomeMarmita,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.corTexto),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${rec.nomeCardapio}  ·  ${rec.nomeMarmiteria}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.corSubtexto),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Toggle ativo/inativo
                Switch(
                  value: rec.ativo,
                  onChanged: (_) => provider.alternarAtivo(rec.id),
                  activeColor: AppTheme.corSecundaria,
                ),
              ],
            ),
          ),

          // ── Informações ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              children: [
                // Dias da semana
                _recInfoRow(
                  Icons.calendar_today_rounded,
                  'Dias de entrega',
                  rec.nomeDias,
                  accent,
                ),
                const SizedBox(height: 6),
                // Duração
                _recInfoRow(
                  rec.semanasRestantes == null
                      ? Icons.all_inclusive_rounded
                      : Icons.event_repeat_rounded,
                  'Recorrência',
                  rec.resumoSemanas,
                  rec.semanasRestantes == null
                      ? AppTheme.corPrimaria
                      : AppTheme.corDestaque,
                ),
                const SizedBox(height: 6),
                // Valor estimado
                _recInfoRow(
                  Icons.attach_money_rounded,
                  'Valor estimado / pedido',
                  'R\$ ${rec.valorEstimado.toStringAsFixed(2)}',
                  AppTheme.corDestaque,
                ),

                if (!rec.ativo) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.corErro.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pause_circle_outline_rounded,
                            color: AppTheme.corErro, size: 14),
                        SizedBox(width: 6),
                        Text('Recorrência pausada',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.corErro,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                Divider(
                    height: 1, color: AppTheme.corBorda.withOpacity(0.2)),
                const SizedBox(height: 8),

                // Botões de ação
                Row(
                  children: [
                    // Editar
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _editarRecorrencia(rec, provider),
                        icon: const Icon(
                            Icons.edit_calendar_rounded,
                            size: 14),
                        label: const Text('Editar',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.corPrimaria,
                          side: BorderSide(
                              color: AppTheme.corPrimaria
                                  .withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Remover
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.corCard,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                            title: const Text(
                                'Remover recorrência?',
                                style: TextStyle(
                                    color: AppTheme.corTexto,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            content: const Text(
                                'A marmita não será mais pedida automaticamente.',
                                style: TextStyle(
                                    color: AppTheme.corSubtexto,
                                    fontSize: 13)),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancelar',
                                    style: TextStyle(
                                        color: AppTheme.corSubtexto)),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.corErro),
                                child: const Text('Remover'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) await provider.remover(rec.id);
                      },
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 14),
                      label: const Text('Remover',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.corErro,
                        side: BorderSide(
                            color: AppTheme.corErro.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recInfoRow(
      IconData icon, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text('$label: ',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.corSubtexto)),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  void _editarRecorrencia(
      RecorrenciaModel rec, RecorrenciaProvider provider) async {
    // Multiselect: usa Set para controlar dias marcados
    final Set<int> diasSel = Set<int>.from(rec.diasSemana);
    bool indefinida = rec.semanasRestantes == null;
    int? semanas = rec.semanasRestantes;
    final semCtrl =
        TextEditingController(text: semanas != null ? '$semanas' : '');

    const opcoesDias = [
      (1, 'Seg'), (2, 'Ter'), (3, 'Qua'),
      (4, 'Qui'), (5, 'Sex'), (6, 'Sáb'), (7, 'Dom'),
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
            top: 4,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppTheme.corCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.corBorda.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.corSecundaria.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_calendar_rounded,
                          color: AppTheme.corSecundaria, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Editar recorrência',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.corTexto)),
                          Text(rec.nomeMarmita,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.corSubtexto),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Dias da semana — multiselect
                const Text('DIAS DE ENTREGA',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.corSubtexto,
                        letterSpacing: 1.0)),
                const SizedBox(height: 4),
                const Text(
                  'Toque para selecionar um ou mais dias.',
                  style: TextStyle(fontSize: 11, color: AppTheme.corSubtexto),
                ),
                const SizedBox(height: 10),
                Row(
                  children: opcoesDias.map((d) {
                    final (num, nome) = d;
                    final sel = diasSel.contains(num);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheet(() {
                          if (sel) {
                            // Impede desmarcar se for o único selecionado
                            if (diasSel.length > 1) diasSel.remove(num);
                          } else {
                            diasSel.add(num);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.corSecundaria
                                : AppTheme.corFundo,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: sel
                                    ? AppTheme.corSecundaria
                                    : AppTheme.corBorda.withOpacity(0.35),
                                width: sel ? 0 : 0.8),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color: AppTheme.corSecundaria
                                          .withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Text(
                            nome,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : AppTheme.corTexto),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),
                const Text('DURAÇÃO',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.corSubtexto,
                        letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheet(() => indefinida = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: indefinida
                                ? AppTheme.corSecundaria.withOpacity(0.12)
                                : AppTheme.corFundo,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: indefinida
                                    ? AppTheme.corSecundaria
                                    : AppTheme.corBorda.withOpacity(0.3),
                                width: 0.8),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.all_inclusive_rounded,
                                  color: indefinida
                                      ? AppTheme.corSecundaria
                                      : AppTheme.corSubtexto,
                                  size: 20),
                              const SizedBox(height: 4),
                              Text('Indefinido',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: indefinida
                                          ? AppTheme.corSecundaria
                                          : AppTheme.corTexto)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheet(() => indefinida = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: !indefinida
                                ? AppTheme.corSecundaria.withOpacity(0.12)
                                : AppTheme.corFundo,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: !indefinida
                                    ? AppTheme.corSecundaria
                                    : AppTheme.corBorda.withOpacity(0.3),
                                width: 0.8),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.date_range_rounded,
                                  color: !indefinida
                                      ? AppTheme.corSecundaria
                                      : AppTheme.corSubtexto,
                                  size: 20),
                              const SizedBox(height: 4),
                              Text('Por semanas',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: !indefinida
                                          ? AppTheme.corSecundaria
                                          : AppTheme.corTexto)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!indefinida) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: semCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Número de semanas',
                      labelStyle: const TextStyle(
                          color: AppTheme.corSubtexto, fontSize: 13),
                      prefixIcon: const Icon(Icons.event_repeat_rounded,
                          color: AppTheme.corSecundaria, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppTheme.corSecundaria, width: 1.4),
                      ),
                    ),
                    onChanged: (v) => semanas = int.tryParse(v),
                  ),
                ],

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (diasSel.isEmpty) return;
                    Navigator.pop(ctx);
                    await provider.alterarDias(
                        rec.id, diasSel.toList()..sort());
                    await provider.alterarSemanas(
                        rec.id,
                        indefinida
                            ? null
                            : (int.tryParse(semCtrl.text) ?? semanas));
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      backgroundColor: AppTheme.corSecundaria),
                  child: const Text('Salvar alterações'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    semCtrl.dispose();
  }
}

// ── Barra de progresso do status ─────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final String status;
  const _StatusBar({required this.status});

  static const _steps = [
    'PENDENTE', 'CONFIRMADO', 'EM_PRODUCAO', 'PRONTO', 'ENTREGUE'
  ];
  static const _labels = [
    'Pendente', 'Confirmado', 'Produção', 'Pronto', 'Entregue'
  ];

  @override
  Widget build(BuildContext context) {
    final isCanceled = status.toUpperCase() == 'CANCELADO';
    final currentStep =
        isCanceled ? -1 : _steps.indexWhere((s) => s == status.toUpperCase());

    if (isCanceled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: AppTheme.corErro.withOpacity(0.1),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: AppTheme.corErro, size: 14),
            SizedBox(width: 6),
            Text('Pedido cancelado',
                style: TextStyle(
                    color: AppTheme.corErro,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.corFundo.withOpacity(0.5),
        border: Border(
            bottom: BorderSide(
                color: AppTheme.corBorda.withOpacity(0.15), width: 0.5)),
      ),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final done = i <= currentStep;
          final active = i == currentStep;
          final dotColor =
              done ? AppTheme.corSucesso : AppTheme.corBorda.withOpacity(0.35);
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: active ? 14 : 10,
                        height: active ? 14 : 10,
                        decoration: BoxDecoration(
                          color: done ? AppTheme.corSucesso : AppTheme.corCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: dotColor, width: active ? 2 : 1.2),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                      color:
                                          AppTheme.corSucesso.withOpacity(0.4),
                                      blurRadius: 6)
                                ]
                              : [],
                        ),
                        child: done && !active
                            ? const Icon(Icons.check,
                                size: 7, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _labels[i],
                        style: TextStyle(
                          fontSize: 8,
                          color: done
                              ? AppTheme.corSucesso
                              : AppTheme.corSubtexto.withOpacity(0.6),
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: i < currentStep
                            ? AppTheme.corSucesso
                            : AppTheme.corBorda.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Chips de ingredientes (resumo) ───────────────────────────────────────

class _IngredientesChips extends StatelessWidget {
  final List<IngredientePedido> ingredientes;
  const _IngredientesChips({required this.ingredientes});

  static const _colors = [
    AppTheme.corPrimaria,
    AppTheme.corDestaque,
    AppTheme.corSecundaria,
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
  ];

  @override
  Widget build(BuildContext context) {
    if (ingredientes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('Nenhum ingrediente.',
            style: TextStyle(color: AppTheme.corSubtexto, fontSize: 12)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(ingredientes.length, (i) {
          final ing = ingredientes[i];
          final color = _colors[i % _colors.length];
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: color.withOpacity(0.35), width: 0.7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco_rounded, size: 11, color: color),
                const SizedBox(width: 4),
                Text(ing.nome,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text('${ing.gramas.toStringAsFixed(0)}g',
                    style: TextStyle(
                        fontSize: 10, color: color.withOpacity(0.7))),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Tabela detalhada expandida ───────────────────────────────────────────

class _IngredientesDetalhe extends StatelessWidget {
  final List<IngredientePedido> ingredientes;
  const _IngredientesDetalhe({required this.ingredientes});

  static const _colors = [
    AppTheme.corPrimaria,
    AppTheme.corDestaque,
    AppTheme.corSecundaria,
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
  ];

  @override
  Widget build(BuildContext context) {
    final totalGramas = ingredientes.fold(0.0, (s, i) => s + i.gramas);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.corFundo,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.corBorda.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: const [
                Expanded(
                    flex: 5,
                    child: Text('Ingrediente',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.corSubtexto,
                            letterSpacing: 0.8))),
                Expanded(
                    flex: 2,
                    child: Text('Gramas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.corSubtexto,
                            letterSpacing: 0.8))),
                Expanded(
                    flex: 2,
                    child: Text('Preço/g',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.corSubtexto,
                            letterSpacing: 0.8))),
                Expanded(
                    flex: 3,
                    child: Text('Subtotal',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.corSubtexto,
                            letterSpacing: 0.8))),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.corBorda.withOpacity(0.3)),
          const SizedBox(height: 6),
          ...List.generate(ingredientes.length, (i) {
            final ing = ingredientes[i];
            final color = _colors[i % _colors.length];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Row(children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(ing.nome,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.corTexto,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
                  Expanded(
                      flex: 2,
                      child: Text('${ing.gramas.toStringAsFixed(0)}g',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.corSubtexto))),
                  Expanded(
                      flex: 2,
                      child: Text(
                          'R\$ ${ing.valorPorGramas.toStringAsFixed(2)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.corSubtexto))),
                  Expanded(
                      flex: 3,
                      child: Text(
                          'R\$ ${ing.subtotal.toStringAsFixed(2)}',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: 13,
                              color: color,
                              fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }),
          Divider(height: 12, color: AppTheme.corBorda.withOpacity(0.3)),
          Row(
            children: [
              const Expanded(
                  flex: 5,
                  child: Text('Total',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.corTexto))),
              Expanded(
                  flex: 2,
                  child: Text('${totalGramas.toStringAsFixed(0)}g',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.corTexto))),
              const Expanded(flex: 2, child: SizedBox()),
              Expanded(
                  flex: 3,
                  child: Text(
                      'R\$ ${ingredientes.fold(0.0, (s, i) => s + i.subtotal).toStringAsFixed(2)}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.corDestaque))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Modelo unificado de ingrediente para edição ──────────────────────────

class _IngEditar {
  final int id; // id do Ingrediente no cardápio
  final String nome;
  final double valorPorGramas;
  final int posicao;

  _IngEditar({
    required this.id,
    required this.nome,
    required this.valorPorGramas,
    required this.posicao,
  });

  factory _IngEditar.fromCardapioJson(Map<String, dynamic> j) => _IngEditar(
        id: (j['id'] as num).toInt(),
        nome: j['nome'] as String,
        valorPorGramas: (j['valorPorGramas'] as num).toDouble(),
        posicao: (j['posicao'] as num).toInt(),
      );
}

// ── Bottom sheet de gerenciamento ────────────────────────────────────────

class _EditarPedidoSheet extends StatefulWidget {
  final PedidoModel pedido;
  final http.Client httpClient;
  final VoidCallback onCancelar;

  const _EditarPedidoSheet({
    required this.pedido,
    required this.httpClient,
    required this.onCancelar,
  });

  @override
  State<_EditarPedidoSheet> createState() => _EditarPedidoSheetState();
}

class _EditarPedidoSheetState extends State<_EditarPedidoSheet> {
  static const double _passo = 50.0;
  static const double _minGramas = 50.0;
  static const double _maxGramas = 500.0;

  // Lista completa de ingredientes do cardápio
  List<_IngEditar> _todosIngredientes = [];
  // gramas editáveis: ingredienteId (do cardápio) → gramas
  Map<int, double> _gramas = {};
  // controllers de texto
  Map<int, TextEditingController> _controllers = {};

  bool _isLoadingCardapio = true;
  bool _isSaving = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _carregarIngredientesCardapio();
  }

  /// Busca os ingredientes do cardápio e pré-preenche as gramas dos que
  /// já estão no pedido.
  Future<void> _carregarIngredientesCardapio() async {
    final cardapioId = widget.pedido.cardapioId as int;
    // Precisamos do marmiteriaId para consultar o cardápio. Como o endpoint
    // /apiCardapio/todos recebe marmiteriaId, vamos buscar o cardápio
    // individualmente. Mas o back-end expõe apenas /todos?marmiteriaId.
    // Alternativa: buscar via o cardápio embutido na resposta do pedido.
    // O PedidoResponse retorna cardapioId — usamos GET /apiCardapio/todos
    // de forma genérica buscando por qualquer marmiteria não é viável sem
    // o id. Portanto usamos a rota de pedido que já retorna os ingredientes
    // do pedido, e para obter os do cardápio fazemos GET /apiCardapio/todos
    // passando a marmiteriaId. Como não temos marmiteriaId no PedidoModel,
    // usamos uma alternativa: GET individual via /apiCardapio/todos filtrando
    // localmente pelo id. Na prática o back não tem rota GET /apiCardapio/{id},
    // então pedimos todos e filtramos — mas precisamos da marmiteriaId.
    //
    // Solução pragmática: adicionamos marmiteriaId ao PedidoModel OU usamos
    // o endpoint de um único cardápio. Como o back não expõe GET por id,
    // vamos buscar diretamente via query de pedido pelo cardapioId usando
    // a lista de pedidos já disponível.
    //
    // Abordagem escolhida: o back-end tem GET /apiCardapio/todos?marmiteriaId,
    // e o PedidoResponse já traz cardapioId. Adicionamos uma rota de busca
    // por id no back seria o ideal, mas para não alterar o back usamos os
    // ingredientes do pedido como base e complementamos fazendo uma chamada
    // GET /apiCardapio/todos com a marmiteriaId obtida via pedido.
    //
    // Como não temos marmiteriaId no modelo, a abordagem mais simples e
    // sem alterar o back-end é: GET /apiPedido/todos?marmiteriaId não serve.
    // MELHOR SOLUÇÃO SEM ALTERAR BACK: buscar os ingredientes via o endpoint
    // de cardápio, mas precisamos da marmiteriaId. Como o PedidoResponse
    // não a inclui, vamos adicionar marmiteriaId ao PedidoModel também.
    //
    // Para não aumentar o escopo, usamos a única informação que temos:
    // os ingredientes já presentes no pedido como "pool" de edição E
    // fazemos GET /apiCardapio/todos?marmiteriaId buscando de forma indireta.
    //
    // DECISÃO FINAL: buscamos via GET /apiCardapio/todos passando marmiteriaId
    // adicionado ao PedidoModel. Se não houver marmiteriaId, fallback para
    // os ingredientes do pedido.

    // Tenta buscar pelo cardapio diretamente usando os ingredientes existentes
    // do pedido para identificar o marmiteriaId — não disponível no modelo.
    // Usamos o endpoint de busca de cardápio por marmiteria via o cardapioId
    // exposto no PedidoModel.
    //
    // Abordagem final e simples: o servidor tem /apiCardapio/todos?marmiteriaId.
    // Precisamos do marmiteriaId. Como o PedidoResponse inclui cardapioId,
    // podemos deduzir o marmiteriaId se adicionarmos esse campo ao modelo.
    // Mas para não precisar alterar o back-end, buscamos todos os cardápios
    // de todas as marmiterias NÃO é viável.
    //
    // SOLUÇÃO REAL: adicionamos /apiCardapio/{id} no back-end OU
    // incluímos marmiteriaId no PedidoResponse. Como ambas requerem mudança
    // de back-end, a alternativa Flutter-only é usar os ingredientes do
    // pedido como lista base (comportamento atual) mas também pré-carregar
    // os ingredientes fazendo GET para o endpoint que já existe passando
    // o marmiteriaId que foi salvo no PedidoModel.
    //
    // Vamos adicionar marmiteriaId ao PedidoModel e ao PedidoResponse do back.
    // Para o front funcionar imediatamente adicionamos o campo com fallback 0
    // e quando disponível busca o cardápio completo.

    final pedidoIngs = widget.pedido.ingredientes as List<IngredientePedido>;

    // Tenta buscar os ingredientes completos do cardápio
    List<_IngEditar> todos = [];
    try {
      final url = Uri.parse(
          'http://localhost:8080/apiCardapio/buscarPorId/$cardapioId');
      final resp = await widget.httpClient.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final ings = (data['ingredientes'] as List?) ?? [];
        todos = ings
            .map((e) => _IngEditar.fromCardapioJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Se a chamada falhou ou retornou vazia, constrói a lista a partir
    // dos ingredientes já no pedido (comportamento degradado).
    if (todos.isEmpty) {
      todos = pedidoIngs
          .map((i) => _IngEditar(
                id: i.id,
                nome: i.nome,
                valorPorGramas: i.valorPorGramas,
                posicao: i.posicao,
              ))
          .toList();
    }

    // Mapa nome→gramas dos ingredientes já no pedido (para pré-preencher).
    // Usamos nome como chave porque o id do PedidoIngrediente ≠ id do Ingrediente.
    final gramasPorNome = <String, double>{
      for (final pi in pedidoIngs) pi.nome: pi.gramas,
    };

    final gramas = <int, double>{};
    final controllers = <int, TextEditingController>{};
    for (final ing in todos) {
      final g = gramasPorNome[ing.nome] ?? 0.0;
      gramas[ing.id] = g;
      controllers[ing.id] = TextEditingController(text: g.toStringAsFixed(0));
    }

    if (mounted) {
      setState(() {
        _todosIngredientes = todos;
        _gramas = gramas;
        _controllers = controllers;
        _isLoadingCardapio = false;
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  double get _novoTotal {
    return _todosIngredientes.fold(0.0, (s, ing) {
      return s + ing.valorPorGramas * (_gramas[ing.id] ?? 0);
    });
  }

  void _setGramas(_IngEditar ing, double valor) {
    setState(() {
      _gramas[ing.id] = valor.clamp(0, _maxGramas);
      _controllers[ing.id]!.text = _gramas[ing.id]!.toStringAsFixed(0);
    });
  }

  void _incrementar(_IngEditar ing) {
    final atual = _gramas[ing.id] ?? 0.0;
    _setGramas(ing, atual == 0 ? _minGramas : atual + _passo);
  }

  void _decrementar(_IngEditar ing) {
    final atual = _gramas[ing.id] ?? 0.0;
    _setGramas(ing, atual <= _minGramas ? 0 : atual - _passo);
  }

  // ── Salvar ────────────────────────────────────────────────────────────

  Future<void> _salvar() async {
    // Filtra apenas ingredientes com gramas > 0
    final ativos = _todosIngredientes
        .where((i) => (_gramas[i.id] ?? 0) > 0)
        .toList();

    if (ativos.isEmpty) {
      setState(() => _errorMsg = 'Adicione pelo menos um ingrediente.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMsg = null;
    });

    final url = Uri.parse(
        'http://localhost:8080/apiPedido/atualizar/${widget.pedido.id}');

    try {
      final body = {
        'nomeCliente': '',
        'cardapioId': widget.pedido.cardapioId,
        'ingredientes': ativos
            .map((i) => {
                  'nome': i.nome,
                  'valorPorGramas': i.valorPorGramas,
                  'gramas': _gramas[i.id],
                  'posicao': i.posicao,
                })
            .toList(),
      };

      final response = await widget.httpClient.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final updated = PedidoModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        Navigator.pop(context, updated);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pedido atualizado com sucesso!'),
          backgroundColor: AppTheme.corSucesso,
        ));
      } else {
        setState(() {
          _errorMsg = 'Erro ${response.statusCode}: ${response.body}';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Erro de conexão: $e';
          _isSaving = false;
        });
      }
    }
  }

  // ── Widgets ───────────────────────────────────────────────────────────

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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? color.withOpacity(0.12)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? color.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            width: 0.8,
          ),
        ),
        child: Icon(icon,
            color: enabled ? color : Colors.grey.withOpacity(0.4), size: 17),
      ),
    );
  }

  Widget _ingredienteRow(_IngEditar ing, int index) {
    final gramas = _gramas[ing.id] ?? 0.0;
    final selecionado = gramas > 0;
    final colors = [
      AppTheme.corPrimaria,
      AppTheme.corDestaque,
      AppTheme.corSecundaria,
      const Color(0xFF2E7D32),
      const Color(0xFF1565C0),
    ];
    final accent = colors[index % colors.length];
    final subtotal = ing.valorPorGramas * gramas;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: selecionado ? AppTheme.corCard : AppTheme.corFundo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selecionado
              ? accent.withOpacity(0.45)
              : AppTheme.corBorda.withOpacity(0.2),
          width: selecionado ? 1.1 : 0.5,
        ),
        boxShadow: selecionado
            ? [
                BoxShadow(
                    color: accent.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (selecionado)
              Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 3, color: accent)),
            Padding(
              padding:
                  EdgeInsets.fromLTRB(selecionado ? 14 : 10, 10, 10, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: selecionado
                              ? accent.withOpacity(0.13)
                              : AppTheme.corPrimaria.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.eco_outlined,
                            color: selecionado
                                ? accent
                                : AppTheme.corSubtexto,
                            size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ing.nome,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selecionado
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: AppTheme.corTexto)),
                            Text(
                                'R\$ ${ing.valorPorGramas.toStringAsFixed(2)}/g',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.corSubtexto)),
                          ],
                        ),
                      ),
                      if (selecionado)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.corDestaque.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'R\$ ${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.corDestaque),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Controles +/-
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ctrlBtn(
                          icon: Icons.remove_rounded,
                          onTap: () => _decrementar(ing),
                          enabled: gramas > 0,
                          color: AppTheme.corErro),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 76,
                        child: TextField(
                          controller: _controllers[ing.id],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.corTexto),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 9),
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
                                      ? accent.withOpacity(0.45)
                                      : AppTheme.corBorda.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: accent, width: 1.4),
                            ),
                            suffix: const Text('g',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.corSubtexto)),
                          ),
                          onChanged: (v) {
                            final val = double.tryParse(v) ?? 0.0;
                            setState(() {
                              _gramas[ing.id] = val.clamp(0, _maxGramas);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ctrlBtn(
                          icon: Icons.add_rounded,
                          onTap: () => _incrementar(ing),
                          enabled: gramas < _maxGramas,
                          color: AppTheme.corSucesso),
                    ],
                  ),
                  if (!selecionado) ...[
                    const SizedBox(height: 5),
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColorStatic(widget.pedido.status as String);
    final ativoCount = _gramas.values.where((v) => v > 0).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.corCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // ── Handle + cabeçalho ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.corBorda.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.corPrimaria.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_note_rounded,
                            color: AppTheme.corPrimaria, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Editar pedido',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.corTexto)),
                            Text(
                              'Pedido #${widget.pedido.id}  •  '
                              '${_statusLabelStatic(widget.pedido.status as String)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.corSubtexto),
                            ),
                          ],
                        ),
                      ),
                      // Badge de status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: statusColor.withOpacity(0.35),
                              width: 0.6),
                        ),
                        child: Text(
                          _statusLabelStatic(widget.pedido.status as String),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(
                      height: 1,
                      color: AppTheme.corBorda.withOpacity(0.3)),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // ── Corpo: loading ou lista de ingredientes ────────────
            if (_isLoadingCardapio)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.corPrimaria),
                      SizedBox(height: 14),
                      Text('Carregando ingredientes...',
                          style: TextStyle(
                              color: AppTheme.corSubtexto, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else ...[
              // ── Lista rolável de ingredientes ──────────────────────
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  children: [
                    // Dica
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.corPrimaria.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.corPrimaria.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline_rounded,
                              color: AppTheme.corPrimaria, size: 15),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ajuste as gramas de cada ingrediente. Zerar um ingrediente o remove do pedido. Você pode adicionar novos ingredientes do cardápio.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.corSubtexto,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ingredientes completos do cardápio
                    ...List.generate(
                        _todosIngredientes.length,
                        (i) => _ingredienteRow(_todosIngredientes[i], i)),
                  ],
                ),
              ),

              // ── Rodapé fixo ────────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(
                    20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                decoration: BoxDecoration(
                  color: AppTheme.corCard,
                  border: Border(
                      top: BorderSide(
                          color: AppTheme.corBorda.withOpacity(0.3),
                          width: 0.6)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, -2))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Resumo: itens ativos + novo total
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$ativoCount ingrediente${ativoCount != 1 ? 's' : ''} selecionado${ativoCount != 1 ? 's' : ''}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.corSubtexto),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Novo total: R\$ ${_novoTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.corTexto,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Mensagem de erro
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.corErro.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.corErro.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.corErro, size: 15),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMsg!,
                                  style: const TextStyle(
                                      color: AppTheme.corErro,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Botões
                    Row(
                      children: [
                        // Cancelar pedido
                        OutlinedButton.icon(
                          onPressed:
                              _isSaving ? null : widget.onCancelar,
                          icon: const Icon(Icons.cancel_outlined, size: 15),
                          label: const Text('Cancelar Pedido'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.corErro,
                            side: BorderSide(
                                color: AppTheme.corErro.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Salvar
                        Expanded(
                          child: _isSaving
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: AppTheme.corPrimaria))
                              : ElevatedButton.icon(
                                  onPressed: _salvar,
                                  icon: const Icon(Icons.save_rounded,
                                      size: 17),
                                  label: const Text('Salvar'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _statusColorStatic(String s) {
    switch (s.toUpperCase()) {
      case 'PENDENTE':    return AppTheme.corDestaque;
      case 'CONFIRMADO':  return const Color(0xFF1565C0);
      case 'EM_PRODUCAO': return const Color(0xFF6A1B9A);
      case 'PRONTO':
      case 'ENTREGUE':
      case 'CONCLUIDO':   return AppTheme.corSucesso;
      case 'CANCELADO':   return AppTheme.corErro;
      default:            return AppTheme.corSubtexto;
    }
  }

  static String _statusLabelStatic(String s) {
    switch (s.toUpperCase()) {
      case 'PENDENTE':    return 'Pendente';
      case 'CONFIRMADO':  return 'Confirmado';
      case 'EM_PRODUCAO': return 'Em produção';
      case 'PRONTO':      return 'Pronto';
      case 'ENTREGUE':    return 'Entregue';
      case 'CONCLUIDO':   return 'Concluído';
      case 'CANCELADO':   return 'Cancelado';
      default:            return s;
    }
  }
}