import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/edital.dart';
import 'formatadores.dart';

typedef RegistroJson = Map<String, dynamic>;
typedef ListaRegistros = List<RegistroJson>;
typedef FutureRegistro = Future<RegistroJson>;
typedef FutureListaRegistros = Future<ListaRegistros>;
typedef FutureListaEditais = Future<List<Edital>>;
typedef FutureListaDocs = Future<List<DocumentoEmpresa>>;

const String apiLicitacoesUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5173',
);

const String apiUsuariosUrl = String.fromEnvironment(
  'AUTH_BASE_URL',
  defaultValue: 'http://localhost:5174',
);

class SessaoUsuario {
  static String? accessToken;
  static String? refreshToken;
  static String nomeUsuario = 'Usuário LicitHub';
  static String emailUsuario = '';
  static String razaoSocial = 'LicitHub Admin LTDA';
  static String cnpjEmpresa = '00000000000191';
  static String telefoneContato = '';
  static String? fotoPerfilBase64;

  static const _kAccessToken = 'licithub_access_token';
  static const _kRefreshToken = 'licithub_refresh_token';
  static const _kNomeUsuario = 'licithub_nome_usuario';
  static const _kEmailUsuario = 'licithub_email_usuario';
  static const _kRazaoSocial = 'licithub_razao_social';
  static const _kCnpjEmpresa = 'licithub_cnpj_empresa';
  static const _kTelefoneContato = 'licithub_telefone_contato';
  static const _kFotoPerfil = 'licithub_foto_perfil';

  static bool get estaAutenticado =>
      accessToken != null && accessToken!.isNotEmpty;

  static Map<String, String> get headersAutenticados => {
        'Content-Type': 'application/json',
        if (estaAutenticado) 'Authorization': 'Bearer $accessToken',
      };

  static Future<void> salvarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) {
      await prefs.setString(_kAccessToken, accessToken!);
    }
    if (refreshToken != null) {
      await prefs.setString(_kRefreshToken, refreshToken!);
    }
    await prefs.setString(_kNomeUsuario, nomeUsuario);
    await prefs.setString(_kEmailUsuario, emailUsuario);
    await prefs.setString(_kRazaoSocial, razaoSocial);
    await prefs.setString(_kCnpjEmpresa, cnpjEmpresa);
    await prefs.setString(_kTelefoneContato, telefoneContato);

    if (fotoPerfilBase64 != null && fotoPerfilBase64!.isNotEmpty) {
      await prefs.setString(_kFotoPerfil, fotoPerfilBase64!);
    } else {
      await prefs.remove(_kFotoPerfil);
    }
  }

  static Future<void> carregarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_kAccessToken);
    refreshToken = prefs.getString(_kRefreshToken);
    nomeUsuario = prefs.getString(_kNomeUsuario) ?? 'Usuário LicitHub';
    emailUsuario = prefs.getString(_kEmailUsuario) ?? '';
    razaoSocial = prefs.getString(_kRazaoSocial) ?? 'LicitHub Admin LTDA';
    cnpjEmpresa = prefs.getString(_kCnpjEmpresa) ?? '00000000000191';
    telefoneContato = prefs.getString(_kTelefoneContato) ?? '';
    fotoPerfilBase64 = prefs.getString(_kFotoPerfil);
  }

  static Future<void> limpar() async {
    accessToken = null;
    refreshToken = null;
    nomeUsuario = 'Usuário LicitHub';
    emailUsuario = '';
    razaoSocial = 'LicitHub Admin LTDA';
    cnpjEmpresa = '00000000000191';
    telefoneContato = '';
    fotoPerfilBase64 = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kNomeUsuario);
    await prefs.remove(_kEmailUsuario);
    await prefs.remove(_kRazaoSocial);
    await prefs.remove(_kCnpjEmpresa);
    await prefs.remove(_kTelefoneContato);
    await prefs.remove(_kFotoPerfil);
  }
}

