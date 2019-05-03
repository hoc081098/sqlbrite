import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

typedef Future<List<Map<String, dynamic>>> Query();

typedef void Logger(String message);

abstract class IBriteDatabaseExecutor {
  Future<void> executeAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);

  Future<int> rawDeleteAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);

  Future<int> rawUpdateAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);

  Future<int> rawInsertAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);
}

abstract class IBriteDatabase {
  QueryObservable createQuery(
    String table, {
    bool distinct,
    List<String> columns,
    String where,
    List<dynamic> whereArgs,
    String groupBy,
    String having,
    String orderBy,
    int limit,
    int offset,
  });

  QueryObservable createRawQuery(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);

  Future<T> transactionAndTrigger<T>(Future<T> action(BriteTransaction txn),
      {bool exclusive});
}

abstract class BriteDatabaseExecutor
    implements DatabaseExecutor, IBriteDatabaseExecutor {
  final DatabaseExecutor _delegate;

  BriteDatabaseExecutor(this._delegate);

  void _sendTableTrigger(Iterable<String> tables);

  @override
  Future<void> execute(String sql, [List<dynamic> arguments]) =>
      _delegate.execute(sql, arguments);

  @override
  Future<void> executeAndTrigger(Iterable<String> tables, String sql,
      [List<dynamic> arguments]) async {
    await execute(sql, arguments);
    _sendTableTrigger(tables);
  }

  @override
  BriteBatch batch() => BriteBatch(this, _delegate.batch());

  @override
  Future<int> delete(String table,
      {String where, List<dynamic> whereArgs}) async {
    final int rows =
        await _delegate.delete(table, where: where, whereArgs: whereArgs);
    if (rows > 0) {
      _sendTableTrigger({table});
    }
    return rows;
  }

  @override
  Future<int> rawDelete(String sql, [List<dynamic> arguments]) =>
      _delegate.rawDelete(sql, arguments);

  @override
  Future<int> rawDeleteAndTrigger(Iterable<String> tables, String sql,
      [List<dynamic> arguments]) async {
    final int rows = await rawDelete(sql, arguments);
    if (rows > 0) {
      _sendTableTrigger(tables);
    }
    return rows;
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values,
      {String where,
      List<dynamic> whereArgs,
      ConflictAlgorithm conflictAlgorithm}) async {
    final int rows = await _delegate.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
    if (rows > 0) {
      _sendTableTrigger({table});
    }
    return rows;
  }

  @override
  Future<int> rawUpdate(String sql, [List<dynamic> arguments]) =>
      _delegate.rawUpdate(sql, arguments);

  @override
  Future<int> rawUpdateAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]) async {
    final int rows = await rawUpdate(sql, arguments);
    if (rows > 0) {
      _sendTableTrigger(tables);
    }
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
          [List<dynamic> arguments]) =>
      _delegate.rawQuery(sql, arguments);

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {bool distinct,
      List<String> columns,
      String where,
      List<dynamic> whereArgs,
      String groupBy,
      String having,
      String orderBy,
      int limit,
      int offset}) {
    return _delegate.query(
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
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values,
      {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) async {
    final int id = await _delegate.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
    if (id != -1) {
      _sendTableTrigger({table});
    }
    return id;
  }

  @override
  Future<int> rawInsert(String sql, [List<dynamic> arguments]) =>
      _delegate.rawInsert(sql, arguments);

  @override
  Future<int> rawInsertAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]) async {
    final int id = await rawInsert(sql, arguments);
    if (id != -1) {
      _sendTableTrigger(tables);
    }
    return id;
  }
}

