import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlbrite/sqlbrite.dart';

import '../mocks.dart';
import '../mocks.mocks.dart';
import 'utils.dart';

void main() {
  group('Batch', () {
    late BriteDatabase briteDb;

    setUp(() {
      briteDb = BriteDatabase(MockDatabase());
    });

    tearDown(() async {
      await briteDb.close();
    });

    test('trigger query again after batch is committed', () async {
      const streamTable = 'Test_stream';
      const testTable = 'Test';
      const placeholderTable = 'Placeholder';

      briteDb =
          BriteDatabase(await initDeleteDbAndOpen('batch_transaction.db'));

      await briteDb.execute(
          'CREATE TABLE $streamTable (id INTEGER PRIMARY KEY, name TEXT)');
      await briteDb
          .execute('CREATE TABLE $placeholderTable (id INTEGER PRIMARY KEY)');

      final streamBatch = briteDb.batch();
      final stream$ = briteDb.createQuery(streamTable);
      final future = expectLater(
        stream$,
        emitsInOrder(<Matcher>[
          isQuery, // initial
          isQuery, // commit
        ]),
      );

      // create test table
      streamBatch.execute(
          'CREATE TABLE $testTable (id INTEGER PRIMARY KEY, name TEXT)');

      // trigger
      streamBatch.insert(streamTable, <String, Object?>{'name': 'item1'});
      streamBatch.insert(testTable, <String, Object?>{'name': 'item1'});
      streamBatch.update(
        streamTable,
        <String, Object?>{'name': 'updated-1'},
        where: 'id = ?',
        whereArgs: [1],
      );
      streamBatch.update(
        testTable,
        <String, Object?>{'name': 'updated-1'},
        where: 'id = ?',
        whereArgs: [1],
      );
      streamBatch.delete(placeholderTable);

      // ...trigger
      streamBatch
          .executeAndTrigger([streamTable], 'SELECT * FROM $streamTable');
      streamBatch.executeAndTrigger([testTable], 'SELECT * FROM $testTable');

      streamBatch.rawDeleteAndTrigger(
          [streamTable], 'DELETE FROM $streamTable WHERE id = ?', [1]);
      streamBatch.rawDeleteAndTrigger(
          [testTable], 'DELETE FROM $testTable WHERE id = ?', [1]);

      streamBatch.rawInsertAndTrigger([streamTable],
          'INSERT INTO $streamTable(name) VALUES (?)', ['updated-2']);
      streamBatch.rawInsertAndTrigger([testTable],
          'INSERT INTO $testTable(name) VALUES (?)', ['updated-2']);

      streamBatch.rawUpdateAndTrigger([streamTable],
          'UPDATE $streamTable SET name = ? WHERE id = ?', ['updated-3', 1]);
      streamBatch.rawUpdateAndTrigger([testTable],
          'UPDATE $testTable SET name = ? WHERE id = ?', ['updated-3', 1]);

      // nothing
      streamBatch.execute('SELECT * FROM $streamTable');
      streamBatch.rawUpdate(
          'UPDATE $streamTable SET name = ? WHERE id = ?', ['@', -1]);
      streamBatch.rawDelete('DELETE FROM $streamTable WHERE id = ?', [-1]);
      streamBatch.query(streamTable);
      streamBatch.rawQuery('SELECT * FROM $streamTable');

      final result = await streamBatch.commit();
      expect(
        result,
        <Object?>[
          null, // execute - create
          1, // insert
          1, // insert
          1, // update
          1, // update
          0, // delete
          null, // execute - select
          null, // execute - select
          1, // delete
          1, // delete
          1, // insert
          1, // insert
          1, // update
          1, // update
          null, // execute - select
          0, // update
          0, // delete
          [
            {'id': 1, 'name': 'updated-3'}
          ], // query
          [
            {'id': 1, 'name': 'updated-3'}
          ], // rawQuery
        ],
      );
      expect(
        (await briteDb.query(testTable)).single,
        {'id': 1, 'name': 'updated-3'},
      );
      expect(
        (await briteDb.query(streamTable)).single,
        {'id': 1, 'name': 'updated-3'},
      );
      await future;
    });

    test('batch in manual transaction', () async {
      const streamTable = 'stream_table';

      briteDb = BriteDatabase(
          await initDeleteDbAndOpen('batch_custom_transaction.db'));

      await briteDb.execute(
          'CREATE TABLE $streamTable(id INTEGER PRIMARY KEY, name TEXT)');
      expect(
        briteDb.createQuery(streamTable),
        emitsInOrder(<Object>[
          isQuery, // initial
          isQuery, // apply
        ]),
      );

      await briteDb.execute('BEGIN');

      final batch = briteDb.batch();
      batch
        ..execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)')
        ..rawInsert(
          'INSERT INTO Test (name) VALUES (?)',
          ['item1'],
        )
        ..rawInsertAndTrigger(
          [streamTable],
          'INSERT INTO $streamTable(name) VALUES (?)',
          ['item1'],
        )
        ..insert(streamTable, {'name': 'item2'});

      await batch.apply(noResult: true);
      await briteDb.execute('COMMIT');

      // Sanity check too see whether values have been written
      expect(
        (await briteDb.rawQuery('SELECT * FROM Test')).single,
        {'id': 1, 'name': 'item1'},
      );
      expect(
        await briteDb.rawQuery('SELECT * FROM $streamTable'),
        [
          {'id': 1, 'name': 'item1'},
          {'id': 2, 'name': 'item2'},
        ],
      );
    });

    test(
      'Trigger query again after batch is committed (multiple operations)',
      () async {
        briteDb =
            BriteDatabase(await initDeleteDbAndOpen('batch_stream_query.db'));

        const testTable1 = 'test_table_1';
        const testTable2 = 'test_table_2';
        await briteDb.execute(
            'CREATE TABLE $testTable1(id INTEGER PRIMARY KEY, name TEXT)');
        await briteDb.execute(
            'CREATE TABLE $testTable2(id INTEGER PRIMARY KEY, name TEXT)');

        expect(
          briteDb.createQuery(testTable1),
          emitsInOrder(<Object>[
            isQuery, // initial
            isQuery, // commit
          ]),
        );

        final completer = Completer<void>.sync();

        final expected = [
          <Map<String, dynamic>>[],
          List.generate(11, (i) => {'name': 'name-$i', 'id': (i + 1)}),
        ];
        var index = 0;
        briteDb.createQuery(testTable2).mapToList((row) => row).listen(
              expectAsync1(
                (list) {
                  expect(list, expected[index++]);
                  if (!completer.isCompleted) completer.complete();
                },
                count: 2,
              ),
            );

        // await until the first query is triggered
        await completer.future;

        final streamBatch = briteDb.batch();
        for (var i = 0; i <= 10; i++) {
          streamBatch.insert(testTable1, <String, Object?>{'name': 'name-$i'});
          streamBatch.insert(testTable2, <String, Object?>{'name': 'name-$i'});
        }
        await streamBatch.commit(noResult: true);
      },
    );
  });
}
