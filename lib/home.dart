import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/marmiteria.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<String> _imgList = [
    'assets/images/a.png',
    'assets/images/b.png',
  ];

  int _currentSlide = 0;

  // ── Marmiterias ──────────────────────────────────────────────────────────
  List<MarmiteriaModel> _marmiterias = [];
  bool _loadingMarmiterias = true;
  String? _errorMarmiterias;

  @override
  void initState() {
    super.initState();
    _carregarMarmiterias();
  }

  Future<void> _carregarMarmiterias() async {
    final url = Uri.parse('http://localhost:8080/apiMarmiteria/todos');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body) as List;
        if (mounted) {
          setState(() {
            _marmiterias = data
                .map((e) => MarmiteriaModel.fromJson(e as Map<String, dynamic>))
                .toList();
            _loadingMarmiterias = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMarmiterias = 'Erro ${response.statusCode}';
            _loadingMarmiterias = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMarmiterias = e.toString();
          _loadingMarmiterias = false;
        });
      }
    }
  }

  void _abrirMarmiteria(MarmiteriaModel marmiteria) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Marmiteria(marmiteria: marmiteria),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _marmiteriaCard(MarmiteriaModel marmiteria, int index) {
    final colors = [
      AppTheme.corPrimaria,
      AppTheme.corDestaque,
      AppTheme.corSecundaria,
    ];
    final accent = colors[index % colors.length];

    return GestureDetector(
      onTap: () => _abrirMarmiteria(marmiteria),
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
              // Barra lateral colorida
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: accent),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    // Ícone da loja
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.store_rounded, color: accent, size: 26),
                    ),
                    const SizedBox(width: 14),
                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            marmiteria.nome,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.corTexto,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Badge de status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: marmiteria.status
                                      ? AppTheme.corSucesso.withOpacity(0.12)
                                      : AppTheme.corErro.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: marmiteria.status
                                        ? AppTheme.corSucesso.withOpacity(0.4)
                                        : AppTheme.corErro.withOpacity(0.4),
                                    width: 0.6,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      marmiteria.status
                                          ? Icons.check_circle_outline
                                          : Icons.cancel_outlined,
                                      size: 11,
                                      color: marmiteria.status
                                          ? AppTheme.corSucesso
                                          : AppTheme.corErro,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      marmiteria.status ? 'Aberto' : 'Fechado',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: marmiteria.status
                                            ? AppTheme.corSucesso
                                            : AppTheme.corErro,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (marmiteria.telefone != null &&
                                  marmiteria.telefone!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.phone_outlined,
                                    size: 11, color: AppTheme.corSubtexto),
                                const SizedBox(width: 3),
                                Text(
                                  marmiteria.telefone!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.corSubtexto),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Seta
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: accent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _marmiteriasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da seção
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.corPrimaria.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store_mall_directory_rounded,
                    color: AppTheme.corPrimaria, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marmiterias',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.corTexto,
                      ),
                    ),
                    Text(
                      'Escolha onde pedir sua marmita',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.corSubtexto),
                    ),
                  ],
                ),
              ),
              if (!_loadingMarmiterias && _marmiterias.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.corPrimaria.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_marmiterias.length}',
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

        // Conteúdo
        if (_loadingMarmiterias)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.corPrimaria),
            ),
          )
        else if (_errorMarmiterias != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.corErro.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.corErro.withOpacity(0.25), width: 0.6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: AppTheme.corErro, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMarmiterias ?? 'Erro desconhecido',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.corErro.withOpacity(0.8)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _loadingMarmiterias = true;
                        _errorMarmiterias = null;
                      });
                      _carregarMarmiterias();
                    },
                    child: const Text('Tentar novamente',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.corPrimaria)),
                  ),
                ],
              ),
            ),
          )
        else if (_marmiterias.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.store_outlined,
                      size: 40,
                      color: AppTheme.corPrimaria.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  const Text(
                    'Nenhuma marmiteria disponível.',
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.corSubtexto),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(
            _marmiterias.length,
            (i) => _marmiteriaCard(_marmiterias[i], i),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.corFundo,
      body: RefreshIndicator(
        color: AppTheme.corPrimaria,
        backgroundColor: AppTheme.corCard,
        onRefresh: _carregarMarmiterias,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // // ── Carrossel ────────────────────────────────────────────
              // CarouselSlider(
              //   options: CarouselOptions(
              //     autoPlay: true,
              //     enlargeCenterPage: true,
              //     height: 220,
              //     aspectRatio: 16 / 9,
              //     enableInfiniteScroll: true,
              //     scrollDirection: Axis.horizontal,
              //     viewportFraction: 0.88,
              //     autoPlayInterval: const Duration(seconds: 4),
              //     onPageChanged: (i, _) =>
              //         setState(() => _currentSlide = i),
              //   ),
              //   items: _imgList.map((item) {
              //     return ClipRRect(
              //       borderRadius: BorderRadius.circular(14),
              //       child: Image.asset(item, fit: BoxFit.cover),
              //     );
              //   }).toList(),
              // ),

              // // Indicadores do carrossel
              // const SizedBox(height: 12),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: _imgList.asMap().entries.map((entry) {
              //     return Container(
              //       width: _currentSlide == entry.key ? 20 : 7,
              //       height: 7,
              //       margin: const EdgeInsets.symmetric(horizontal: 3),
              //       decoration: BoxDecoration(
              //         color: _currentSlide == entry.key
              //             ? AppTheme.corPrimaria
              //             : AppTheme.corBorda.withOpacity(0.3),
              //         borderRadius: BorderRadius.circular(4),
              //       ),
              //     );
              //   }).toList(),
              // ),

              // const SizedBox(height: 28),

              // ── Banner principal ─────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.corPrimaria,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.corPrimaria.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lunch_dining_rounded,
                        color: Colors.white70, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'Se alimente bem de maneira\nrápida e prática.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Receba marmitas saudáveis, saborosas\ne balanceadas onde estiver.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 15,
                          height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Cards de destaque ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _featureCard(
                      icon: Icons.health_and_safety_outlined,
                      title: 'Saudável',
                      subtitle: 'Ingredientes\nselecionados',
                      color: AppTheme.corSucesso,
                    ),
                    const SizedBox(width: 12),
                    _featureCard(
                      icon: Icons.delivery_dining_outlined,
                      title: 'Prático',
                      subtitle: 'Entrega rápida\nonde estiver',
                      color: AppTheme.corDestaque,
                    ),
                    const SizedBox(width: 12),
                    _featureCard(
                      icon: Icons.star_outline_rounded,
                      title: 'Qualidade',
                      subtitle: 'Refeições\nbalanceadas',
                      color: AppTheme.corPrimaria,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Slogan final ─────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.corCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.corBorda.withOpacity(0.3), width: 0.6),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.corPrimaria.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite_outline_rounded,
                          color: AppTheme.corPrimaria, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'A saúde na palma da sua mão, sem complicação!',
                        style: TextStyle(
                          color: AppTheme.corTexto,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Divisor ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                    height: 1, color: AppTheme.corBorda.withOpacity(0.3)),
              ),

              const SizedBox(height: 20),

              // ── Seção de Marmiterias ──────────────────────────────────
              _marmiteriasSection(),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.corCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.corBorda.withOpacity(0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 3,
                color: color,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.corSubtexto,
                          height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}