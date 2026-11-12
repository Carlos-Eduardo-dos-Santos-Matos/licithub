import 'package:flutter/material.dart';
import '../../modelos/edital.dart';

typedef BuscarEditaisPage = TelaBuscarEditais;

/// Aba 2: Busca e listagem de Editais de licitação.
class TelaBuscarEditais extends StatelessWidget {
  final ValueChanged<Edital> onAnalisar;

  const TelaBuscarEditais({super.key, required this.onAnalisar});

  static const List<Edital> editais = [
    Edital(
      titulo: 'Pregão Eletrônico 45/2026',
      orgao: 'Prefeitura de São Paulo',
      objeto:
          'Contratação de serviços de limpeza predial para as unidades administrativas, com fornecimento de mão de obra, materiais e equipamentos.',
      valor: 'R\$ 250.000,00',
      itens: [
        'Limpeza e conservação das áreas internas e externas',
        'Fornecimento de materiais de higiene e limpeza',
        'Equipe com supervisão dedicada',
        'Capital social mínimo: R\$ 25.000',
      ],
    ),
    Edital(
      titulo: 'Pregão Eletrônico 12/2026',
      orgao: 'Governo do Estado de SP',
      objeto:
          'Fornecimento de licenças de software de gestão, com serviços de implantação, treinamento e suporte técnico.',
      valor: 'R\$ 840.000,00',
      itens: [
        'Licenças de uso por 24 meses',
        'Implantação e migração de dados',
        'Treinamento das equipes',
        'Suporte técnico em horário comercial',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por objeto, órgão ou CNAE...',
                hintStyle: TextStyle(color: Colors.black38),
                prefixIcon: Icon(Icons.search, color: Colors.black45),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFiltroTag('Limpeza'),
              const SizedBox(width: 12),
              _buildFiltroTag('São Paulo'),
              const SizedBox(width: 12),
              _buildFiltroTag('> R\$ 100k'),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildCardEdital(
                  icone: Icons.account_balance,
                  corIcone: Colors.orange,
                  edital: editais[0],
                ),
                const SizedBox(height: 16),
                _buildCardEdital(
                  icone: Icons.business,
                  corIcone: Colors.redAccent,
                  edital: editais[1],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroTag(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            texto,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.close, size: 14, color: Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildCardEdital({
    required IconData icone,
    required Color corIcone,
    required Edital edital,
  }) {
    final titulo = '${edital.orgao} - ${edital.titulo}';
    final objeto = edital.objeto;
    final valor = edital.valor;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: corIcone.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: corIcone, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  objeto,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Valor Estimado:',
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.more_horiz, color: Colors.black38),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => onAnalisar(edital),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Analisar Edital',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
