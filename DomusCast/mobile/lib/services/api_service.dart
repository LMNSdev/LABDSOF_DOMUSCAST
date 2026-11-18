import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Erro HTTP da API, com o código para a app escolher a mensagem certa.
/// [codigo] vem do corpo `{codigo, mensagem, request_id}` (8.4), quando existe.
class ApiException implements Exception {
  final int statusCode;
  final String? codigo;
  final String? mensagem;
  ApiException(this.statusCode, {this.codigo, this.mensagem});

  @override
  String toString() => mensagem ?? 'ApiException($statusCode, $codigo)';
}

/// Endereço da API. Definido no build com `--dart-define=API_BASE_URL=...`
/// (o APK da pipeline aponta para a VM em HTTPS); sem ele, usa o host da
/// máquina vista a partir do emulador Android.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class ApiService {
  static const _maxFotoBytes = 5 * 1024 * 1024;

  final String baseUrl;
  final http.Client _client;

  ApiService({
    this.baseUrl = kApiBaseUrl,
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
    required String credencial,
    required String descricao,
    Uint8List? fotoBytes,
    String? fotoNome,
    String? fotoAlt,
    bool mostrarNome = false,
    required String idempotencyKey,
  }) async {
    MediaType? tipoFoto;
    if (fotoBytes != null) {
      if (fotoBytes.length > _maxFotoBytes) {
        throw ArgumentError('A foto não pode exceder 5 MB.');
      }
      if (fotoNome == null || fotoAlt?.trim().isEmpty != false) {
        throw ArgumentError(
          'Foto e texto alternativo são obrigatórios em conjunto.',
        );
      }
      final extensao = fotoNome.split('.').last.toLowerCase();
      tipoFoto = switch (extensao) {
        'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
        'png' => MediaType('image', 'png'),
        _ => throw ArgumentError('A foto tem de ser JPEG ou PNG.'),
      };
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/reportes'),
    )
      ..headers.addAll({
        ..._auth(credencial),
        'Idempotency-Key': idempotencyKey,
      })
      ..fields.addAll({
        'descricao': descricao,
        'mostrar_nome': mostrarNome.toString(),
        if (fotoAlt != null) 'foto_alt': fotoAlt,
      });

    if (fotoBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto',
          fotoBytes,
          filename: fotoNome,
          contentType: tipoFoto,
        ),
      );
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _apiException(response);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  // --- US-01: condomínio, frações e QR codes -------------------------------

  Map<String, String> _auth(String credencial) =>
      {'Authorization': 'Bearer $credencial'};

  dynamic _corpo(http.Response r, int esperado) {
    if (r.statusCode != esperado) throw _apiException(r);
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  ApiException _apiException(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        return ApiException(
          response.statusCode,
          codigo: body['codigo'] as String?,
          mensagem: body['mensagem'] as String?,
        );
      }
    } on FormatException {
      return ApiException(response.statusCode);
    }
    return ApiException(response.statusCode);
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
      body: jsonEncode(
          {'nome': nome, 'nome_admin': nomeAdmin, 'n_fracoes': nFracoes}),
    );
    return _corpo(r, 201) as Map<String, dynamic>;
  }

  /// Lista `{id, designacao, n_residentes}` das frações do condomínio.
  Future<List<Map<String, dynamic>>> getFracoes(
      int condominioId, String credencial) async {
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
