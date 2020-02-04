import 'package:example/data/item.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:random_string/random_string.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlbrite/sqlbrite.dart';

const _tableItems = 'items';

Future<Database> _open() async {
  final directory = await getApplicationDocumentsDirectory();
  final path = join(directory.path, 'example.db');
  return await openDatabase(
    path,
    version: 1,
    onCreate: (Database db, int version) async {
      await db.execute(
        '''
          CREATE TABLE $_tableItems( 
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
              content TEXT NOT NULL,
              createdAt TEXT NOT NULL
          )
        ''',
      );

      final batch = db.batch();
      for (int i = 0; i < 10; i++) {
        batch.insert(
          _tableItems,
          Item(
            null,
            randomString(20),
            DateTime.now(),
          ).toJson(),
        );
      }
      final list = await batch.commit(
        continueOnError: true,
        noResult: false,
      );
      print('Batch result: $list');
    },
  );
}

class AppDb {
  static AppDb _singleton;

  AppDb._();

  factory AppDb.getInstance() => _singleton ??= AppDb._();

  final _dbFuture = _open().then((db) => BriteDatabase(db));

  Stream<List<Item>> getAllItems() async* {
    final db = await _dbFuture;
    yield* db
        .createQuery(_tableItems, orderBy: 'createdAt DESC')
        .mapToList((json) => Item.fromJson(json));
  }

  Future<bool> insert(Item item) async {
    final db = await _dbFuture;
    final id = await db.insert(
      _tableItems,
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id != -1;
  }

  Future<bool> remove(Item item) async {
    final db = await _dbFuture;
    final rows = await db.delete(
      _tableItems,
      where: 'id = ?',
      whereArgs: [item.id],
    );
    return rows > 0;
  }
}