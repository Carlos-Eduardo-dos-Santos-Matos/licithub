import 'package:flutter/material.dart';
import '../../configuracoes/tema_app.dart';
import '../../modelos/edital.dart';

typedef DetalhesEditalPage = TelaDetalhesEdital;

/// Sub-tela de Detalhes do Edital com Resumo Inteligente IA e Itens Licitados.
class TelaDetalhesEdital extends StatelessWidget {
  final Edital edital;
  final VoidCallback onBack;

  const TelaDetalhesEdital({
    super.key,
    required this.edital,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1E293B),
                    ),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 16),
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
              Row(
                children: [
                  const Icon(Icons.notifications_none, color: Colors.black54),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${edital.titulo} -\n${edital.orgao}',
                          style: const TextStyle(
                            fontFamily: TemaApp.fonteSerifada,
                            fontFamilyFallback: TemaApp.fallbackSerifada,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          edital.objeto,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Valor estimado: ${edital.valor}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.picture_as_pdf_outlined,
                            color: Color(0xFF2563EB),
                          ),
                          label: const Text(
                            'Edital_Completo.pdf',
                            style: TextStyle(color: Color(0xFF2563EB)),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Itens licitados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...edital.itens.map(_buildBullet),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo Inteligente IA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          children: [
                            _buildResumoRow(
                              'Exige Atestado Técnico?',
                              'SIM',
                              true,
                            ),
                            const Divider(height: 24, color: Color(0xFFBBF7D0)),
                            _buildResumoRow('Vistoria prévia?', 'NÃO', false),
                            const Divider(height: 24, color: Color(0xFFBBF7D0)),
                            _buildResumoRow(
                              'Capital Social mínimo:',
                              'R\$ 25.000',
                              true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Adicionar ao Funil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
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
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 12),
            child: CircleAvatar(radius: 3, backgroundColor: Colors.black45),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoRow(String label, String value, bool isPositive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPositive
                    ? const Color(0xFF059669)
                    : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isPositive ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 16,
              color: isPositive
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
            ),
          ],
        ),
      ],
    );
  }
}
