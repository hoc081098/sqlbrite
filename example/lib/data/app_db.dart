import 'package:example/data/item.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlbrite/sqlbrite.dart';

import 'faker.dart';

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
            contents.random(),
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
  static final _singleton = AppDb._();

  AppDb._();

  factory AppDb.getInstance() => _singleton;

  final _dbFuture = _open()
      .then((db) => BriteDatabase(db, logger: kReleaseMode ? null : print));

  Stream<List<Item>> getAllItems() async* {
    final db = await _dbFuture;
    yield* db
        .createQuery(_tableItems, orderBy: 'createdAt DESC')
        .mapToList((json) => Item.fromJson(json))
        .map((items) =>
            items.where((i) => i.id != null).toList(growable: false));
  }

  Future<bool> insert(Item item) async {
    if (item.id != null) {
      throw StateError('Item.id must be null');
    }

    final db = await _dbFuture;
    final id = await db.insert(
      _tableItems,
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id != -1;
  }

  Future<bool> remove(Item item) async {
    final id = ArgumentError.checkNotNull(item.id);

    final db = await _dbFuture;
    final rows = await db.delete(
      _tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows > 0;
  }

  Future<bool> update(Item item) async {
    final id = ArgumentError.checkNotNull(item.id);

    final db = await _dbFuture;
    final rows = await db.update(
      _tableItems,
      item.toJson(),
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return rows > 0;
  }
}
