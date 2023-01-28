// ignore_for_file: unused_result

import 'dart:async';

import 'package:meta/meta.dart' show internal, useResult;
import 'package:sqflite/sqlite_api.dart' as sqlite_api;

import 'brite_batch.dart';
import 'brite_transaction.dart';

/// JSON Object
typedef JSON = Map<String, dynamic>;

///
/// Lazy query.
///
/// Type alias for a function with no parameters
/// and returns a Future that completes with a list of map
/// or an error.
///
typedef Query = Future<List<JSON>> Function();

///
/// Database to send sql commands, created during [openDatabase]
///
abstract class IBriteDatabase implements sqlite_api.Database {
  ///
  /// Create an stream which will notify subscribers with a [Query] query for
  /// execution.
  ///
  /// Subscribers will receive an immediate notification for initial data as well as subsequent
  /// notifications for when the supplied [table] data changes through the operations: insert, update, delete.
  /// Unsubscribe when you no longer want updates to a query.
  ///
  /// Note: To skip the immediate notification and only receive subsequent notifications when data
  /// has changed call skip(1) on the returned stream.
  ///
  /// Warning: this method does not perform the query! Only by subscribing to the returned
  /// Stream will the operation occur.
  ///
  @useResult
  Stream<Query> createQuery(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  });

  ///
  /// Like [IBriteDatabase.createQuery].
  ///
  @useResult
  Stream<Query> createRawQuery(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]);

  ///
  /// Calls in action must only be done using the transaction object
  /// using the database will trigger a dead-lock.
  ///
  /// A notification to queries for tables will be sent after the transaction is executed.
  ///
  Future<T> transactionAndTrigger<T>(
    Future<T> Function(sqlite_api.Transaction txn) action, {
    bool? exclusive,
  });
}

///
/// Common API for [BriteDatabase] and [BriteTransaction] to execute SQL commands.
///
abstract class BriteDatabaseExecutor implements sqlite_api.DatabaseExecutor {
  ///
  /// See [execute]
  ///
  /// Execute an SQL query with no return value, and notify.
  ///
  /// A notification to queries for [tables] will be sent after the statement is executed.
  ///
  Future<void> executeAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]);

  ///
  /// See [rawDelete]
  ///
  /// Executes a raw SQL DELETE query.
  ///
  /// Returns the number of changes made.
  ///
  /// A notification to queries for [tables] will be sent after the statement is executed
  /// and had rows were affected.
  ///
  Future<int> rawDeleteAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]);

  ///
  /// See [rawUpdate]
  ///
  /// Execute a raw SQL UPDATE query
  ///
  /// A notification to queries for [tables] will be sent after the statement is executed
  /// and had rows were affected.
  ///
  /// Returns the number of changes made
  ///
  Future<int> rawUpdateAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]);

  ///
  /// See [rawInsert]
  ///
  /// Execute a raw SQL INSERT query.
  ///
  /// Returns the last inserted record id.
  ///
  /// A notification to queries for [tables] will be sent after the statement is executed
  /// and the insert was successful.
  ///
  Future<int> rawInsertAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]);
}

///
/// A batch is used to perform multiple operation as a single atomic unit.
/// A Batch object can be acquired by calling [Database.batch]. It provides
/// methods for adding operation. None of the operation will be
/// executed (or visible locally) until commit() is called.
///
abstract class IBriteBatch implements sqlite_api.Batch {
  ///
  /// See [rawInsert]
  ///
  /// A notification to queries for [tables] will be sent after the batch is committed
  ///
  void rawInsertAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]);

  ///
  /// See [rawUpdate]
  ///
  /// A notification to queries for [tables] will be sent after the batch is committed
  ///
  void rawUpdateAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]);

  ///
  /// See [rawDelete]
  ///
  /// A notification to queries for [tables] will be sent after the batch is committed
  ///
  void rawDeleteAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]);

  ///
  /// See [execute]
  ///
  /// A notification to queries for [tables] will be sent after the batch is committed
  ///
  void executeAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]);
}

///
/// Wrap [sqlite_api.DatabaseExecutor] to implement [BriteDatabaseExecutor]
///
abstract class AbstractBriteDatabaseExecutor implements BriteDatabaseExecutor {
  final sqlite_api.DatabaseExecutor _delegate;

  /// Construct a [AbstractBriteDatabaseExecutor] backed by a [sqlite_api.DatabaseExecutor]
  const AbstractBriteDatabaseExecutor(this._delegate);

  /// Override this method to send notifications
  @internal
  void sendTableTrigger(Iterable<String> tables);

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _delegate.execute(sql, arguments);

  @override
  Future<void> executeAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]) async {
    await execute(sql, arguments);
    sendTableTrigger(tables);
  }

  @override
  IBriteBatch batch() => BriteBatch(this, _delegate.batch());

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final rows = await _delegate.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
    if (rows > 0) {
      sendTableTrigger({table});
    }
    return rows;
  }

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) =>
      _delegate.rawDelete(sql, arguments);

  @override
  Future<int> rawDeleteAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final rows = await rawDelete(sql, arguments);
    if (rows > 0) {
      sendTableTrigger(tables);
    }
    return rows;
  }

  @override
  Future<int> update(
    String table,
    JSON values, {
    String? where,
    List<Object?>? whereArgs,
    sqlite_api.ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final rows = await _delegate.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
    if (rows > 0) {
      sendTableTrigger({table});
    }
    return rows;
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) =>
      _delegate.rawUpdate(sql, arguments);

  @override
  Future<int> rawUpdateAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final rows = await rawUpdate(sql, arguments);
    if (rows > 0) {
      sendTableTrigger(tables);
    }
    return rows;
  }

  @override
  Future<List<JSON>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) =>
      _delegate.rawQuery(sql, arguments);

  @override
  Future<List<JSON>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
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
  Future<int> insert(
    String table,
    JSON values, {
    String? nullColumnHack,
    sqlite_api.ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final id = await _delegate.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
    if (id != -1) {
      sendTableTrigger({table});
    }
    return id;
  }

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) =>
      _delegate.rawInsert(sql, arguments);

  @override
  Future<int> rawInsertAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final id = await rawInsert(sql, arguments);
    if (id != -1) {
      sendTableTrigger(tables);
    }
    return id;
  }

  @override
  Future<sqlite_api.QueryCursor> queryCursor(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    int? bufferSize,
  }) =>
      _delegate.queryCursor(
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

  @override
  Future<sqlite_api.QueryCursor> rawQueryCursor(
    String sql,
    List<Object?>? arguments, {
    int? bufferSize,
  }) =>
      _delegate.rawQueryCursor(
        sql,
        arguments,
        bufferSize: bufferSize,
      );

  @override
  sqlite_api.Database get database => _delegate.database;
}