Future<void> autenticarUsuario({
  required String email,
  required String senha,
}) async {
  final respLogin = await http.post(
    Uri.parse('$apiUsuariosUrl/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'senha': senha}),
  );

  if (respLogin.statusCode != 200) {
    final erro = _extrairMensagemErro(
      respLogin.body,
      'E-mail ou senha inválidos.',
    );
    throw Exception(erro);
  }

  final tokens = jsonDecode(respLogin.body) as RegistroJson;
  SessaoUsuario.accessToken = tokens['accessToken']?.toString();
  SessaoUsuario.refreshToken = tokens['refreshToken']?.toString();
  SessaoUsuario.emailUsuario = email;

  final respMe = await http.get(
    Uri.parse('$apiUsuariosUrl/api/auth/me'),
    headers: SessaoUsuario.headersAutenticados,
  );

  if (respMe.statusCode == 200) {
    final perfil = jsonDecode(respMe.body) as RegistroJson;
    SessaoUsuario.nomeUsuario = perfil['nome']?.toString() ?? email;
  }

  await SessaoUsuario.salvarSessao();
}

Future<void> registrarEAcessar({
  required String nome,
  required String email,
  required String senha,
  String? cnpj,
  String? razaoSocial,
  String? porte,
}) async {
  final respReg = await http.post(
    Uri.parse('$apiUsuariosUrl/api/auth/registrar'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'nome': nome,
      'email': email,
      'senha': senha,
      'cnpj': cnpj,
      'razaoSocial': razaoSocial,
      'porte': porte ?? 'EPP',
    }),
  );

  if (respReg.statusCode != 201 && respReg.statusCode != 200) {
    final erro = _extrairMensagemErro(
      respReg.body,
      'Não foi possível concluir o cadastro.',
    );
    throw Exception(erro);
  }

  if (razaoSocial != null && razaoSocial.trim().isNotEmpty) {
    SessaoUsuario.razaoSocial = razaoSocial.trim();
  }
  if (cnpj != null && cnpj.trim().isNotEmpty) {
    SessaoUsuario.cnpjEmpresa = cnpj.trim();
  }

  await autenticarUsuario(email: email, senha: senha);
}

FutureRegistro buscarDadosDashboard() async {
  final response = await http.get(
    Uri.parse('$apiLicitacoesUrl/api/dashboard'),
    headers: SessaoUsuario.headersAutenticados,
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Falha ao carregar o dashboard (HTTP ${response.statusCode})',
    );
  }

  return jsonDecode(response.body) as RegistroJson;
}

FutureRegistro sincronizarPncpAgora() async {
  final response = await http.post(
    Uri.parse('$apiLicitacoesUrl/api/sincronizar'),
    headers: SessaoUsuario.headersAutenticados,
  );

  if (response.statusCode != 200) {
    final erro = _extrairMensagemErro(
      response.body,
      'Falha na sincronização com o PNCP.',
    );
    throw Exception(erro);
  }

  return jsonDecode(response.body) as RegistroJson;
}

FutureListaEditais buscarLicitacoes({
  String? termo,
  String? uf,
  double? valorMinimo,
  String? modalidade,
  String? situacao,
  int pagina = 1,
}) async {
  final params = <String, String>{
    'pagina': '$pagina',
    'tamanhoPagina': '25',
    if (termo != null && termo.trim().isNotEmpty) 'q': termo.trim(),
    if (uf != null && uf.trim().isNotEmpty) 'uf': uf.trim(),
    if (valorMinimo != null && valorMinimo > 0) 'valorMin': '$valorMinimo',
    if (modalidade != null && modalidade.trim().isNotEmpty)
      'modalidade': modalidade.trim(),
    if (situacao != null && situacao.trim().isNotEmpty)
      'situacao': situacao.trim(),
  };

  final uri = Uri.parse(
    '$apiLicitacoesUrl/api/licitacoes',
  ).replace(queryParameters: params);

  final response = await http.get(
    uri,
    headers: SessaoUsuario.headersAutenticados,
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Erro ao buscar licitações (HTTP ${response.statusCode})',
    );
  }

  final body = jsonDecode(response.body) as RegistroJson;
  final lista = (body['itens'] as List<dynamic>?) ?? [];

  return lista
      .map(
        (item) => Edital.fromJson(
          item as RegistroJson,
          formatarMoeda,
        ),
      )
      .toList();
}

