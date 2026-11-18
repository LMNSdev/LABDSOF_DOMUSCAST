import 'dart:convert';
import 'package:http/http.dart' as http;

/// Erro HTTP da API, com o código para a app escolher a mensagem certa.
/// [codigo] vem do corpo `{codigo, mensagem, request_id}` (8.4), quando existe.
class ApiException implements Exception {
  final int statusCode;
  final String? codigo;
  ApiException(this.statusCode, [this.codigo]);

  @override
  String toString() => 'ApiException($statusCode, $codigo)';
}

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    this.baseUrl = 'http://10.0.2.2:8000',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> getReportes() async {
    final response = await _client.get(Uri.parse('$baseUrl/reportes'));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ${response.statusCode} ao carregar reportes');
  }

  Future<Map<String, dynamic>> criarReporte({
    required String descricao,
    String? fotoUrl,
    required String idempotencyKey,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/reportes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'descricao': descricao,
        if (fotoUrl != null) 'foto_url': fotoUrl,
        'idempotency_key': idempotencyKey,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erro ${response.statusCode} ao criar reporte');
  }

  // --- US-01: condomínio, frações e QR codes -------------------------------

  Map<String, String> _auth(String credencial) => {'Authorization': 'Bearer $credencial'};

  dynamic _corpo(http.Response r, int esperado) {
    if (r.statusCode != esperado) throw ApiException(r.statusCode, _codigo(r));
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  String? _codigo(http.Response r) {
    try {
      final corpo = jsonDecode(utf8.decode(r.bodyBytes));
      return corpo is Map<String, dynamic> ? corpo['codigo'] as String? : null;
    } on FormatException {
      return null;
    }
  }

  /// Devolve `{id, nome, n_fracoes, credencial_admin, fracoes}`.
  Future<Map<String, dynamic>> criarCondominio({
    required String nome,
    required String nomeAdmin,
    required int nFracoes,
  }) async {
    final r = await _client.post(
      Uri.parse('$baseUrl/condominios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome, 'nome_admin': nomeAdmin, 'n_fracoes': nFracoes}),
    );
    return _corpo(r, 201) as Map<String, dynamic>;
  }

  /// Lista `{id, designacao, n_residentes}` das frações do condomínio.
  Future<List<Map<String, dynamic>>> getFracoes(int condominioId, String credencial) async {
    final r = await _client.get(
      Uri.parse('$baseUrl/condominios/$condominioId/fracoes'),
      headers: _auth(credencial),
    );
    return (_corpo(r, 200) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Gera um novo QR para a fração; devolve `{token, link, fracao, criado_em}`.
  Future<Map<String, dynamic>> gerarQr(int fracaoId, String credencial) async {
    final r = await _client.post(
      Uri.parse('$baseUrl/fracoes/$fracaoId/qr'),
      headers: _auth(credencial),
    );
    return _corpo(r, 201) as Map<String, dynamic>;
  }

  // --- US-15: identidade do residente ---------------------------------------

  /// Cria a identidade com o token do QR code; devolve `{id, nome, fracao, credencial}`.
  /// Erros: 404 QR code inválido ou revogado, 409 `nome_duplicado` ou `fracao_cheia`,
  /// 422 nome vazio, 429 demasiadas tentativas.
  Future<Map<String, dynamic>> criarIdentidade({
    required String token,
    required String nome,
  }) async {
    final r = await _client.post(
      Uri.parse('$baseUrl/identidades'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'nome': nome}),
    );
    return _corpo(r, 201) as Map<String, dynamic>;
  }
}
