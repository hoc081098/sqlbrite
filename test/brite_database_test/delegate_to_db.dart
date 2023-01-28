import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqlbrite/src/brite_database.dart';

import '../mocks.mocks.dart';

void main() {
  group('Delegates to db', () {
    late MockDatabase db;
    late BriteDatabase briteDb;

    setUp(() {
      db = MockDatabase();
      briteDb = BriteDatabase(db);
    });

    test('delegates to db query', () async {
      const table = 'Table';
      const distinct = true;
      final columns = ['column'];
      const where = 'where';
      final whereArgs = ['whereArg'];
      const groupBy = 'groupBy';
      const having = 'having';
      const orderBy = 'orderBy';
      const limit = 1;
      const offset = 1;

      when(
        db.query(
          table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        ),
      ).thenAnswer((_) => Future.value(<Map<String, Object?>>[]));

      await briteDb.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );

      verify(
        db.query(
          table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        ),
      ).called(1);
    });

    test('delegates to db rawQuery', () async {
      const sql = 'sql';
      final arguments = ['whereArg'];

      when(
        db.rawQuery(
          sql,
          arguments,
        ),
      ).thenAnswer((realInvocation) => Future.value([]));

      await briteDb.rawQuery(
        sql,
        arguments,
      );

      verify(
        db.rawQuery(
          sql,
          arguments,
        ),
      );
    });

    test('delegates to db insert', () async {
      when(
        db.insert(
          'Table',
          <String, Object?>{},
          conflictAlgorithm: ConflictAlgorithm.fail,
        ),
      ).thenAnswer((realInvocation) => Future.value(1));

      await briteDb.insert(
        'Table',
        <String, Object?>{},
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      verify(
        db.insert(
          'Table',
          <String, Object?>{},
          conflictAlgorithm: ConflictAlgorithm.fail,
        ),
      );
    });

    test('delegates to db rawInsert', () async {
      when(db.rawInsert('sql', ['arg']))
          .thenAnswer((realInvocation) => Future.value(0));
      await briteDb.rawInsert('sql', ['arg']);
      verify(db.rawInsert('sql', ['arg']));
    });

    test('delegates to db delete', () async {
      const table = 'Table';

      when(
        db.delete(
          table,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) => Future.value(1));

      await briteDb.delete(
        table,
        where: 'where',
        whereArgs: ['whereArg'],
      );

      verify(
        db.delete(
          table,
          where: 'where',
          whereArgs: ['whereArg'],
        ),
      );
    });

    test('delegates to db rawDelete', () async {
      const sql = 'sql';
      const arguments = ['arg'];

      when(
        db.rawDelete(sql, arguments),
      ).thenAnswer((_) => Future.value(1));

      await briteDb.rawDelete(sql, arguments);

      verify(db.rawDelete(sql, arguments));
    });

    test('delegates to db update', () async {
      const table = 'Table';
      const values = <String, Object?>{};
      const where = 'where';
      const whereArgs = ['whereArg'];
      const algorithm = ConflictAlgorithm.fail;

      when(
        db.update(
          table,
          values,
          where: where,
          whereArgs: whereArgs,
          conflictAlgorithm: algorithm,
        ),
      ).thenAnswer((_) => Future.value(1));

      await briteDb.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: algorithm,
      );

      verify(
        db.update(
          table,
          values,
          where: where,
          whereArgs: whereArgs,
          conflictAlgorithm: algorithm,
        ),
      );
    });

    test('delegates to db rawUpdate', () async {
      const sql = 'sql';
      const arguments = ['arg'];

      when(db.rawUpdate(sql, arguments)).thenAnswer((_) => Future.value(1));

      await briteDb.rawUpdate(sql, arguments);

      verify(db.rawUpdate(sql, arguments));
    });

    test('delegates to db execute', () async {
      await briteDb.execute('sql', ['arg']);
      verify(db.execute('sql', ['arg']));
    });

    test('delegates to db path', () {
      when(db.path).thenReturn('expected');
      briteDb.path;
      verify(db.path).called(1);
    });

    test('delegates to db isOpen', () {
      when(db.isOpen).thenReturn(true);
      briteDb.isOpen;
      verify(db.isOpen).called(1);
    });

    test('delegates to db close', () async {
      when(db.close()).thenAnswer((realInvocation) => Future.value(null));
      await briteDb.close();
      verify(db.close()).called(1);
    });

    test('delegates to db devInvokeMethod', () {
      const method = 'method';
      const arguments = 1;

      when(db.devInvokeMethod<void>(method, arguments))
          .thenAnswer((realInvocation) => Future.value(null));

      // ignore: deprecated_member_use, deprecated_member_use_from_same_package
      briteDb.devInvokeMethod<void>(method, arguments);

      verify(db.devInvokeMethod<void>(method, arguments)).called(arguments);
    });

    test('delegates to db devInvokeSqlMethod', () {
      const method = 'method';
      const sql = 'sql';
      const arguments = [1];

      when(db.devInvokeSqlMethod<void>(method, sql, arguments))
          .thenAnswer((realInvocation) => Future.value(null));

      // ignore: deprecated_member_use, deprecated_member_use_from_same_package
      briteDb.devInvokeSqlMethod<void>(method, sql, arguments);

      verify(db.devInvokeSqlMethod<void>(method, sql, arguments)).called(1);
    });

    test('delegates to db transaction', () async {
      Future<int> action(Transaction transaction) {
        return transaction.insert(
          'Table',
          <String, Object?>{},
        );
      }

      when(db.transaction(action))
          .thenAnswer((realInvocation) => Future.value(1));

      await briteDb.transaction(action);

      verify(db.transaction(action)).called(1);
    });

    test('delegates to db queryCursor', () async {
      const table = 'Table';
      const distinct = true;
      final columns = ['column'];
      const where = 'where';
      final whereArgs = ['whereArg'];
      const groupBy = 'groupBy';
      const having = 'having';
      const orderBy = 'orderBy';
      const limit = 1;
      const offset = 1;
      const bufferSize = 1;

      when(
        db.queryCursor(
          table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
          bufferSize: bufferSize,
        ),
      ).thenAnswer((_) => Future.value(MockQueryCursor()));

      await briteDb.queryCursor(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
        bufferSize: bufferSize,
      );

      verify(
        db.queryCursor(
          table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
          bufferSize: bufferSize,
        ),
      ).called(1);
    });

    test('delegates to db rawQueryCursor', () async {
      const sql = 'sql';
      final arguments = ['whereArg'];
      const bufferSize = 1;

      when(
        db.rawQueryCursor(
          sql,
          arguments,
          bufferSize: bufferSize,
        ),
      ).thenAnswer((_) => Future.value(MockQueryCursor()));

      await briteDb.rawQueryCursor(
        sql,
        arguments,
        bufferSize: bufferSize,
      );

      verify(
        db.rawQueryCursor(
          sql,
          arguments,
          bufferSize: bufferSize,
        ),
      ).called(1);
    });
  });
}
