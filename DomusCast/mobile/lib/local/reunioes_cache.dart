import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Última lista de reuniões recebida da API, para a mostrar quando a API não
/// responde (US-28, ecrã 4). Os ecrãs recebem a cache no construtor, para os
/// testes usarem a [MemoriaCacheReunioes] em vez do SQLite do telemóvel.
///
/// A cache é só uma alternativa: nunca lança erros. Se o armazenamento local
/// falhar, [guardar] não faz nada e [ler] devolve `null`.
abstract class CacheReunioes {
  Future<void> guardar(List<Map<String, dynamic>> reunioes);

  /// `null` se nunca foi guardada nenhuma lista.
  Future<List<Map<String, dynamic>>?> ler();
}

class SqliteCacheReunioes implements CacheReunioes {
  static Database? _db;

  static Future<Database> get _database async => _db ??= await openDatabase(
        join(await getDatabasesPath(), 'reunioes.db'),
        version: 1,
        onCreate: (db, _) => db.execute(
          'CREATE TABLE ultima_lista (id INTEGER PRIMARY KEY CHECK (id = 1), json TEXT NOT NULL)',
        ),
      );

  @override
  Future<void> guardar(List<Map<String, dynamic>> reunioes) async {
    try {
      final db = await _database;
      await db.insert('ultima_lista', {'id': 1, 'json': jsonEncode(reunioes)},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      // Sem armazenamento local (ex.: plugin indisponível): a lista vem da API.
      return;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> ler() async {
    try {
      final db = await _database;
      final linhas = await db.query('ultima_lista', where: 'id = 1');
      if (linhas.isEmpty) return null;
      return (jsonDecode(linhas.first['json'] as String) as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }
}

/// Usada nos testes.
class MemoriaCacheReunioes implements CacheReunioes {
  List<Map<String, dynamic>>? lista;

  MemoriaCacheReunioes([this.lista]);

  @override
  Future<void> guardar(List<Map<String, dynamic>> reunioes) async => lista = List.of(reunioes);

  @override
  Future<List<Map<String, dynamic>>?> ler() async => lista;
}
