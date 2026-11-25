import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Última lista de reuniões recebida da API, por condomínio, para a mostrar
/// quando a API não responde (US-28, ecrã 4). Guardar por condomínio impede que
/// um administrador veja reuniões de outro condomínio no mesmo telemóvel. Os
/// ecrãs recebem a cache no construtor, para os testes usarem a
/// [MemoriaCacheReunioes] em vez do SQLite do telemóvel.
///
/// A cache é só uma alternativa: nunca lança erros. Se o armazenamento local
/// falhar, [guardar] não faz nada e [ler] devolve `null`.
abstract class CacheReunioes {
  Future<void> guardar(int condominioId, List<Map<String, dynamic>> reunioes);

  /// `null` se nunca foi guardada nenhuma lista deste condomínio.
  Future<List<Map<String, dynamic>>?> ler(int condominioId);
}

class SqliteCacheReunioes implements CacheReunioes {
  static Database? _db;

  static const _criar =
      'CREATE TABLE ultima_lista (condominio_id INTEGER PRIMARY KEY, json TEXT NOT NULL)';

  static Future<Database> get _database async => _db ??= await openDatabase(
        join(await getDatabasesPath(), 'reunioes.db'),
        version: 2,
        onCreate: (db, _) => db.execute(_criar),
        // A versão 1 guardava uma só lista, sem condomínio: não se aproveita.
        onUpgrade: (db, _, __) async {
          await db.execute('DROP TABLE IF EXISTS ultima_lista');
          await db.execute(_criar);
        },
      );

  @override
  Future<void> guardar(int condominioId, List<Map<String, dynamic>> reunioes) async {
    try {
      final db = await _database;
      await db.insert('ultima_lista', {'condominio_id': condominioId, 'json': jsonEncode(reunioes)},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      // Sem armazenamento local (ex.: plugin indisponível): a lista vem da API.
      return;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> ler(int condominioId) async {
    try {
      final db = await _database;
      final linhas =
          await db.query('ultima_lista', where: 'condominio_id = ?', whereArgs: [condominioId]);
      if (linhas.isEmpty) return null;
      return (jsonDecode(linhas.first['json'] as String) as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }
}

/// Usada nos testes.
class MemoriaCacheReunioes implements CacheReunioes {
  final Map<int, List<Map<String, dynamic>>> listas;

  MemoriaCacheReunioes([Map<int, List<Map<String, dynamic>>>? listas]) : listas = listas ?? {};

  @override
  Future<void> guardar(int condominioId, List<Map<String, dynamic>> reunioes) async =>
      listas[condominioId] = List.of(reunioes);

  @override
  Future<List<Map<String, dynamic>>?> ler(int condominioId) async => listas[condominioId];
}