Future<Edital> buscarDetalhesEdital(Edital base) async {
  final response = await http.get(
    Uri.parse('$apiLicitacoesUrl/api/licitacoes/${base.id}'),
    headers: SessaoUsuario.headersAutenticados,
  );

  if (response.statusCode != 200) {
    return base;
  }

  final body = jsonDecode(response.body) as RegistroJson;
  final itensRaw = (body['itens'] as List<dynamic>?) ?? [];

  final itensFormatados = itensRaw.map((item) {
    final m = item as RegistroJson;
    final nr = m['numeroItem'] ?? '';
    final desc = m['descricao']?.toString() ?? '';
    final qtd = m['quantidade'] ?? 0;
    final un = m['unidade']?.toString() ?? 'UN';
    final vl = m['valorUnitarioEstimado'];

    final vlStr = (vl is num && vl > 0)
        ? ' — Unit.: ${formatarMoeda(vl)}'
        : '';

    return 'Item $nr: $desc ($qtd $un$vlStr)';
  }).toList();

  return base.copyWith(itens: itensFormatados);
}

Future<void> adicionarEditalAoFunil(
  int idLicitacao, {
  String? anotacoes,
}) async {
  final response = await http.post(
    Uri.parse('$apiLicitacoesUrl/api/acompanhamentos'),
    headers: SessaoUsuario.headersAutenticados,
    body: jsonEncode({
      'idLicitacao': idLicitacao,
      'anotacoes': anotacoes,
    }),
  );

  if (response.statusCode == 401) {
    throw Exception(
      'Faça login com uma conta empresarial para adicionar editais ao funil.',
    );
  }

  if (response.statusCode != 200) {
    throw Exception(
      'Falha ao salvar edital no funil (HTTP ${response.statusCode})',
    );
  }
}

FutureListaRegistros listarAcompanhamentosFunil() async {
  final response = await http.get(
    Uri.parse('$apiLicitacoesUrl/api/acompanhamentos'),
    headers: SessaoUsuario.headersAutenticados,
  );

  if (response.statusCode == 401) {
    throw Exception(
      'Sessão não autenticada. Entre com sua conta para carregar o funil.',
    );
  }

  if (response.statusCode != 200) {
    throw Exception(
      'Erro ao carregar o funil (HTTP ${response.statusCode})',
    );
  }

  final lista = (jsonDecode(response.body) as List<dynamic>)
      .cast<RegistroJson>();

  final prefs = await SharedPreferences.getInstance();
  final excluidos = prefs.getStringList('licithub_funil_excluidos') ?? [];
  final overridesRaw = prefs.getString('licithub_funil_overrides');
  final overrides = overridesRaw != null
      ? RegistroJson.from(jsonDecode(overridesRaw) as Map)
      : <String, dynamic>{};

  return lista.where((item) {
    final id = (item['id'] ?? item['idAcompanhamento'] ?? '').toString();
    return !excluidos.contains(id);
  }).map((item) {
    final id = (item['id'] ?? item['idAcompanhamento'] ?? '').toString();
    if (overrides.containsKey(id)) {
      return {...item, 'status': overrides[id]};
    }
    return item;
  }).toList();
}

Future<void> moverCardFunil(
  int idAcompanhamento,
  String novoStatus,
) async {
  final prefs = await SharedPreferences.getInstance();
  final overridesRaw = prefs.getString('licithub_funil_overrides');
  final overrides = overridesRaw != null
      ? RegistroJson.from(jsonDecode(overridesRaw) as Map)
      : <String, dynamic>{};

  try {
    final response = await http.patch(
      Uri.parse(
        '$apiLicitacoesUrl/api/acompanhamentos/$idAcompanhamento/status',
      ),
      headers: SessaoUsuario.headersAutenticados,
      body: jsonEncode({'status': novoStatus}),
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      overrides.remove('$idAcompanhamento');
      await prefs.setString('licithub_funil_overrides', jsonEncode(overrides));
      return;
    }
  } catch (_) {}

  overrides['$idAcompanhamento'] = novoStatus;
  await prefs.setString('licithub_funil_overrides', jsonEncode(overrides));
}