class BriteDatabase extends BriteDatabaseExecutor
    implements Database, IBriteDatabase {
  final PublishSubject<Set<String>> _triggers = PublishSubject<Set<String>>();
  final Database _db;

  BriteDatabase(this._db) : super(_db);

  @override
  void _sendTableTrigger(Iterable<String> tables) {
    _triggers.add(tables.toSet());
  }

  QueryObservable createQuery(
    String table, {
    bool distinct,
    List<String> columns,
    String where,
    List<dynamic> whereArgs,
    String groupBy,
    String having,
    String orderBy,
    int limit,
    int offset,
  }) {
    return _createQuery(
      {table},
      () {
        return _db.query(
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
      },
    );
  }

  QueryObservable createRawQuery(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]) {
    return _createQuery(
      tables,
      () => _db.rawQuery(sql, arguments),
    );
  }

  QueryObservable _createQuery(Iterable<String> tables, Query query) {
    final Observable<Query> queryObservable = _triggers
        .where((strings) {
          return tables.any((table) {
            return strings.contains(table);
          });
        })
        .map((_) => query)
        .startWith(query);
    return QueryObservable(queryObservable);
  }

  @override
  Future<void> close() => _db.close();

  @deprecated
  @override
  Future<T> devInvokeMethod<T>(String method, [arguments]) =>
      _db.devInvokeMethod(method, arguments);

  @deprecated
  @override
  Future<T> devInvokeSqlMethod<T>(String method, String sql,
          [List arguments]) =>
      _db.devInvokeSqlMethod(method, sql, arguments);

  @override
  Future<int> getVersion() => _db.getVersion();

  @override
  bool get isOpen => _db.isOpen;

  @override
  String get path => _db.path;

  @override
  Future<void> setVersion(int version) => _db.setVersion(version);

  @override
  Future<T> transaction<T>(Future<T> action(Transaction txn),
          {bool exclusive}) =>
      _db.transaction(action, exclusive: exclusive);

  @override
  Future<T> transactionAndTrigger<T>(
    Future<T> Function(BriteTransaction txn) action, {
    bool exclusive,
  }) async {
    final tables = <String>{};
    final T result = await _db.transaction(
      (txn) {
        final briteTransaction = BriteTransaction(txn, tables);
        return action(briteTransaction);
      },
      exclusive: exclusive,
    );
    _sendTableTrigger(tables);
    return result;
  }
}

class BriteTransaction extends BriteDatabaseExecutor implements Transaction {
  final Set<String> _tables;

  BriteTransaction(Transaction txn, this._tables) : super(txn);

  @override
  void _sendTableTrigger(Iterable<String> tables) {
    _tables.addAll(tables);
  }
}

class BriteBatch implements Batch {
  final BriteDatabaseExecutor _executor;
  final Batch _delegate;
  final _tables = <String>{};

  BriteBatch(this._executor, this._delegate);

  @override
  Future<List> commit(
      {bool exclusive, bool noResult, bool continueOnError}) async {
    final List list = await _delegate.commit(
      exclusive: exclusive,
      noResult: noResult,
      continueOnError: continueOnError,
    );
    _executor._sendTableTrigger(_tables);
    return list;
  }

  @override
  void delete(String table, {String where, List whereArgs}) {
    _delegate.delete(table, whereArgs: whereArgs, where: where);
    _tables.add(table);
  }

  @override
  void execute(String sql, [List arguments]) {
    _delegate.execute(sql, arguments);
  }

  @override
  void insert(
    String table,
    Map<String, dynamic> values, {
    String nullColumnHack,
    ConflictAlgorithm conflictAlgorithm,
  }) {
    _delegate.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
    _tables.add(table);
  }

  @override
  void query(String table,
      {bool distinct,
      List<String> columns,
      String where,
      List whereArgs,
      String groupBy,
      String having,
      String orderBy,
      int limit,
      int offset}) {
    _delegate.query(
      table,
      distinct: distinct,
      columns: columns,
      whereArgs: whereArgs,
      where: where,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    _tables.add(table);
  }

  @override
  void rawDelete(String sql, [List arguments]) {
    _delegate.rawDelete(sql, arguments);
  }

  @override
  void rawInsert(String sql, [List arguments]) {
    _delegate.rawInsert(sql, arguments);
  }

  @override
  void rawQuery(String sql, [List arguments]) {
    _delegate.rawQuery(sql, arguments);
  }

  @override
  void rawUpdate(String sql, [List arguments]) {
    _delegate.rawUpdate(sql, arguments);
  }

  @override
  void update(String table, Map<String, dynamic> values,
      {String where, List whereArgs, ConflictAlgorithm conflictAlgorithm}) {
    _delegate.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
    _tables.add(table);
  }

  void rawDeleteAndTrigger(Iterable<String> tables, String sql,
      [List arguments]) {
    rawDelete(sql, arguments);
    _tables.addAll(tables);
  }

  void rawInsertAndTrigger(Iterable<String> tables, String sql,
      [List arguments]) {
    rawInsert(sql, arguments);
    _tables.addAll(tables);
  }

  void rawUpdateAndTrigger(Iterable<String> tables, String sql,
      [List arguments]) {
    rawUpdate(sql, arguments);
    _tables.addAll(tables);
  }
}

///
///
///

class QueryObservable extends Observable<Query> {
  final Stream<Query> _stream;

