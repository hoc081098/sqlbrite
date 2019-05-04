@Timeout(const Duration(seconds: 2))
import 'dart:async';

import "package:flutter_test/flutter_test.dart";
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlbrite/sqlbrite.dart';
import 'package:test_api/test_api.dart' show TypeMatcher;
import 'package:test_api/test_api.dart' as prefix0;

const typeMatcherQuery = TypeMatcher<Query>();

void main() {
  Database db;
  BriteDatabase briteDb;

  setUp(() {
    db = MockDatabase();
    briteDb = BriteDatabase(db);
  });

  group('$QueryObservable', () {
    test('Create $QueryObservable from $Stream', () async {
      await expectLater(
        QueryObservable(Stream.empty()),
        emitsDone,
      );
    });

    test('Create $QueryObservable from $Stream', () async {
      await expectLater(
        QueryObservable(
          Stream<Query>.fromIterable(
            [
              () => Future.value([<String, dynamic>{}])
            ],
          ),
        ).mapToOneOrDefault((row) => row),
        emits(<String, dynamic>{}),
      );
    });
  });

  group('createQuery', () {
    test('delegates to db query', () async {
      final stream$ = briteDb.createQuery(
        "Table",
        distinct: true,
        columns: ["column"],
        where: "where",
        whereArgs: ["whereArg"],
        groupBy: "groupBy",
        having: "having",
        orderBy: "orderBy",
        limit: 1,
        offset: 1,
      );
      (await stream$.first)();

      /// execute [Query]

      verify(
        db.query(
          "Table",
          distinct: true,
          columns: ["column"],
          where: "where",
          whereArgs: <dynamic>["whereArg"],
          groupBy: "groupBy",
          having: "having",
          orderBy: "orderBy",
          limit: 1,
          offset: 1,
        ),
      ).called(1);
    });

    test('triggers intial query', () async {
      final QueryObservable stream$ = briteDb.createQuery("Table");
      expect(
        stream$,
        emits(typeMatcherQuery),
      );
    });

    test('triggers query again on insert', () async {
      when(db.insert("Table", <String, dynamic>{}))
          .thenAnswer((_) => Future.value(0));

      final QueryObservable stream$ = briteDb.createQuery("Table");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.insert("Table", <String, dynamic>{});
      await expect;
    });

    test(
      'triggers query multiple time',
      () async {
        const table = 'Table';
        when(db.insert(table, <String, dynamic>{}))
            .thenAnswer((_) => Future.value(0));
        var count = 0;
        when(db.query(table)).thenAnswer(
          (_) {
            ++count;
            return count.isEven
                ? Future.delayed(
                    const Duration(seconds: 2),
                    () => <Map<String, dynamic>>[
                          {'count': count}
                        ],
                  )
                : null;
          },
        );

        final QueryObservable stream$ = briteDb.createQuery(table);
        final Future<void> ex = expectLater(
          stream$.mapToOneOrDefault((r) => r),
          emitsInOrder([
            {'count': 2},
            {'count': 4},
            {'count': 6},
            {'count': 8},
            {'count': 10},
          ]),
        );

        briteDb.insert(table, {}); //1
        briteDb.insert(table, {}); //2
        briteDb.insert(table, {}); //3
        briteDb.insert(table, {}); //4
        briteDb.insert(table, {}); //5
        briteDb.insert(table, {}); //6
        briteDb.insert(table, {}); //7
        briteDb.insert(table, {}); //8
        briteDb.insert(table, {}); //9
        briteDb.insert(table, {}); //10

        await ex;
      },
      timeout: Timeout(Duration(seconds: 30)),
    );

    test('triggers query again on rawInsertAndTrigger', () async {
      when(db.insert("Table", <String, Object>{}))
          .thenAnswer((_) => Future.value(0));

      final QueryObservable stream$ = briteDb.createQuery("Table");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.rawInsertAndTrigger(["Table"], "");
      await expect;
    });

    test("triggers query again on delete", () async {
      when(db.delete("Table")).thenAnswer((_) => Future.value(1));

      final QueryObservable stream$ = briteDb.createQuery("Table");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.delete("Table");
      await expect;
    });

    test('triggers query again on rawDeleteAndTrigger', () async {
      when(db.rawDelete("")).thenAnswer((_) => Future.value(1));

      final QueryObservable stream$ = briteDb.createQuery("Table");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.rawDeleteAndTrigger(["Table"], "");
      await expect;
    });

    test('triggers query again on update', () async {
      when(db.update("Table", <String, Object>{}))
          .thenAnswer((_) => Future.value(1));
      final QueryObservable stream$ = briteDb.createQuery("Table");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.update("Table", {});
      await expect;
    });

    test('triggers query again on rawUpdateAndTrigger', () async {
      when(db.rawUpdate("")).thenAnswer((_) => Future.value(1));

      final QueryObservable stream$ = briteDb.createQuery("Table");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.rawUpdateAndTrigger(["Table"], "");
      await expect;
    });

    test("triggers query again on executeAndTrigger", () async {
      when(db.execute("")).thenAnswer((_) => Future<int>.value(0));

      final QueryObservable stream$ = briteDb.createQuery("Table");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.executeAndTrigger(["Table"], "");
      await expect;
    });
  });

  group('createRawQuery', () {
    test('delegates to db rawQuery', () async {
      final stream = briteDb.createRawQuery(
        ["Table"],
        "sql",
        ["whereArg"],
      );
      (await stream.first)();

      verify(
        db.rawQuery(
          "sql",
          <dynamic>["whereArg"],
        ),
      ).called(1);
    });

    test('triggers intial query', () async {
      final stream = briteDb.createRawQuery(["Table"], "");
      await expectLater(stream, emitsInOrder([typeMatcherQuery]));
    });

    test("triggers query again on insert", () async {
      when(db.insert("Table", <String, Object>{}))
          .thenAnswer((_) => Future.value(0));

      final QueryObservable stream$ = briteDb.createRawQuery(["Table"], "");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.insert("Table", <String, Object>{});
      await expect;
    });

    test("triggers query again on rawInsertAndTrigger", () async {
      when(db.insert("Table", <String, Object>{}))
          .thenAnswer((_) => Future.value(0));

      final QueryObservable stream$ = briteDb.createRawQuery(["Table"], "");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.rawInsertAndTrigger(["Table"], "");
      await expect;
    });

    test("triggers query again on delete", () async {
      when(db.delete("Table")).thenAnswer((_) => Future.value(1));

      final QueryObservable stream$ = briteDb.createRawQuery(["Table"], "");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.delete("Table");
      await expect;
    });

    test("triggers query again on rawDeleteAndTrigger", () async {
      when(db.rawDelete("")).thenAnswer((_) => Future.value(1));

      final QueryObservable stream$ = briteDb.createRawQuery(["Table"], "");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.rawDeleteAndTrigger(["Table"], "");
      await expect;
    });

    test("triggers query again on update", () async {
      when(db.update("Table", <String, Object>{}))
          .thenAnswer((_) => Future.value(1));

      final QueryObservable stream$ = briteDb.createRawQuery(["Table"], "");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.update("Table", {});
      await expect;
    });

    test("triggers query again on rawUpdateAndTrigger", () async {
      when(db.rawUpdate("")).thenAnswer((_) => Future.value(1));

      final stream$ = briteDb.createRawQuery(["Table"], "");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.rawUpdateAndTrigger(["Table"], "");
      await expect;
    });

    test("triggers query again on executeAndTrigger", () async {
      when(db.execute("")).thenAnswer((_) => Future<int>.value(0));

      final QueryObservable stream$ = briteDb.createRawQuery(["Table"], "");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      await briteDb.executeAndTrigger(["Table"], "");
      await expect;
    });
  });

  group("Delegates to db", () {
    test("delegates to db query", () async {
      await briteDb.query(
        "Table",
        distinct: true,
        columns: ["column"],
        where: "where",
        whereArgs: ["whereArg"],
        groupBy: "groupBy",
        having: "having",
        orderBy: "orderBy",
        limit: 1,
        offset: 1,
      );
      verify(db.query(
        "Table",
        distinct: true,
        columns: ["column"],
        where: "where",
        whereArgs: <dynamic>["whereArg"],
        groupBy: "groupBy",
        having: "having",
        orderBy: "orderBy",
        limit: 1,
        offset: 1,
      ));
    });

    test("delegates to db rawQuery", () async {
      await briteDb.rawQuery(
        "sql",
        <String>["whereArg"],
      );
      verify(db.rawQuery(
        "sql",
        <dynamic>["whereArg"],
      ));
    });

    test("delegates to db insert", () async {
      await briteDb.insert("Table", <String, Object>{},
          conflictAlgorithm: ConflictAlgorithm.fail);
      verify(db.insert("Table", <String, dynamic>{},
          conflictAlgorithm: ConflictAlgorithm.fail));
    });

    test("delegates to db rawInsert", () async {
      await briteDb.rawInsertAndTrigger(["Table"], "sql", <String>["arg"]);
      verify(db.rawInsert("sql", <dynamic>["arg"]));
    });

    test("delegates to db delete", () async {
      when(db.delete(
              // ignore: argument_type_not_assignable
              any,
              // ignore: argument_type_not_assignable
              where: anyNamed("where"),
              // ignore: argument_type_not_assignable
              whereArgs: anyNamed("whereArgs")))
          .thenAnswer((_) => Future.value(1));
      await briteDb.delete("Table", where: "where", whereArgs: ["whereArg"]);
      verify(
          db.delete("Table", where: "where", whereArgs: <dynamic>["whereArg"]));
    });

    test("delegates to db rawDelete", () async {
      when(db.rawDelete(
              // ignore: argument_type_not_assignable
              any,
              // ignore: argument_type_not_assignable
              any))
          .thenAnswer((_) => Future.value(1));
      await briteDb.rawDeleteAndTrigger(["Table"], "sql", ["arg"]);
      verify(db.rawDelete("sql", <dynamic>["arg"]));
    });

    test("delegates to db update", () async {
      when(db.update(
              // ignore: argument_type_not_assignable
              any,
              // ignore: argument_type_not_assignable
              any,
              // ignore: argument_type_not_assignable
              where: anyNamed("where"),
              // ignore: argument_type_not_assignable
              whereArgs: anyNamed("whereArgs"),
              // ignore: argument_type_not_assignable
              conflictAlgorithm: anyNamed("conflictAlgorithm")))
          .thenAnswer((_) => Future.value(1));
      await briteDb.update("Table", {},
          where: "where",
          whereArgs: ["whereArg"],
          conflictAlgorithm: ConflictAlgorithm.fail);
      verify(db.update("Table", <String, dynamic>{},
          where: "where",
          whereArgs: <dynamic>["whereArg"],
          conflictAlgorithm: ConflictAlgorithm.fail));
    });

    test("delegates to db rawUpdate", () async {
      when(db.rawUpdate(
              // ignore: argument_type_not_assignable
              any,
              // ignore: argument_type_not_assignable
              any))
          .thenAnswer((_) => Future.value(1));
      await briteDb.rawUpdateAndTrigger(["Table"], "sql", ["arg"]);
      verify(db.rawUpdate("sql", <dynamic>["arg"]));
    });

    test("delegates to db execute", () async {
      await briteDb.execute("sql", <String>["arg"]);
      verify(db.execute("sql", <dynamic>["arg"]));
    });
  });

  group("transaction", () {
    test("triggers query again after transactionAndTrigger completes",
        () async {
      final transaction = MockTransaction();
      when(transaction.insert("Table", <String, dynamic>{}))
          .thenAnswer((_) => Future.value(0));

      when(
        db.transaction<dynamic>(
          any,
          exclusive: anyNamed("exclusive"),
        ),
      ).thenAnswer((invocation) {
        Function f = invocation.positionalArguments[0] as Function;
        Future<int> result = f(transaction) as Future<int>;
        return result;
      });

      final QueryObservable stream$ = briteDb.createQuery("Table");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );
      await briteDb.transactionAndTrigger<int>((transaction) {
        return transaction.insert("Table", <String, Object>{});
      });
      await expect;
    });
  });

  group("batch", () {
    test("trigger query again after batch is commited", () async {
      final batch = MockBatch();

      when(db.batch()).thenAnswer((_) => batch);
      when(batch.insert("Table", <String, Object>{}))
          .thenAnswer((_) => Future.value(0));

      final QueryObservable stream$ = briteDb.createQuery("Table");
      final Future<void> expect = expectLater(
        stream$,
        emitsInOrder([
          typeMatcherQuery,
          typeMatcherQuery,
        ]),
      );

      final streamBatch = briteDb.batch();
      streamBatch.insert("Table", <String, Object>{});
      await streamBatch.commit();

      await expect;
    });

    test(
      "trigger query again after batch is commited (multiple operations)",
      () async {
        final batch = MockBatch();
        const table = 'table';

        when(db.batch()).thenAnswer((_) => batch);
        when(batch.insert(table, <String, Object>{}))
            .thenAnswer((_) => Future.value(0));

        final QueryObservable stream$ = briteDb.createQuery(table);

        stream$.listen(
          prefix0.expectAsync1(
            (v) {
              expect(v, typeMatcherQuery);
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

class MockDatabase extends Mock implements Database {}

class MockTransaction extends Mock implements Transaction {}

class MockBatch extends Mock implements Batch {}
