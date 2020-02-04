import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqlbrite/src/brite_database.dart';

import '../mocks.dart';

void main() {
  group('Delegates to db', () {
    Database db;
    BriteDatabase briteDb;

    setUp(() {
      db = MockDatabase();
      briteDb = BriteDatabase(db);
    });

    test('delegates to db query', () async {
      await briteDb.query(
        'Table',
        distinct: true,
        columns: ['column'],
        where: 'where',
        whereArgs: ['whereArg'],
        groupBy: 'groupBy',
        having: 'having',
        orderBy: 'orderBy',
        limit: 1,
        offset: 1,
      );
      verify(
        db.query(
          'Table',
          distinct: true,
          columns: ['column'],
          where: 'where',
          whereArgs: ['whereArg'],
          groupBy: 'groupBy',
          having: 'having',
          orderBy: 'orderBy',
          limit: 1,
          offset: 1,
        ),
      );
    });

    test('delegates to db rawQuery', () async {
      await briteDb.rawQuery(
        'sql',
        ['whereArg'],
      );
      verify(
        db.rawQuery(
          'sql',
          ['whereArg'],
        ),
      );
    });

    test('delegates to db insert', () async {
      await briteDb.insert(
        'Table',
        <String, dynamic>{},
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      verify(
        db.insert(
          'Table',
          <String, dynamic>{},
          conflictAlgorithm: ConflictAlgorithm.fail,
        ),
      );
    });

    test('delegates to db rawInsert', () async {
      await briteDb.rawInsert(
        'sql',
        ['arg'],
      );
      verify(db.rawInsert('sql', ['arg']));
    });

    test('delegates to db delete', () async {
      when(
        db.delete(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) => Future.value(1));
      await briteDb.delete(
        'Table',
        where: 'where',
        whereArgs: ['whereArg'],
      );
      verify(
        db.delete(
          'Table',
          where: 'where',
          whereArgs: ['whereArg'],
        ),
      );
    });

    test('delegates to db rawDelete', () async {
      when(
        db.rawDelete(any, any),
      ).thenAnswer((_) => Future.value(1));
      await briteDb.rawDelete('sql', ['arg']);
      verify(db.rawDelete('sql', ['arg']));
    });

    test('delegates to db update', () async {
      when(
        db.update(
          any,
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          conflictAlgorithm: anyNamed('conflictAlgorithm'),
        ),
      ).thenAnswer((_) => Future.value(1));
      await briteDb.update(
        'Table',
        <String, dynamic>{},
        where: 'where',
        whereArgs: ['whereArg'],
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      verify(
        db.update(
          'Table',
          <String, dynamic>{},
          where: 'where',
          whereArgs: <dynamic>['whereArg'],
          conflictAlgorithm: ConflictAlgorithm.fail,
        ),
      );
    });

    test('delegates to db rawUpdate', () async {
      when(db.rawUpdate(any, any)).thenAnswer((_) => Future.value(1));
      await briteDb.rawUpdate('sql', ['arg']);
      verify(db.rawUpdate('sql', ['arg']));
    });

    test('delegates to db execute', () async {
      await briteDb.execute('sql', ['arg']);
      verify(db.execute('sql', ['arg']));
    });

    test('delegates to db path', () {
      briteDb.path;
      verify(db.path).called(1);
    });

    test('delegates to db isOpen', () {
      briteDb.isOpen;
      verify(db.isOpen).called(1);
    });

    test('delegates to db close', () {
      briteDb.close();
      verify(db.close()).called(1);
    });

    test('delegates to db getVersion', () {
      briteDb.getVersion();
      verify(db.getVersion()).called(1);
    });

    test('delegates to db setVersion', () {
      briteDb.setVersion(1);
      verify(db.setVersion(1)).called(1);
    });

    test('delegates to db devInvokeMethod', () {
      // ignore: deprecated_member_use_from_same_package
      briteDb.devInvokeMethod('');
      // ignore: deprecated_member_use
      verify(db.devInvokeMethod('')).called(1);
    });

    test('delegates to db devInvokeSqlMethod', () {
      // ignore: deprecated_member_use_from_same_package
      briteDb.devInvokeSqlMethod('', '');
      // ignore: deprecated_member_use
      verify(db.devInvokeSqlMethod('', '')).called(1);
    });
  });
}
