import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../configuracoes/tema_app.dart';
import '../../modelos/edital.dart';
import '../../servicos/api_servico.dart';

typedef DetalhesEditalPage = TelaDetalhesEdital;

class TelaDetalhesEdital extends StatefulWidget {
  final Edital edital;
  final VoidCallback onBack;

  const TelaDetalhesEdital({
    super.key,
    required this.edital,
    required this.onBack,
  });

  @override
  State<TelaDetalhesEdital> createState() => _TelaDetalhesEditalState();
}

class _TelaDetalhesEditalState extends State<TelaDetalhesEdital> {
  late Future<Edital> _detalheFuture;
  bool _salvandoFunil = false;

  @override
  void initState() {
    super.initState();
    _detalheFuture = buscarDetalhesEdital(widget.edital);
  }

  Future<void> _adicionarAoFunil(Edital edital) async {
    setState(() => _salvandoFunil = true);
    try {
      await adicionarEditalAoFunil(edital.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Licitação adicionada ao Funil de Disputa com sucesso!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvandoFunil = false);
    }
  }

  Future<void> _copiarLinkOrigem(String? link) async {
    if (link == null || link.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link oficial do PNCP copiado: $link'),
        backgroundColor: const Color(0xFF004CA3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Edital>(
      future: _detalheFuture,
      initialData: widget.edital,
      builder: (context, snapshot) {
        final edital = snapshot.data ?? widget.edital;
        final carregandoItens = snapshot.connectionState == ConnectionState.waiting;

        return Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Detalhes do Edital',
                    style: TextStyle(
                      fontFamily: TemaApp.fonteSerifada,
                      fontFamilyFallback: TemaApp.fallbackSerifada,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${edital.titulo} — ${edital.orgao}',
                                style: const TextStyle(
                                  fontFamily: TemaApp.fonteSerifada,
                                  fontFamilyFallback: TemaApp.fallbackSerifada,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Controle PNCP: ${edital.numeroControlePncp} • Situação: ${edital.situacao}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                edital.objeto,
                                style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Valor estimado: ${edital.valor}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (edital.linkOrigem != null && edital.linkOrigem!.isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: () => _copiarLinkOrigem(edital.linkOrigem),
                                  icon: const Icon(Icons.open_in_new, color: Color(0xFF2563EB)),
                                  label: const Text(
                                    'Copiar Link Oficial no Portal PNCP',
                                    style: TextStyle(color: Color(0xFF2563EB)),
                                  ),
                                ),
                              const SizedBox(height: 28),
                              const Text(
                                'Itens Licitados (PNCP)',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 14),
                              if (carregandoItens)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: CircularProgressIndicator(),
                                )
                              else if (edital.itens.isEmpty)
                                const Text(
                                  'Nenhum item detalhado retornado pelo PNCP para esta compra.',
                                  style: TextStyle(color: Colors.black54),
                                )
                              else
                                ...edital.itens.map(_buildBullet),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dados da Contratação',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Column(
                              children: [
                                _buildLinhaDado('CNPJ Órgão', edital.cnpjOrgao),
                                const Divider(height: 20),
                                _buildLinhaDado('Localidade', '${edital.municipio} / ${edital.uf}'),
                                const Divider(height: 20),
                                _buildLinhaDado('Total de Itens', '${edital.itens.length}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _salvandoFunil ? null : () => _adicionarAoFunil(edital),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text(
                                _salvandoFunil ? 'Salvando...' : 'Adicionar ao Funil',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: CircleAvatar(radius: 3, backgroundColor: Color(0xFF2563EB)),
          ),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildLinhaDado(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF334155), fontSize: 13)),
        Flexible(
          child: Text(
            valor.isEmpty ? '-' : valor,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13),
          ),
        ),
      ],
    );
  }
}