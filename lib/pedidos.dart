import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/pedido_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pedido extends StatefulWidget {
  const Pedido({super.key});

  @override
  State<Pedido> createState() => _PedidoState();
}

class _PedidoState extends State<Pedido> {
  final _httpClient = http.Client();
  final _scrollController = ScrollController();

  List<PedidoModel> _pedidos = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _pedirPedido();
  }

  Future<void> _pedirPedido() async {
    final url = Uri.parse('http://localhost:8080/apiPedido/pedidos');
    //try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body:
            jsonEncode({'username': username, 'password': 'empty'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pedidos = List<PedidoModel>.from(
    (data as List).map((e) => PedidoModel.fromJson(e as Map<String, dynamic>))
);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg = 'Erro ${response.statusCode}';
          _isLoading = false;
        });
    //  }
   // } catch (e) {
    //  print(e);
   //   setState(() {
     //   _errorMsg = e.toString();
       // _isLoading = false;
    //  });
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return AppTheme.corDestaque;
      case 'CONCLUIDO':
      case 'ENTREGUE':
        return AppTheme.corSucesso;
      case 'CANCELADO':
        return AppTheme.corErro;
      default:
        return AppTheme.corSubtexto;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return Icons.pending_actions_rounded;
      case 'CONCLUIDO':
      case 'ENTREGUE':
        return Icons.check_circle_outline_rounded;
      case 'CANCELADO':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Widget _buildPedido(PedidoModel pedido) {
    final statusColor = _statusColor(pedido.status as String);

    String dataCriadaFmt = '';
    String dataPedidoFmt = '';
    try {
      final dc = pedido.dataCriada as DateTime;
      final dp = pedido.dataPedido as DateTime;
      dataCriadaFmt =
          '${dc.day.toString().padLeft(2, '0')}/${dc.month.toString().padLeft(2, '0')}/${dc.year}';
      dataPedidoFmt =
          '${dp.day.toString().padLeft(2, '0')}/${dp.month.toString().padLeft(2, '0')}/${dp.year}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.corCard,
        borderRadius: BorderRadius.circular(14),
        // Uniform border so borderRadius is valid
        border: Border.all(
          color: AppTheme.corBorda.withOpacity(0.25),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.corPrimaria.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Left accent bar replacing the non-uniform left border
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: statusColor),
            ),
            Padding(
              // Extra left padding to account for the accent bar
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cabeçalho do card ──────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.corPrimaria.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store_rounded,
                            color: AppTheme.corPrimaria, size: 18),
                      ),
                      const SizedBox(width: 10),
                      // Expanded(
                      //   child: Text(
                      //     pedido.nomeMarmiteria as String,
                      //     style: const TextStyle(
                      //       fontSize: 16,
                      //       fontWeight: FontWeight.bold,
                      //       color: AppTheme.corTexto,
                      //     ),
                      //   ),
                      // ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                            const SizedBox(width: 4),
                            Text(
                              pedido.status as String,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(
                      height: 1,
                      color: AppTheme.corBorda.withOpacity(0.25)),
                  const SizedBox(height: 12),

                  // ── Datas ──────────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppTheme.corSubtexto),
                      const SizedBox(width: 6),
                      Text(
                        'Criado: $dataCriadaFmt',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.corSubtexto),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppTheme.corSubtexto),
                      const SizedBox(width: 6),
                      Text(
                        'Entrega: $dataPedidoFmt',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.corSubtexto),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Ingredientes ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.restaurant_menu_rounded,
                          size: 14, color: AppTheme.corSubtexto),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (pedido.ingredientes as List<dynamic>).join(', '),
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.corTexto, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Valor ──────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.corDestaque.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.corDestaque.withOpacity(0.3),
                              width: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_money_rounded,
                                size: 16, color: AppTheme.corDestaque),
                            Text(
                              'R\$ ${(pedido.valor as double).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.corDestaque,
                              ),
                            ),
                          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pedidos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.corTexto,
                        ),
                      ),
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
          const SizedBox(height: 8),

          // ── Conteúdo ─────────────────────────────────────────────
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
                            Text(
                              _errorMsg!,
                              style: const TextStyle(
                                  color: AppTheme.corSubtexto,
                                  fontSize: 14),
                            ),
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
                      )
                    : _pedidos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 52,
                                    color: AppTheme.corPrimaria
                                        .withOpacity(0.3)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Nenhum pedido encontrado.',
                                  style: TextStyle(
                                      color: AppTheme.corSubtexto,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _pedidos.length,
                            itemBuilder: (_, i) =>
                                _buildPedido(_pedidos[i]),
                          ),
          ),
        ],
      ),
    );
  }
}