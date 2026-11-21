import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Identidade do residente guardada no telemóvel no primeiro acesso (US-15).
class SessaoResidente {
  final String credencial;
  final String nome;
  final String fracao;

  const SessaoResidente({
    required this.credencial,
    required this.nome,
    required this.fracao,
  });

  Map<String, dynamic> toJson() => {'credencial': credencial, 'nome': nome, 'fracao': fracao};

  factory SessaoResidente.fromJson(Map<String, dynamic> j) => SessaoResidente(
        credencial: j['credencial'] as String,
        nome: j['nome'] as String,
        fracao: j['fracao'] as String,
      );
}

abstract class SessaoResidenteStore {
  Future<SessaoResidente?> ler();
  Future<void> guardar(SessaoResidente sessao);

  /// Apaga a credencial, quando a identidade foi removida (US-23).
  Future<void> apagar();
}

/// Guarda a credencial no armazenamento seguro do sistema (Android Keystore).
class SeguraSessaoResidenteStore implements SessaoResidenteStore {
  static const _chave = 'sessao_residente';
  final FlutterSecureStorage _storage;

  SeguraSessaoResidenteStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<SessaoResidente?> ler() async {
    try {
      final raw = await _storage.read(key: _chave);
      if (raw == null) return null;
      return SessaoResidente.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Sem armazenamento seguro disponível (ex.: testes) ou dados corrompidos.
      return null;
    }
  }

  @override
  Future<void> guardar(SessaoResidente sessao) =>
      _storage.write(key: _chave, value: jsonEncode(sessao.toJson()));

  @override
  Future<void> apagar() => _storage.delete(key: _chave);
}

/// Usado nos testes.
class MemoriaSessaoResidenteStore implements SessaoResidenteStore {
  SessaoResidente? _sessao;

  MemoriaSessaoResidenteStore([this._sessao]);

  @override
  Future<SessaoResidente?> ler() async => _sessao;

  @override
  Future<void> guardar(SessaoResidente sessao) async => _sessao = sessao;

  @override
  Future<void> apagar() async => _sessao = null;
}
