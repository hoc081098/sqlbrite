import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlbrite/sqlbrite.dart';
import 'package:sqlbrite/src/brite_database.dart';

import '../mocks.dart';

void main() {
  group('Batch', () {
    Database db;
    BriteDatabase briteDb;

    setUp(() {
      db = MockDatabase();
      briteDb = BriteDatabase(db);
    });

    test('trigger query again after batch is commited', () async {
      const table = 'Table';

      when(db.batch()).thenAnswer((_) => MockBatch());

      final stream$ = briteDb.createQuery(table);
      final expect = expectLater(
        stream$,
        emitsInOrder([
          isQuery, // initial
          isQuery, // commit
        ]),
      );

      final streamBatch = briteDb.batch();

      // trigger
      streamBatch.insert(table, <String, dynamic>{});
      streamBatch.delete(table);
      streamBatch.update(table, <String, dynamic>{});

      // ...trigger
      streamBatch.executeAndTrigger([table], 'sql');
      streamBatch.rawDeleteAndTrigger([table], 'sql');
      streamBatch.rawInsertAndTrigger([table], 'sql');
      streamBatch.rawUpdateAndTrigger([table], 'sql');

      // nothing
      streamBatch.execute('sql');
      streamBatch.rawUpdate('sql');
      streamBatch.rawDelete('sql');
      streamBatch.rawUpdate('sql');
      streamBatch.query(table);
      streamBatch.rawQuery('sql');

      await streamBatch.commit();

      await expect;
    });

    test('Trigger query again after batch is commited (multiple operations)',
        () async {
      final batch = MockBatch();
      const table = 'table';

      when(db.batch()).thenAnswer((_) => batch);
      when(batch.insert(table, <String, dynamic>{}))
          .thenAnswer((_) => Future.value(0));

      final stream$ = briteDb.createQuery(table);

      stream$.listen(
        expectAsync1(
          (v) => expect(v, isQuery),
          count: 2,
          max: 2,
        ),
      );

      final streamBatch = briteDb.batch();
      for (var i = 0; i <= 10; i++) {
        streamBatch.insert(table, <String, dynamic>{});
      }
      await streamBatch.commit();
    });
  });
}
