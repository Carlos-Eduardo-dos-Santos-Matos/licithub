import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ============================================================================
// SERVIÇO DE COMUNICAÇÃO HTTP COM O C#
// ============================================================================
Future<Map<String, dynamic>> buscarDadosDashboard() async {
  final url = Uri.parse('http://localhost:5173/api/dashboard');
  
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Erro ao carregar dados: ${response.statusCode}');
    }
  } catch (e) {
    print('Erro na ligação com a API: $e');
    return {};
  }
}

void main() {
  runApp(const LicitHubApp());
}

class LicitHubApp extends StatelessWidget {
  const LicitHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LicitHub MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF0F172A),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF334155)),
        ),
      ),
      home: const MainLayout(),
    );
  }
}

// ============================================================================
// LAYOUT PRINCIPAL (SIDEBAR + NAVEGAÇÃO)
// ============================================================================
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _mostrandoDetalhes = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const DashboardPage(),
      BuscarEditaisPage(
        onAnalisar: () {
          setState(() {
            _mostrandoDetalhes = true;
          });
        },
      ),
      const FunilPage(),
      const Center(child: Text("Página de Documentos", style: TextStyle(fontSize: 24))),
    ];

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 250,
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.only(top: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.blueAccent, size: 28),
                      const SizedBox(width: 12),
                      const Text('LicitHub', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildMenuItem(0, Icons.home_outlined, 'Dashboard'),
                _buildMenuItem(1, Icons.search, 'Buscar Editais'),
                _buildMenuItem(2, Icons.filter_alt_outlined, 'Funil'),
                _buildMenuItem(3, Icons.description_outlined, 'Documentos'),
              ],
            ),
          ),
          
          // ÁREA PRINCIPAL
          Expanded(
            child: Container(
              color: const Color(0xFFF4F7F9),
              child: _mostrandoDetalhes 
                  ? DetalhesEditalPage(onBack: () {
                      setState(() {
                        _mostrandoDetalhes = false;
                      });
                    }) 
                  : pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index && !_mostrandoDetalhes;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _mostrandoDetalhes = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 22),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? Colors.white : Colors.white60)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PÁGINA 1: DASHBOARD (COM FUTUREBUILDER E API)
// ============================================================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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

        final dados = snapshot.data ?? {};
        final licitacoesAtivas = dados['licitacoesAtivas']?.toString() ?? '0';
        final disputasGanhas = dados['disputasGanhas']?.toString() ?? 'R\$ 0';
        final mensagemAlerta = dados['alerta']?.toString() ?? 'Sem alertas de momento.';

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
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                  )
                ],
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3), 
                  border: Border.all(color: const Color(0xFFFDE047)),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFCA8A04)),
                    const SizedBox(width: 12),
                    Text(mensagemAlerta, style: const TextStyle(color: Color(0xFF854D0E), fontWeight: FontWeight.w500)),
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
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Volume das licitações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Últimas Oportunidades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 16),
                          _buildListaOportunidade(Icons.account_balance, Colors.orange, 'Prefeitura de SP', 'Pregão 48/2026'),
                          const Divider(height: 32, color: Color(0xFFF1F5F9)),
                          _buildListaOportunidade(Icons.local_hospital, Colors.teal, 'Hospital das Clínicas', 'Pregão 15/2026', tag: '75% completo'),
                          const Divider(height: 32, color: Color(0xFFF1F5F9)),
                          _buildListaOportunidade(Icons.account_balance, Colors.blue, 'Governo do Estado de SP', 'Pregão 12/2026'),
                        ],
                      ),
                    ),
                  ),
                ],
              )
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(valor, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraGrafico(double altura, String mes) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(width: 32, height: altura, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 8),
        Text(mes, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }

  Widget _buildListaOportunidade(IconData icone, Color corIcone, String orgao, String pregao, {String? tag}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: corIcone.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icone, color: corIcone, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(orgao, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(pregao, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  if (tag != null) ...[
                    const SizedBox(width: 8),
                    Text(tag, style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.w500)),
                  ]
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

// ============================================================================
// PÁGINA 2: BUSCAR EDITAIS
// ============================================================================
class BuscarEditaisPage extends StatelessWidget {
  final VoidCallback onAnalisar;
  
  const BuscarEditaisPage({super.key, required this.onAnalisar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
            child: const TextField(
              decoration: InputDecoration(hintText: 'Buscar por objeto, órgão ou CNAE...', hintStyle: TextStyle(color: Colors.black38), prefixIcon: Icon(Icons.search, color: Colors.black45), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 16)),
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
                _buildCardEdital(icone: Icons.account_balance, corIcone: Colors.orange, titulo: 'Prefeitura de São Paulo - Pregão 45/2026', objeto: 'Serviços de limpeza', valor: 'R\$ 250.000,00'),
                const SizedBox(height: 16),
                _buildCardEdital(icone: Icons.business, corIcone: Colors.redAccent, titulo: 'Governo do Estado de SP - Pregão 12/2026', objeto: 'Fornecimento de Software', valor: 'R\$ 840.000,00'),
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
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), border: Border.all(color: const Color(0xFFBFDBFE)), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(texto, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.w500)), const SizedBox(width: 6), const Icon(Icons.close, size: 14, color: Color(0xFF2563EB))],
      ),
    );
  }

  Widget _buildCardEdital({required IconData icone, required Color corIcone, required String titulo, required String objeto, required String valor}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: corIcone.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icone, color: corIcone, size: 28)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(objeto, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 16),
                const Text('Valor Estimado:', style: TextStyle(fontSize: 13, color: Colors.black45)),
                Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
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
                onPressed: onAnalisar,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                child: const Text('Analisar Edital', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PÁGINA 3: FUNIL DE DISPUTA (KANBAN)
// ============================================================================
class FunilPage extends StatelessWidget {
  const FunilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Funil de Disputa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKanbanColumn(
                  titulo: 'Mapeados (3)',
                  cards: [
                    _buildKanbanCard('Prefeitura de SP - Limpeza', 'R\$ 250k'),
                    _buildKanbanCard('Prefeitura de SP - Limpeza', 'R\$ 250k'),
                    _buildKanbanCard('Prefeitura de SP - Limpeza', 'R\$ 120k'),
                  ],
                ),
                const SizedBox(width: 24),
                _buildKanbanColumn(
                  titulo: 'Documentação (2)',
                  cards: [
                    _buildKanbanCard('Hospital das Clínicas - Insumos', 'R\$ 120k', progresso: 0.75, textoProgresso: '75% completo'),
                  ],
                ),
                const SizedBox(width: 24),
                _buildKanbanColumn(
                  titulo: 'Pronto para Lance (1)',
                  cards: [
                    _buildKanbanCard('Tribunal de Justiça - TI', 'R\$ 95k'),
                  ],
                ),
                const SizedBox(width: 24),
                _buildKanbanColumn(
                  titulo: 'Resultados (2)',
                  cards: [
                    _buildKanbanCard('Câmara de SP - Móveis', '(R\$ 45k)', tagResultado: '[Ganho]', corTag: Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn({required String titulo, required List<Widget> cards}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 12), child: card)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanCard(String titulo, String valor, {double? progresso, String? textoProgresso, String? tagResultado, Color? corTag}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 14)),
          const SizedBox(height: 8),
          Text(valor, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          if (progresso != null) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progresso, backgroundColor: Colors.grey.shade200, color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4), minHeight: 6),
            const SizedBox(height: 8),
            Text(textoProgresso ?? '', style: const TextStyle(color: Colors.black45, fontSize: 12)),
          ],
          if (tagResultado != null) ...[
            const SizedBox(height: 12),
            Text(tagResultado, style: TextStyle(color: corTag, fontSize: 13, fontWeight: FontWeight.bold)),
          ]
        ],
      ),
    );
  }
}

