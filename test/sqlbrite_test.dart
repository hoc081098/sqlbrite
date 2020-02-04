@Timeout(Duration(seconds: 2))
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlbrite/sqlbrite.dart';
import 'package:sqlbrite/src/brite_database.dart';

import 'brite_database_test/brite_database_test.dart' as brite_database_test;
import 'mocks.dart';
import 'query_stream_test.dart' as query_stream_test;

void main() {
  Database db;
  BriteDatabase briteDb;

  setUp(() {
    db = MockDatabase();
    briteDb = BriteDatabase(db);
  });

  query_stream_test.main();
  brite_database_test.main();

  group('CreateRawQuery', () {
    test('delegates to db rawQuery', () async {
      final stream = briteDb.createRawQuery(
        ['Table'],
        'sql',
        ['whereArg'],
      );
      await (await stream.first)();

      verify(
        db.rawQuery(
          'sql',
          ['whereArg'],
        ),
      ).called(1);
    });

    test('triggers intial query', () async {
      final stream = briteDb.createRawQuery(['Table'], '');
      await expectLater(stream, emitsInOrder([isQuery]));
    });

    test('triggers query again on insert', () async {
      when(db.insert('Table', <String, Object>{}))
          .thenAnswer((_) => Future.value(0));

      final stream$ = briteDb.createRawQuery(['Table'], '');
      final expect = expectLater(
        stream$,
        emitsInOrder([
          isQuery,
          isQuery,
        ]),
      );

      await briteDb.insert('Table', <String, Object>{});
      await expect;
    });

    test('triggers query again on rawInsertAndTrigger', () async {
      when(db.insert('Table', <String, Object>{}))
          .thenAnswer((_) => Future.value(0));

      final stream$ = briteDb.createRawQuery(['Table'], '');
      final expect = expectLater(
        stream$,
        emitsInOrder([
          isQuery,
          isQuery,
        ]),
      );

      await briteDb.rawInsertAndTrigger(['Table'], '');
      await expect;
    });

    test('triggers query again on delete', () async {
      when(db.delete('Table')).thenAnswer((_) => Future.value(1));

      final stream$ = briteDb.createRawQuery(['Table'], '');
      final expect = expectLater(
        stream$,
        emitsInOrder([
          isQuery,
          isQuery,
        ]),
      );

      await briteDb.delete('Table');
      await expect;
    });

    test('triggers query again on rawDeleteAndTrigger', () async {
      when(db.rawDelete('')).thenAnswer((_) => Future.value(1));

      final stream$ = briteDb.createRawQuery(['Table'], '');
      final expect = expectLater(
        stream$,
        emitsInOrder([
          isQuery,
          isQuery,
        ]),
      );

      await briteDb.rawDeleteAndTrigger(['Table'], '');
      await expect;
    });

    test('triggers query again on update', () async {
      when(db.update('Table', <String, Object>{}))
          .thenAnswer((_) => Future.value(1));

      final stream$ = briteDb.createRawQuery(['Table'], '');
      final expect = expectLater(
        stream$,
        emitsInOrder([
          isQuery,
          isQuery,
        ]),
      );

      await briteDb.update('Table', {});
      await expect;
    });

    test('triggers query again on rawUpdateAndTrigger', () async {
      when(db.rawUpdate('')).thenAnswer((_) => Future.value(1));

      final stream$ = briteDb.createRawQuery(['Table'], '');
      final expect = expectLater(
        stream$,
        emitsInOrder([
          isQuery,
          isQuery,
        ]),
      );

      await briteDb.rawUpdateAndTrigger(['Table'], '');
      await expect;
    });

    test('triggers query again on executeAndTrigger', () async {
      when(db.execute('')).thenAnswer((_) => Future<int>.value(0));

      final stream$ = briteDb.createRawQuery(['Table'], '');
      final expect = expectLater(
        stream$,
        emitsInOrder([
          isQuery,
          isQuery,
        ]),
      );

      await briteDb.executeAndTrigger(['Table'], '');
      await expect;
    });
  });

  group('Transaction', () {
    test('triggers query again after transactionAndTrigger completes',
        () async {
      final transaction = MockTransaction();
      when(transaction.insert('Table', <String, dynamic>{}))
          .thenAnswer((_) => Future.value(0));

      when(
        db.transaction<dynamic>(
          any,
          exclusive: anyNamed('exclusive'),
        ),
      ).thenAnswer((invocation) {
        final f = invocation.positionalArguments[0] as Future<int> Function(
            Transaction);
        return f(transaction);
      });

      final stream$ = briteDb.createQuery('Table');
      final expect = expectLater(
        stream$,
        emitsInOrder([
          isQuery,
          isQuery,
        ]),
      );
      await briteDb.transactionAndTrigger<int>((transaction) {
        return transaction.insert(
          'Table',
          <String, dynamic>{},
        );
      });
      await expect;
    });
  });

  group('Batch', () {
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
