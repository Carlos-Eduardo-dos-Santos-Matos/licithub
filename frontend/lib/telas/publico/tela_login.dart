import 'package:flutter/material.dart';
import '../../componentes/ilustracoes/fundo_login_painter.dart';
import '../../componentes/ilustracoes/logo_google_painter.dart';
import '../../componentes/logo_licithub.dart';
import '../../configuracoes/tema_app.dart';

typedef LoginPage = TelaLogin;

/// Tela de Login dividida (Split Screen 50/50 em Desktop, empilhada em Mobile).
class TelaLogin extends StatefulWidget {
  final ValueChanged<String>? onLoginSuccess;
  final VoidCallback? onGoogleLogin;

  const TelaLogin({
    super.key,
    this.onLoginSuccess,
    this.onGoogleLogin,
  });

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _senhaFocusNode = FocusNode();

  String _email = '';
  String _senha = '';
  String? _mensagemFeedback;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _emailFocusNode.dispose();
    _senhaFocusNode.dispose();
    super.dispose();
  }

  void _handleContinuarComGoogle() {
    debugPrint('[TelaLogin] Clique em "Continuar com Google"');
    setState(() {
      _mensagemFeedback = null;
    });
    if (widget.onGoogleLogin != null) {
      widget.onGoogleLogin!();
    }
  }

  void _handleEntrar() {
    final emailTrimmed = _email.trim();
    debugPrint(
      '[TelaLogin] Clique em "Entrar" | email: "$emailTrimmed" | senha preenchida: ${_senha.isNotEmpty}',
    );

    if (emailTrimmed.isEmpty || _senha.isEmpty) {
      setState(() {
        _mensagemFeedback = 'Por favor, preencha seu e-mail e sua senha.';
      });
      return;
    }

    setState(() {
      _mensagemFeedback = null;
    });

    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!(emailTrimmed);
    }
  }

  void _handleEsqueceuSenha() {
    debugPrint('[TelaLogin] Clique em "Esqueceu a senha?" (email: "$_email")');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recuperação de senha solicitada.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleCadastreSe() {
    debugPrint('[TelaLogin] Clique em "Cadastre-se"');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecionando para criação de conta...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: _buildPainelDestaque(isDesktop: true),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: const Color(0xFFF5F8FD),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48.0,
                          vertical: 40.0,
                        ),
                        child: _buildAreaFormulario(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Layout empilhado para dispositivos móveis e telas menores
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPainelDestaque(isDesktop: false),
                Container(
                  color: const Color(0xFFF5F8FD),
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 480 ? 24.0 : 40.0,
                    vertical: 40.0,
                  ),
                  child: Center(
                    child: _buildAreaFormulario(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Coluna da Esquerda: Painel de destaque escuro com degradê azul, formas geométricas abstratas e textos.
  Widget _buildPainelDestaque({required bool isDesktop}) {
    return Container(
      constraints: BoxConstraints(
        minHeight: isDesktop ? double.infinity : 360,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.52, 1.0],
          colors: [
            Color(0xFF061B49),
            Color(0xFF00459E),
            Color(0xFF006EE6),
          ],
        ),
      ),
      child: ClipRect(
        child: CustomPaint(
          painter: const FundoLoginPainter(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 56.0 : 28.0,
              vertical: isDesktop ? 44.0 : 36.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Topo Esquerdo: Marca LicitHub + subtítulo LICITAÇÕES
                const LogoLicitHub(
                  primaryColor: Colors.white,
                  subtitleColor: Color(0xFFD6E6FF),
                  titleFontSize: 25,
                  subtitleFontSize: 9.0,
                ),

                SizedBox(height: isDesktop ? 48 : 36),

                // Conteúdo Central: Título e Subtítulo
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Todas as licitações do\npaís, em um só lugar.',
                        style: TextStyle(
                          fontFamily: TemaApp.fonteSerifada,
                          fontFamilyFallback: TemaApp.fallbackSerifada,
                          fontSize: isDesktop ? 38 : 30,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.22,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Encontre oportunidades, acompanhe editais e organize suas propostas com segurança.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFC4DBF7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isDesktop ? 48 : 36),

                // Rodapé: Copyright no canto inferior esquerdo
                const Text(
                  '© 2026 LicitHub',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8FB4E5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Coluna da Direita: Área clara contendo a marca, cabeçalho, botão Google e formulário de login.
  Widget _buildAreaFormulario() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Marca e Subtítulo no topo da área do formulário
            const LogoLicitHub(
              primaryColor: Color(0xFF0A2547),
              subtitleColor: Color(0xFF0A2547),
              titleFontSize: 28,
              subtitleFontSize: 10.0,
            ),
            const SizedBox(height: 28),

            // Cabeçalho: Título e subtítulo
            const Text(
              'Bem-vindo de volta',
              style: TextStyle(
                fontFamily: TemaApp.fonteSerifada,
                fontFamilyFallback: TemaApp.fallbackSerifada,
                fontSize: 32,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0B1F3A),
                height: 1.15,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Entre para acessar sua conta.',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 26),

            // Botão "Continuar com Google"
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _handleContinuarComGoogle,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFAFBFD),
                  foregroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(
                    color: Color(0xFF64748B),
                    width: 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: Size(18, 18),
                      painter: LogoGooglePainter(),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Continuar com Google',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Divisória horizontal com o texto "ou" centralizado em tom sutil
            const Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Color(0xFFDCE4F0),
                    thickness: 1,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'ou',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Color(0xFFDCE4F0),
                    thickness: 1,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Campo E-mail
            const Text(
              'E-mail',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'E-mail',
              textField: true,
              child: TextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (value) {
                  setState(() {
                    _email = value;
                  });
                },
                onSubmitted: (_) {
                  _senhaFocusNode.requestFocus();
                },
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'voce@empresa.com.br',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEEF3FA),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: Color(0xFFD6E0EE),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: Color(0xFF004CA3),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Campo Senha + Link "Esqueceu a senha?" alinhado à direita
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Senha',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: _handleEsqueceuSenha,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFF1D4F91),
                  ),
                  child: const Text(
                    'Esqueceu a senha?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4F91),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Senha',
              textField: true,
              obscured: true,
              child: TextField(
                controller: _senhaController,
                focusNode: _senhaFocusNode,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onChanged: (value) {
                  setState(() {
                    _senha = value;
                  });
                },
                onSubmitted: (_) => _handleEntrar(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                    letterSpacing: 1.8,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEEF3FA),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: Color(0xFFD6E0EE),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: Color(0xFF004CA3),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),

            if (_mensagemFeedback != null) ...[
              const SizedBox(height: 12),
              Text(
                _mensagemFeedback!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Botão "Entrar"
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _handleEntrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004CA3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Entrar',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rodapé: "Não tem uma conta? Cadastre-se"
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Não tem uma conta? ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  TextButton(
                    onPressed: _handleCadastreSe,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFF16437E),
                    ),
                    child: const Text(
                      'Cadastre-se',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16437E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
