import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../componentes/ilustracoes/equipe_negocios_painter.dart';
import '../../componentes/ilustracoes/predio_governo_painter.dart';
import '../../configuracoes/tema_app.dart';
import '../../modelos/dados_landing.dart';

typedef HomeScreen = TelaInicial;

/// Landing Page pública do LicitHub (rota '/').
class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inicioKey = GlobalKey();
  final GlobalKey _sobreNosKey = GlobalKey();
  final GlobalKey _servicosKey = GlobalKey();
  final GlobalKey _contatoKey = GlobalKey();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailContatoController = TextEditingController();
  final TextEditingController _assuntoController = TextEditingController();
  final TextEditingController _mensagemController = TextEditingController();

  late final Map<String, dynamic> _dadosLanding;

  @override
  void initState() {
    super.initState();
    _dadosLanding = obterDadosLanding();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nomeController.dispose();
    _emailContatoController.dispose();
    _assuntoController.dispose();
    _mensagemController.dispose();
    super.dispose();
  }

  void _rolarParaSecao(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navegarParaLogin() {
    debugPrint('[TelaInicial] Navegando para a tela de login (/login)');
    Navigator.of(context).pushNamed('/login');
  }

  void _enviarMensagemContato() {
    final payloadSimulado = <String, dynamic>{
      'nomeCompleto': _nomeController.text.trim(),
      'email': _emailContatoController.text.trim(),
      'assunto': _assuntoController.text.trim(),
      'mensagem': _mensagemController.text.trim(),
      'enviadoEm': DateTime.now().toIso8601String(),
      'origem': 'LandingPage/Contato',
    };

    final jsonLog = const JsonEncoder.withIndent('  ').convert(payloadSimulado);
    debugPrint('[TelaInicial Contato] Formulário submetido (JSON):\n$jsonLog');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mensagem registrada com sucesso! Confira o console para o JSON.',
        ),
        backgroundColor: Color(0xFF004CA3),
        duration: Duration(seconds: 3),
      ),
    );
  }

  IconData _mapearIcone(String codigo) {
    switch (codigo) {
      case 'search':
        return Icons.search_rounded;
      case 'document':
        return Icons.description_outlined;
      case 'bell':
        return Icons.notifications_none_rounded;
      case 'shield':
        return Icons.verified_user_outlined;
      case 'users':
        return Icons.people_outline_rounded;
      case 'phone':
        return Icons.phone_outlined;
      case 'mail':
        return Icons.mail_outline_rounded;
      case 'location':
        return Icons.location_on_outlined;
      case 'clock':
        return Icons.access_time_rounded;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // A. Cabeçalho (AppBar Fixo no Topo)
          _buildHeader(context),

          // Corpo rolável com todas as seções da Landing Page
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // B. Seção Hero (Banner Principal)
                      Container(
                        key: _inicioKey,
                        child: _buildHeroSection(context),
                      ),

                      // C. Seção "Sobre nós"
                      Container(
                        key: _sobreNosKey,
                        child: _buildSobreNosSection(context),
                      ),

                      // D. Seção "Visão e valores" (Serviços)
                      Container(
                        key: _servicosKey,
                        child: _buildVisaoValoresSection(context),
                      ),

                      // E. Seção "Contato"
                      Container(
                        key: _contatoKey,
                        child: _buildContatoSection(context),
                      ),

                      // F. Rodapé (Footer)
                      _buildFooter(),
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

  // ==========================================================================
  // A. CABEÇALHO (APPBAR)
  // ==========================================================================
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8EEF5), width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isCompact = constraints.maxWidth < 680;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Esquerda: Logo "LicitHub" (fonte com serifa, em azul escuro)
                    InkWell(
                      onTap: () => _rolarParaSecao(_inicioKey),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'LicitHub',
                          style: TextStyle(
                            fontFamily: TemaApp.fonteSerifada,
                            fontFamilyFallback: TemaApp.fallbackSerifada,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF154586),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),

                    // Direita: Links de navegação e botão "Contato"
                    if (!isCompact)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeaderNavLink(
                            'Início',
                            () => _rolarParaSecao(_inicioKey),
                          ),
                          const SizedBox(width: 24),
                          _buildHeaderNavLink(
                            'Sobre nós',
                            () => _rolarParaSecao(_sobreNosKey),
                          ),
                          const SizedBox(width: 24),
                          _buildHeaderNavLink(
                            'Serviços',
                            () => _rolarParaSecao(_servicosKey),
                          ),
                          const SizedBox(width: 24),
                          _buildHeaderNavLink(
                            'Entrar',
                            _navegarParaLogin,
                          ),
                          const SizedBox(width: 24),
                          ElevatedButton(
                            onPressed: () => _rolarParaSecao(_contatoKey),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004CA3),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'Contato',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeaderNavLink('Entrar', _navegarParaLogin),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => _rolarParaSecao(_contatoKey),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004CA3),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'Contato',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.menu_rounded,
                              color: Color(0xFF154586),
                            ),
                            onSelected: (value) {
                              if (value == 'inicio') {
                                _rolarParaSecao(_inicioKey);
                              }
                              if (value == 'sobre') {
                                _rolarParaSecao(_sobreNosKey);
                              }
                              if (value == 'servicos') {
                                _rolarParaSecao(_servicosKey);
                              }
                              if (value == 'entrar') _navegarParaLogin();
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'inicio',
                                child: Text('Início'),
                              ),
                              PopupMenuItem(
                                value: 'sobre',
                                child: Text('Sobre nós'),
                              ),
                              PopupMenuItem(
                                value: 'servicos',
                                child: Text('Serviços'),
                              ),
                              PopupMenuItem(
                                value: 'entrar',
                                child: Text('Entrar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderNavLink(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF1E293B),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  // ==========================================================================
  // B. SEÇÃO HERO (BANNER PRINCIPAL COM GLASSMORPHISM)
  // ==========================================================================
  Widget _buildHeroSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;

        return SizedBox(
          height: isDesktop ? 560 : 480,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ilustração arquitetônica de fundo (prédio governamental com colunas)
              const CustomPaint(
                painter: PredioGovernoPainter(),
              ),

              // Imagem fotográfica do prédio governamental (com fallback transparente para a pintura abaixo)
              Image.network(
                'https://images.unsplash.com/photo-1541872703-74c5e44368f9?auto=format&fit=crop&w=1800&q=80',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.expand(),
              ),

              // Overlay azul escuro/vibrante por cima da imagem
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.55, 1.0],
                    colors: [
                      const Color(0xFF061E4E).withValues(alpha: 0.84),
                      const Color(0xFF0048A5).withValues(alpha: 0.80),
                      const Color(0xFF0072E5).withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),

              // Card central com efeito Glassmorphism (BackdropFilter)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32.0 : 20.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 660),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 56.0 : 28.0,
                            vertical: isDesktop ? 48.0 : 34.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF031536).withValues(alpha: 0.22),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo "LicitHub" branca
                              Text(
                                'LicitHub',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: TemaApp.fonteSerifada,
                                  fontFamilyFallback: TemaApp.fallbackSerifada,
                                  fontSize: isDesktop ? 50 : 38,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Título "Sua empresa, as licitações certas"
                              Text(
                                'Sua empresa, as licitações certas',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: TemaApp.fonteSerifada,
                                  fontFamilyFallback: TemaApp.fallbackSerifada,
                                  fontSize: isDesktop ? 24 : 19,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Texto descritivo
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 500),
                                child: const Text(
                                  'Ligamos sua empresa às licitações do governo e entregamos as informações mastigadas: editais resumidos, prazos organizados e oportunidades filtradas para o seu negócio.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFDCEBFF),
                                    height: 1.55,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Botão branco "Comece agora ->"
                              ElevatedButton(
                                onPressed: _navegarParaLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0F294A),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                    vertical: 16,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Comece agora',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F294A),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: Color(0xFF0F294A),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // C. SEÇÃO "SOBRE NÓS" (50/50 DESKTOP, EMPILHADO MOBILE)
  // ==========================================================================
  Widget _buildSobreNosSection(BuildContext context) {
    final List<dynamic> paragrafos =
        (_dadosLanding['sobreNos'] as List<dynamic>?) ?? const [];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isDesktop = constraints.maxWidth >= 860;

              final Widget textoColuna = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sobre nós',
                    style: TextStyle(
                      fontFamily: TemaApp.fonteSerifada,
                      fontFamilyFallback: TemaApp.fallbackSerifada,
                      fontSize: 38,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0A4386),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (int i = 0; i < paragrafos.length; i++) ...[
                    Text(
                      paragrafos[i].toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF475569),
                        height: 1.62,
                      ),
                    ),
                    if (i < paragrafos.length - 1) const SizedBox(height: 18),
                  ],
                ],
              );

              final Widget imagemColuna = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: AspectRatio(
                    aspectRatio: 1.18,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Fundo orgânico azul-claro suavemente inclinado
                        Transform.rotate(
                          angle: -0.055,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCEBFA),
                              borderRadius: BorderRadius.circular(36),
                            ),
                          ),
                        ),
                        // Container principal com bordas suavemente arredondadas
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF0F172A).withValues(alpha: 0.10),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                const CustomPaint(
                                  painter: EquipeNegociosPainter(),
                                ),
                                Image.network(
                                  'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=1000&q=80',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.expand(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 1, child: textoColuna),
                    const SizedBox(width: 56),
                    Expanded(flex: 1, child: imagemColuna),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  textoColuna,
                  const SizedBox(height: 40),
                  imagemColuna,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // D. SEÇÃO "VISÃO E VALORES" (5 CARDS BRANCOS)
  // ==========================================================================
  Widget _buildVisaoValoresSection(BuildContext context) {
    final List<dynamic> valores =
        (_dadosLanding['visaoValores'] as List<dynamic>?) ?? const [];

    return Container(
      color: const Color(0xFFEEF4FB),
      padding: const EdgeInsets.symmetric(vertical: 84, horizontal: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Column(
            children: [
              const Text(
                'Visão e valores',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: TemaApp.fonteSerifada,
                  fontFamilyFallback: TemaApp.fallbackSerifada,
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF004CA3),
                ),
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 1020) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < valores.length; i++) ...[
                          Expanded(
                            child: _buildValorCard(
                              valores[i] as Map<String, dynamic>,
                            ),
                          ),
                          if (i < valores.length - 1) const SizedBox(width: 20),
                        ],
                      ],
                    );
                  }

                  final double cardWidth = constraints.maxWidth >= 640
                      ? (constraints.maxWidth - 20) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final item in valores)
                        SizedBox(
                          width: cardWidth,
                          child: _buildValorCard(item as Map<String, dynamic>),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValorCard(Map<String, dynamic> item) {
    final String iconeKey = item['icone']?.toString() ?? 'search';
    final String titulo = item['titulo']?.toString() ?? '';
    final String descricao = item['descricao']?.toString() ?? '';

    return Container(
      height: 215,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EDF7), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF052357),
                  Color(0xFF0066CC),
                ],
              ),
            ),
            child: Icon(
              _mapearIcone(iconeKey),
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // E. SEÇÃO "CONTATO" (2 COLUNAS DESKTOP, EMPILHADO MOBILE)
  // ==========================================================================
  Widget _buildContatoSection(BuildContext context) {
    final List<dynamic> contatos =
        (_dadosLanding['contatos'] as List<dynamic>?) ?? const [];

    return Container(
      color: const Color(0xFFF8FAFE),
      padding: const EdgeInsets.symmetric(vertical: 84, horizontal: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            children: [
              const Text(
                'Contato',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: TemaApp.fonteSerifada,
                  fontFamilyFallback: TemaApp.fallbackSerifada,
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF004CA3),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quer encontrar as licitações certas para sua empresa? Fale com a gente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 48),

              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isDesktop = constraints.maxWidth >= 860;

                  // Coluna Esquerda (Info: 4 cards horizontais + banner azul escuro)
                  final Widget colunaEsquerda = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < contatos.length; i++) ...[
                        _buildContatoInfoCard(
                          contatos[i] as Map<String, dynamic>,
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 26,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF051C48),
                              Color(0xFF004BA0),
                              Color(0xFF0077E6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF004BA0).withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Mais oportunidades, menos papelada. Deixe a parte difícil com a LicitHub.',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  // Coluna Direita (Formulário em card branco)
                  final Widget colunaDireita = Container(
                    padding: const EdgeInsets.all(34),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE5EDF7),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Envie uma mensagem',
                            style: TextStyle(
                              fontFamily: TemaApp.fonteSerifada,
                              fontFamilyFallback: TemaApp.fallbackSerifada,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0B1F3A),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildCampoContato(
                            label: 'Nome completo *',
                            hint: 'Seu nome',
                            controller: _nomeController,
                          ),
                          const SizedBox(height: 18),
                          _buildCampoContato(
                            label: 'E-mail *',
                            hint: 'voce@empresa.com.br',
                            controller: _emailContatoController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),
                          _buildCampoContato(
                            label: 'Assunto *',
                            hint: 'Como podemos ajudar?',
                            controller: _assuntoController,
                          ),
                          const SizedBox(height: 18),
                          _buildCampoContato(
                            label: 'Mensagem *',
                            hint: 'Conte sobre sua empresa...',
                            controller: _mensagemController,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFF051C48),
                                    Color(0xFF004BA0),
                                    Color(0xFF0077E6),
                                  ],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: _enviarMensagemContato,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Enviar mensagem',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.send_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 10, child: colunaEsquerda),
                        const SizedBox(width: 32),
                        Expanded(flex: 11, child: colunaDireita),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      colunaEsquerda,
                      const SizedBox(height: 32),
                      colunaDireita,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContatoInfoCard(Map<String, dynamic> item) {
    final String iconeKey = item['icone']?.toString() ?? 'phone';
    final String titulo = item['titulo']?.toString() ?? '';
    final String valor = item['valor']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EDF7), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF004CA3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _mapearIcone(iconeKey),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoContato({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFDBE3F0),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF004CA3),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // F. RODAPÉ (FOOTER)
  // ==========================================================================
  Widget _buildFooter() {
    return Container(
      color: const Color(0xFFF8FAFE),
      child: const Column(
        children: [
          Divider(
            color: Color(0xFFE2E8F0),
            thickness: 1,
            height: 1,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Center(
              child: Text(
                '© 2026 LicitHub. Todos os direitos reservados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