// ============================================================================
// PÁGINA 4: DETALHES DO EDITAL (SUB-PÁGINA)
// ============================================================================
class DetalhesEditalPage extends StatelessWidget {
  final VoidCallback onBack;
  
  const DetalhesEditalPage({super.key, required this.onBack});

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
                  IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: onBack),
                  const SizedBox(width: 16),
                  const Text('Detalhes do Edital', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.notifications_none, color: Colors.black54),
                  const SizedBox(width: 16),
                  CircleAvatar(backgroundColor: Colors.grey[300], child: const Icon(Icons.person, color: Colors.white)),
                ],
              )
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
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pregão Eletrônico 45/2026 -\nPrefeitura de SP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 16),
                        const Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Texto os prescimento descontbiner em marosas de feitorões públicas. Evita regurado de enits licitações para uma conseneten e anoura initsstora responoúsda. Pera cen com consuretana bs download.', style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5)),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF2563EB)),
                          label: const Text('Edital_Completo.pdf', style: TextStyle(color: Color(0xFF2563EB))),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), side: const BorderSide(color: Color(0xFFBFDBFE)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                        const SizedBox(height: 32),
                        const Text('Itens licitados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 16),
                        _buildBullet('Itens de Elemento o Conneesto'),
                        _buildBullet('Itens de Corpultarios'),
                        _buildBullet('Itens de Mudecira de - Conoticidade'),
                        _buildBullet('Itens de Elonsentamento'),
                        _buildBullet('Capital Social mínimo: Simóro'),
                        _buildBullet('Capital Social mínimo: R\$ 25.000'),
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
                      const Text('Resumo Inteligente IA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
                        child: Column(
                          children: [
                            _buildResumoRow('Exige Atestado Técnico?', 'SIM', true),
                            const Divider(height: 24, color: Color(0xFFBBF7D0)),
                            _buildResumoRow('Vistoria prévia?', 'NÃO', false),
                            const Divider(height: 24, color: Color(0xFFBBF7D0)),
                            _buildResumoRow('Capital Social mínimo:', 'R\$ 25.000', true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Adicionar ao Funil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
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
          const Padding(padding: EdgeInsets.only(top: 6, right: 12), child: CircleAvatar(radius: 3, backgroundColor: Colors.black45)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildResumoRow(String label, String value, bool isPositive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF334155), fontSize: 13)),
        Row(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626))),
            const SizedBox(width: 6),
            Icon(isPositive ? Icons.check_circle_outline : Icons.cancel_outlined, size: 16, color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626))
          ],
        )
      ],
    );
  }
}