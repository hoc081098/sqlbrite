import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqlbrite/src/brite_database.dart';
import 'package:sqlbrite/src/query_stream.dart';

import '../mocks.dart';
import '../mocks.mocks.dart';

void main() {
  group('CreateRawQuery', () {
    late Database db;
    late BriteDatabase briteDb;
    late Map<String, Object?>? defaultValue;

    setUp(() {
      db = MockDatabase();
      briteDb = BriteDatabase(db);
      defaultValue = null;
    });

    test('Delegates to db rawQuery', () async {
      final stream = briteDb.createRawQuery(
        ['Table'],
        'sql',
        ['whereArg'],
      );

      // execute Query
      await (await stream.first)();

      verify(
        db.rawQuery(
          'sql',
          ['whereArg'],
        ),
      ).called(1);
    });

    test('Triggers intial query', () async {
      final stream = briteDb.createRawQuery(['Table'], 'sql');
      await expectLater(
        stream,
        emits(isQuery),
      );
    });

    group('Insert', () {
      test('Triggers query again on insert', () async {
        when(db.insert('Table', <String, Object?>{}))
            .thenAnswer((_) => Future.value(0));

        final stream$ = briteDb.createRawQuery(['Table'], 'sql');
        final expect = expectLater(
          stream$,
          emitsInOrder(<Matcher>[
            isQuery,
            isQuery,
          ]),
        );

        await briteDb.insert('Table', <String, Object?>{});
        await expect;
      });

      test('Triggers query multiple times on insert', () async {
        const table = 'Table';

        // mocking insert
        var id = 0;
        when(db.insert(table, <String, Object?>{}))
            .thenAnswer((_) => Future.value(id++));

        // mocking query
        var count = 0;
        when(db.rawQuery('sql')).thenAnswer(
          (_) {
            ++count;
            return Future.delayed(
              const Duration(milliseconds: 100),
              () => count.isEven
                  ? [
                      {'count': count}
                    ]
                  : [],
            );
          },
        );

        final stream$ = briteDb.createRawQuery([table], 'sql');
        final ex = expectLater(
          stream$.mapToOneOrDefault((r) => r, defaultValue),
          emitsInOrder(<Object?>[
            defaultValue,
            {'count': 2},
            defaultValue,
            {'count': 4},
            defaultValue,
            {'count': 6},
            defaultValue,
            {'count': 8},
            defaultValue,
            {'count': 10},
          ]),
        );

        for (var i = 0; i < 10; i++) {
          await briteDb.insert(table, <String, Object?>{});
        }

        await ex;
      });

      test('Triggers query again on rawInsertAndTrigger', () async {
        when(db.insert('Table', <String, Object>{}))
            .thenAnswer((_) => Future.value(0));

        final stream$ = briteDb.createRawQuery(['Table'], 'sql');
        final expect = expectLater(
          stream$,
          emitsInOrder(<Matcher>[
            isQuery,
            isQuery,
          ]),
        );

        await briteDb.rawInsertAndTrigger(['Table'], '');
        await expect;
      });
    });

    group('Delete', () {
      test('Triggers query again on delete', () async {
        when(db.delete('Table')).thenAnswer((_) => Future.value(1));

        final stream$ = briteDb.createRawQuery(['Table'], 'sql');
        final expect = expectLater(
          stream$,
          emitsInOrder(<Matcher>[
            isQuery,
            isQuery,
          ]),
        );

        await briteDb.delete('Table');
        await expect;
      });

      test('Triggers query multiple times on delete', () async {
        const table = 'Table';

        // mocking delete
        when(db.delete(table)).thenAnswer((_) => Future.value(1));

        // mocking query
        var count = 0;
        when(db.rawQuery('sql')).thenAnswer(
          (_) {
            ++count;
            return Future.delayed(
              const Duration(milliseconds: 100),
              () => count.isEven
                  ? [
                      {'count': count}
                    ]
                  : [],
            );
          },
        );

        final stream$ = briteDb.createRawQuery([table], 'sql');
        final ex = expectLater(
          stream$.mapToOneOrDefault((r) => r, defaultValue),
          emitsInOrder(<Object?>[
            defaultValue,
            {'count': 2},
            defaultValue,
            {'count': 4},
            defaultValue,
            {'count': 6},
            defaultValue,
            {'count': 8},
            defaultValue,
            {'count': 10},
          ]),
        );

        for (var i = 0; i < 10; i++) {
          await briteDb.delete(table);
        }

        await ex;
      });

      test('Triggers query again on rawDeleteAndTrigger', () async {
        when(db.rawDelete('')).thenAnswer((_) => Future.value(1));

        final stream$ = briteDb.createRawQuery(['Table'], 'sql');
        final expect = expectLater(
          stream$,
          emitsInOrder(<Matcher>[
            isQuery,
            isQuery,
          ]),
        );

        await briteDb.rawDeleteAndTrigger(['Table'], '');
        await expect;
      });
    });

    group('Update', () {
      test('Triggers query again on update', () async {
        when(db.update('Table', <String, Object>{}))
            .thenAnswer((_) => Future.value(1));
        final stream$ = briteDb.createRawQuery(['Table'], 'sql');
        final expect = expectLater(
          stream$,
          emitsInOrder(<Matcher>[
            isQuery,
            isQuery,
          ]),
        );

        await briteDb.update('Table', {});
        await expect;
      });

      test('Triggers query multiple times on update', () async {
        const table = 'Table';

        // mocking update
        when(db.update(table, <String, Object?>{}))
            .thenAnswer((_) => Future.value(1));

        // mocking query
        var count = 0;
        when(db.rawQuery('sql')).thenAnswer(
          (_) {
            ++count;
            return Future.delayed(
              const Duration(milliseconds: 100),
              () => count.isEven
                  ? [
                      {'count': count}
                    ]
                  : [],
            );
          },
        );

        final stream$ = briteDb.createRawQuery([table], 'sql');
        final ex = expectLater(
          stream$.mapToOneOrDefault((r) => r, defaultValue),
          emitsInOrder(<Object?>[
            defaultValue,
            {'count': 2},
            defaultValue,
            {'count': 4},
            defaultValue,
            {'count': 6},
            defaultValue,
            {'count': 8},
            defaultValue,
            {'count': 10},
          ]),
        );

        for (var i = 0; i < 10; i++) {
          await briteDb.update(table, <String, Object?>{});
        }

        await ex;
      });

      test('Triggers query again on rawUpdateAndTrigger', () async {
        when(db.rawUpdate('')).thenAnswer((_) => Future.value(1));

        final stream$ = briteDb.createRawQuery(['Table'], 'sql');
        final expect = expectLater(
          stream$,
          emitsInOrder(<Matcher>[
            isQuery,
            isQuery,
          ]),
        );

        await briteDb.rawUpdateAndTrigger(['Table'], '');
        await expect;
      });
    });

    test('Triggers query again on executeAndTrigger', () async {
      when(db.execute('')).thenAnswer((_) => Future<int>.value(0));

      final stream$ = briteDb.createRawQuery(['Table'], 'sql');
      final expect = expectLater(
        stream$,
        emitsInOrder(<Matcher>[
          isQuery,
          isQuery,
        ]),
      );

      await briteDb.executeAndTrigger(['Table'], '');
      await expect;
    });
  });
}
