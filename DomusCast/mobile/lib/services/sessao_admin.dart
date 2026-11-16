import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sessão do administrador guardada no telemóvel depois de criar o condomínio (US-01).
class SessaoAdmin {
  final int condominioId;
  final String nomeCondominio;
  final String credencial;

  const SessaoAdmin({
    required this.condominioId,
    required this.nomeCondominio,
    required this.credencial,
  });

  Map<String, dynamic> toJson() => {
        'condominio_id': condominioId,
        'nome_condominio': nomeCondominio,
        'credencial': credencial,
      };

  factory SessaoAdmin.fromJson(Map<String, dynamic> j) => SessaoAdmin(
        condominioId: j['condominio_id'] as int,
        nomeCondominio: j['nome_condominio'] as String,
        credencial: j['credencial'] as String,
      );

  @override
  bool operator ==(Object other) =>
      other is SessaoAdmin &&
      other.condominioId == condominioId &&
      other.nomeCondominio == nomeCondominio &&
      other.credencial == credencial;

  @override
  int get hashCode => Object.hash(condominioId, nomeCondominio, credencial);
}

abstract class SessaoAdminStore {
  Future<SessaoAdmin?> ler();
  Future<void> guardar(SessaoAdmin sessao);
}

/// Guarda a credencial no armazenamento seguro do sistema (Android Keystore).
class SeguraSessaoAdminStore implements SessaoAdminStore {
  static const _chave = 'sessao_admin';
  final FlutterSecureStorage _storage;

  SeguraSessaoAdminStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<SessaoAdmin?> ler() async {
    try {
      final raw = await _storage.read(key: _chave);
      if (raw == null) return null;
      return SessaoAdmin.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Sem armazenamento seguro disponível (ex.: testes) ou dados corrompidos.
      return null;
    }
  }

  @override
  Future<void> guardar(SessaoAdmin sessao) =>
      _storage.write(key: _chave, value: jsonEncode(sessao.toJson()));
}

/// Usado nos testes.
class MemoriaSessaoAdminStore implements SessaoAdminStore {
  SessaoAdmin? _sessao;

  MemoriaSessaoAdminStore([this._sessao]);

  @override
  Future<SessaoAdmin?> ler() async => _sessao;

  @override
  Future<void> guardar(SessaoAdmin sessao) async => _sessao = sessao;
}
