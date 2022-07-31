import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqlbrite/sqlbrite.dart';
import 'package:sqlbrite/src/brite_database.dart';

import '../mocks.dart';
import '../mocks.mocks.dart';

void main() {
  group('Batch', () {
    late MockDatabase db;
    late BriteDatabase briteDb;

    setUp(() {
      db = MockDatabase();
      briteDb = BriteDatabase(db);
    });

    test('trigger query again after batch is committed', () async {
      const table = 'Table';

      final mockBatch = MockBatch();
      when(db.batch()).thenAnswer((_) => mockBatch);
      expect(db.batch(), mockBatch);
      when(mockBatch.commit()).thenAnswer((realInvocation) => Future.value([]));

      final streamBatch = briteDb.batch();

      final stream$ = briteDb.createQuery(table);
      final future = expectLater(
        stream$,
        emitsInOrder(<Matcher>[
          isQuery, // initial
          isQuery, // commit
        ]),
      );

      // trigger
      streamBatch.insert(table, <String, Object?>{});
      streamBatch.delete(table);
      streamBatch.update(table, <String, Object?>{});

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

      await future;
    });

    test(
      'Trigger query again after batch is commited (multiple operations)',
      () async {
        final batch = MockBatch();
        const table = 'table';

        when(db.batch()).thenAnswer((_) => batch);
        when(batch.insert(table, <String, Object?>{}))
            .thenAnswer((_) => Future.value(0));
        when(batch.commit()).thenAnswer((realInvocation) => Future.value([]));

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
          streamBatch.insert(table, <String, Object?>{});
        }
        await streamBatch.commit();
      },
    );
  });
}
