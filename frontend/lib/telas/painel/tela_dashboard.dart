import 'package:flutter/material.dart';
import '../../configuracoes/tema_app.dart';
import '../../servicos/api_servico.dart';
import '../../servicos/formatadores.dart';

typedef DashboardPage = TelaDashboard;

/// Aba 1: Dashboard de indicadores (KPIs), alertas e gráficos conectado à API C#.
class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  late Future<Map<String, dynamic>> _dadosFuture;

  @override
  void initState() {
    super.initState();
    _dadosFuture = buscarDadosDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dadosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.black38),
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível carregar os indicadores.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _dadosFuture = buscarDadosDashboard();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final dados = snapshot.data ?? {};
        final licitacoesAtivas = dados['licitacoesAtivas']?.toString() ?? '0';
        final disputasGanhas = formatarMoeda(dados['disputasGanhas']);
        final mensagemAlerta =
            dados['alerta']?.toString() ?? 'Sem alertas de momento.';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Olá, Carlos Eduardo!',
                    style: TextStyle(
                      fontFamily: TemaApp.fonteSerifada,
                      fontFamilyFallback: TemaApp.fallbackSerifada,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  border: Border.all(color: const Color(0xFFFDE047)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFCA8A04),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      mensagemAlerta,
                      style: const TextStyle(
                        color: Color(0xFF854D0E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  _buildKpiCard('Licitações Ativas:', licitacoesAtivas),
                  const SizedBox(width: 24),
                  _buildKpiCard('Disputas Ganhas:', disputasGanhas),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Volume das licitações',
                            style: TextStyle(
                              fontFamily: TemaApp.fonteSerifada,
                              fontFamilyFallback: TemaApp.fallbackSerifada,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 240,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildBarraGrafico(100, 'Nov'),
                                _buildBarraGrafico(160, 'Dez'),
                                _buildBarraGrafico(130, 'Jan'),
                                _buildBarraGrafico(110, 'Fev'),
                                _buildBarraGrafico(150, 'Mar'),
                                _buildBarraGrafico(190, 'Abr'),
                                _buildBarraGrafico(120, 'Mai'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Últimas Oportunidades',
                            style: TextStyle(
                              fontFamily: TemaApp.fonteSerifada,
                              fontFamilyFallback: TemaApp.fallbackSerifada,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildListaOportunidade(
                            Icons.account_balance,
                            Colors.orange,
                            'Prefeitura de SP',
                            'Pregão 48/2026',
                          ),
                          const Divider(height: 32, color: Color(0xFFF1F5F9)),
                          _buildListaOportunidade(
                            Icons.local_hospital,
                            Colors.teal,
                            'Hospital das Clínicas',
                            'Pregão 15/2026',
                            tag: '75% completo',
                          ),
                          const Divider(height: 32, color: Color(0xFFF1F5F9)),
                          _buildListaOportunidade(
                            Icons.account_balance,
                            Colors.blue,
                            'Governo do Estado de SP',
                            'Pregão 12/2026',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String titulo, String valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraGrafico(double altura, String mes) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: altura,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(mes, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }

  Widget _buildListaOportunidade(
    IconData icone,
    Color corIcone,
    String orgao,
    String pregao, {
    String? tag,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: corIcone.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, color: corIcone, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orgao,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    pregao,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  if (tag != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.black26),
      ],
    );
  }
}