  QueryObservable(this._stream) : super(_stream);

  Observable<T> mapToOne<T>(T mapper(Map<String, dynamic> row),
          {T defaultValue}) =>
      _stream.transform(_QueryToOneStreamTransformer(mapper, defaultValue));

  Observable<List<T>> mapToList<T>(T mapper(Map<String, dynamic> row)) =>
      _stream.transform(_QueryToListStreamTransformer(mapper));
}

class _QueryToOneStreamTransformer<T> extends StreamTransformerBase<Query, T> {
  final StreamTransformer<Query, T> _transformer;

  _QueryToOneStreamTransformer(
      T mapper(Map<String, dynamic> row), T defaultValue)
      : _transformer = _buildTransformer(mapper, defaultValue);

  @override
  Stream<T> bind(Stream<Query> stream) => _transformer.bind(stream);

  static StreamTransformer<Query, T> _buildTransformer<T>(
    T mapper(Map<String, dynamic> row),
    T defaultValue,
  ) {
    return StreamTransformer<Query, T>((
      Stream<Query> input,
      bool cancelOnError,
    ) {
      StreamController<T> controller;
      StreamSubscription<Query> subscription;

      add(List<Map<String, dynamic>> rows) {
        if (rows.length > 1) {
          controller.addError(StateError('Query returned more than 1 row'));
          return;
        }
        if (rows.isEmpty) {
          controller.add(defaultValue);
          return;
        }
        controller.add(mapper(rows[0]));
      }

      controller = StreamController<T>(
        sync: true,
        onListen: () {
          subscription = input.listen(
            (Query query) {
              Future<List<Map<String, dynamic>>> newValue;
              try {
                newValue = query();
              } catch (e, s) {
                controller.addError(e, s);
                return;
              }
              subscription.pause();
              newValue
                  ?.then(add, onError: controller.addError)
                  ?.whenComplete(subscription.resume);
            },
            onError: controller.addError,
            onDone: controller.close,
            cancelOnError: cancelOnError,
          );
        },
        onPause: subscription.pause,
        onResume: subscription.resume,
        onCancel: subscription.cancel,
      );

      return controller.stream.listen(null);
    });
  }
}

class _QueryToListStreamTransformer<T>
    extends StreamTransformerBase<Query, List<T>> {
  final StreamTransformer<Query, List<T>> _transformer;

  _QueryToListStreamTransformer(T mapper(Map<String, dynamic> row))
      : _transformer = _buildTransformer(mapper);

  @override
  Stream<List<T>> bind(Stream<Query> stream) => _transformer.bind(stream);

  static StreamTransformer<Query, List<T>> _buildTransformer<T>(
      T mapper(Map<String, dynamic> row)) {
    return StreamTransformer<Query, List<T>>((
      Stream<Query> input,
      bool cancelOnError,
    ) {
      StreamController<List<T>> controller;
      StreamSubscription<Query> subscription;

      add(List<Map<String, dynamic>> rows) {
        final items = rows.map((row) => mapper(row)).toList(growable: false);
        controller.add(items);
      }

      controller = StreamController<List<T>>(
        sync: true,
        onListen: () {
          subscription = input.listen(
            (Query query) {
              Future<List<Map<String, dynamic>>> newValue;
              try {
                newValue = query();
              } catch (e, s) {
                controller.addError(e, s);
                return;
              }
              subscription.pause();
              newValue
                  ?.then(add, onError: controller.addError)
                  ?.whenComplete(subscription.resume);
            },
            onError: controller.addError,
            onDone: controller.close,
            cancelOnError: cancelOnError,
          );
        },
        onPause: subscription.pause,
        onResume: subscription.resume,
        onCancel: subscription.cancel,
      );

      return controller.stream.listen(null);
    });
  }
}