Future<void> excluirCardFunil(int idAcompanhamento) async {
  try {
    await http.delete(
      Uri.parse('$apiLicitacoesUrl/api/acompanhamentos/$idAcompanhamento'),
      headers: SessaoUsuario.headersAutenticados,
    );
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();
  final excluidos = prefs.getStringList('licithub_funil_excluidos') ?? [];
  if (!excluidos.contains('$idAcompanhamento')) {
    excluidos.add('$idAcompanhamento');
    await prefs.setStringList('licithub_funil_excluidos', excluidos);
  }
}

class DocumentoEmpresa {
  final String id;
  final String titulo;
  final String nomeArquivo;
  final String extensao;
  final int tamanhoBytes;
  final DateTime dataEnvio;
  final DateTime? dataValidade;
  final String conteudoBase64;

  DocumentoEmpresa({
    required this.id,
    required this.titulo,
    required this.nomeArquivo,
    required this.extensao,
    required this.tamanhoBytes,
    required this.dataEnvio,
    this.dataValidade,
    required this.conteudoBase64,
  });

  RegistroJson toJson() => {
        'id': id,
        'titulo': titulo,
        'nomeArquivo': nomeArquivo,
        'extensao': extensao,
        'tamanhoBytes': tamanhoBytes,
        'dataEnvio': dataEnvio.toIso8601String(),
        'dataValidade': dataValidade?.toIso8601String(),
        'conteudoBase64': conteudoBase64,
      };

  factory DocumentoEmpresa.fromJson(RegistroJson json) {
    return DocumentoEmpresa(
      id: json['id'].toString(),
      titulo: json['titulo'].toString(),
      nomeArquivo: json['nomeArquivo'].toString(),
      extensao: json['extensao']?.toString() ?? 'pdf',
      tamanhoBytes: (json['tamanhoBytes'] as num?)?.toInt() ?? 0,
      dataEnvio: DateTime.tryParse(json['dataEnvio']?.toString() ?? '') ??
          DateTime.now(),
      dataValidade: json['dataValidade'] != null
          ? DateTime.tryParse(json['dataValidade'].toString())
          : null,
      conteudoBase64: json['conteudoBase64']?.toString() ?? '',
    );
  }
}

FutureListaDocs listarDocumentosEmpresa() async {
  final prefs = await SharedPreferences.getInstance();
  final chave = 'licithub_docs_${SessaoUsuario.emailUsuario}';
  final raw = prefs.getString(chave);
  if (raw == null || raw.isEmpty) return [];

  final lista = jsonDecode(raw) as List<dynamic>;
  return lista
      .map((item) => DocumentoEmpresa.fromJson(item as RegistroJson))
      .toList();
}

Future<void> salvarDocumentoEmpresa(DocumentoEmpresa doc) async {
  final atuais = await listarDocumentosEmpresa();
  atuais.insert(0, doc);
  final prefs = await SharedPreferences.getInstance();
  final chave = 'licithub_docs_${SessaoUsuario.emailUsuario}';
  await prefs.setString(
    chave,
    jsonEncode(atuais.map((d) => d.toJson()).toList()),
  );
}

Future<void> excluirDocumentoEmpresa(String id) async {
  final atuais = await listarDocumentosEmpresa();
  atuais.removeWhere((d) => d.id == id);
  final prefs = await SharedPreferences.getInstance();
  final chave = 'licithub_docs_${SessaoUsuario.emailUsuario}';
  await prefs.setString(
    chave,
    jsonEncode(atuais.map((d) => d.toJson()).toList()),
  );
}

String _extrairMensagemErro(String body, String padrao) {
  try {
    final json = jsonDecode(body);

    if (json is RegistroJson) {
      return json['detail']?.toString() ??
          json['title']?.toString() ??
          padrao;
    }
  } catch (_) {}

  return padrao;
}