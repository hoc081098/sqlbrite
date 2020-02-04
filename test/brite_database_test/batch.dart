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
      final batch = MockBatch();

      when(db.batch()).thenAnswer((_) => batch);
      when(
        batch.insert(
          'Table',
          <String, dynamic>{},
        ),
      ).thenAnswer((_) => Future.value(0));

      final stream$ = briteDb.createQuery('Table');
      final expect = expectLater(
        stream$,
        emitsInOrder([
          isQuery,
          isQuery,
        ]),
      );

      final streamBatch = briteDb.batch();
      streamBatch.insert(
        'Table',
        <String, dynamic>{},
      );
      await streamBatch.commit();

      await expect;
    });

    test(
      'trigger query again after batch is commited (multiple operations)',
      () async {
        final batch = MockBatch();
        const table = 'table';

        when(db.batch()).thenAnswer((_) => batch);
        when(batch.insert(table, <String, Object>{}))
            .thenAnswer((_) => Future.value(0));

        final stream$ = briteDb.createQuery(table);

        stream$.listen(
          expectAsync1(
            (v) {
              expect(v, isQuery);
            },
            count: 2,
            max: 2,
          ),
        );

        final streamBatch = briteDb.batch();
        streamBatch.insert(table, <String, dynamic>{});
        streamBatch.insert(table, <String, dynamic>{});
        streamBatch.insert(table, <String, dynamic>{});
        streamBatch.insert(table, <String, dynamic>{});
        streamBatch.insert(table, <String, dynamic>{});
        streamBatch.insert(table, <String, dynamic>{});
        streamBatch.insert(table, <String, dynamic>{});
        streamBatch.insert(table, <String, dynamic>{});
        streamBatch.insert(table, <String, dynamic>{});
        streamBatch.insert(table, <String, dynamic>{});
        await streamBatch.commit();
      },
      timeout: Timeout(Duration(seconds: 10)),
    );
  });
}
