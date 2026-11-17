import 'package:flutter/material.dart';
import '../../configuracoes/tema_app.dart';
import '../../servicos/api_servico.dart';
import '../../servicos/formatadores.dart';

typedef DashboardPage = TelaDashboard;

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  late Future<Map<String, dynamic>> _dadosFuture;
  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();
    _dadosFuture = buscarDadosDashboard();
  }

  Future<void> _executarSyncManual() async {
    setState(() => _sincronizando = true);
    try {
      final res = await sincronizarPncpAgora();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['mensagem']?.toString() ?? 'Sincronização concluída.'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      setState(() {
        _dadosFuture = buscarDadosDashboard();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Text('${snapshot.error}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => setState(() => _dadosFuture = buscarDadosDashboard()),
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
        final mensagemAlerta = dados['alerta']?.toString() ?? 'Sem alertas no momento.';
        final volumePorUf = (dados['volumePorUf'] as List<dynamic>?) ?? [];
        final ultimas = (dados['ultimasOportunidades'] as List<dynamic>?) ?? [];

        final maxQtd = volumePorUf.fold<int>(
          1,
          (max, item) => ((item['quantidade'] as num?)?.toInt() ?? 0) > max
              ? (item['quantidade'] as num).toInt()
              : max,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Olá, ${SessaoUsuario.nomeUsuario}!',
                    style: const TextStyle(
                      fontFamily: TemaApp.fonteSerifada,
                      fontFamilyFallback: TemaApp.fallbackSerifada,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _sincronizando ? null : _executarSyncManual,
                    icon: _sincronizando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: Text(_sincronizando ? 'Sincronizando PNCP...' : 'Sincronizar PNCP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004CA3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  border: Border.all(color: const Color(0xFFFDE047)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFCA8A04)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mensagemAlerta,
                        style: const TextStyle(color: Color(0xFF854D0E), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _buildKpiCard('Licitações Ativas (PNCP):', licitacoesAtivas),
                  const SizedBox(width: 24),
                  _buildKpiCard('Disputas Ganhas (Empresa):', disputasGanhas),
                ],
              ),
              const SizedBox(height: 28),
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
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Distribuição de Licitações por Estado (UF)',
                            style: TextStyle(
                              fontFamily: TemaApp.fonteSerifada,
                              fontFamilyFallback: TemaApp.fallbackSerifada,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (volumePorUf.isEmpty)
                            const SizedBox(
                              height: 200,
                              child: Center(child: Text('Aguardando primeira sincronização do PNCP.')),
                            )
                          else
                            SizedBox(
                              height: 220,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: volumePorUf.map((ponto) {
                                  final qtd = (ponto['quantidade'] as num?)?.toInt() ?? 0;
                                  final uf = ponto['label']?.toString() ?? '-';
                                  final altura = (qtd / maxQtd) * 165.0;
                                  return _buildBarraGrafico(altura < 12 ? 12 : altura, '$uf ($qtd)');
                                }).toList(),
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
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Últimas Oportunidades Importadas',
                            style: TextStyle(
                              fontFamily: TemaApp.fonteSerifada,
                              fontFamilyFallback: TemaApp.fallbackSerifada,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (ultimas.isEmpty)
                            const Text('Nenhuma licitação importada ainda.', style: TextStyle(color: Colors.black54))
                          else
                            for (int i = 0; i < ultimas.length; i++) ...[
                              _buildItemRecente(ultimas[i] as Map<String, dynamic>),
                              if (i < ultimas.length - 1) const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            ],
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(valor, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraGrafico(double altura, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 34,
          height: altura,
          decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildItemRecente(Map<String, dynamic> item) {
    final orgao = item['orgao']?.toString() ?? 'Órgão Público';
    final modalidade = item['modalidade']?.toString() ?? '';
    final edital = item['numeroEdital']?.toString() ?? '';
    final uf = item['uf']?.toString() ?? '';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.account_balance, color: Color(0xFF2563EB), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orgao,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 3),
              Text(
                '$modalidade $edital ${uf.isNotEmpty ? "• $uf" : ""}',
                style: const TextStyle(color: Colors.black54, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}