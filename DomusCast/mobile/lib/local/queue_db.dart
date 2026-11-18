import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class QueueDb {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'queue.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE pending_reportes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          descricao TEXT NOT NULL,
          foto_url TEXT,
          idempotency_key TEXT NOT NULL,
          mostrar_nome INTEGER NOT NULL DEFAULT 0,
          criado_em INTEGER NOT NULL
        )
      '''),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE pending_reportes ADD COLUMN mostrar_nome INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  static Future<void> enqueue({
    required String descricao,
    String? fotoUrl,
    required String idempotencyKey,
    bool mostrarNome = false,
  }) async {
    final database = await db;
    await database.insert('pending_reportes', {
      'descricao': descricao,
      'foto_url': fotoUrl,
      'idempotency_key': idempotencyKey,
      'mostrar_nome': mostrarNome ? 1 : 0,
      'criado_em': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<Map<String, dynamic>>> getPending() async {
    final database = await db;
    return database.query('pending_reportes', orderBy: 'criado_em ASC');
  }

  static Future<void> remove(int id) async {
    final database = await db;
    await database.delete('pending_reportes', where: 'id = ?', whereArgs: [id]);
  }
}

/// Reportes por enviar. Os ecrãs recebem a fila no construtor, para os testes
/// usarem a [MemoriaFilaReportes] em vez do SQLite do telemóvel.
abstract class FilaReportes {
  Future<void> guardar({
    required String descricao,
    String? fotoUrl,
    required String idempotencyKey,
    bool mostrarNome = false,
  });

  /// Linhas com `id`, `descricao`, `foto_url`, `idempotency_key` e `mostrar_nome` (0 ou 1).
  Future<List<Map<String, dynamic>>> pendentes();

  Future<void> remover(int id);
}

class SqliteFilaReportes implements FilaReportes {
  @override
  Future<void> guardar({
    required String descricao,
    String? fotoUrl,
    required String idempotencyKey,
    bool mostrarNome = false,
  }) =>
      QueueDb.enqueue(
        descricao: descricao,
        fotoUrl: fotoUrl,
        idempotencyKey: idempotencyKey,
        mostrarNome: mostrarNome,
      );

  @override
  Future<List<Map<String, dynamic>>> pendentes() => QueueDb.getPending();

  @override
  Future<void> remover(int id) => QueueDb.remove(id);
}

/// Usada nos testes.
class MemoriaFilaReportes implements FilaReportes {
  final List<Map<String, dynamic>> linhas = [];
  int _proximoId = 1;

  @override
  Future<void> guardar({
    required String descricao,
    String? fotoUrl,
    required String idempotencyKey,
    bool mostrarNome = false,
  }) async =>
      linhas.add({
        'id': _proximoId++,
        'descricao': descricao,
        'foto_url': fotoUrl,
        'idempotency_key': idempotencyKey,
        'mostrar_nome': mostrarNome ? 1 : 0,
      });

  @override
  Future<List<Map<String, dynamic>>> pendentes() async => List.of(linhas);

  @override
  Future<void> remover(int id) async => linhas.removeWhere((l) => l['id'] == id);
}
