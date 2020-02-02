import 'package:meta/meta.dart';
import 'package:sqflite/sqlite_api.dart' as sqlite_api;

import '../sqlbrite.dart';
import 'brite_batch.dart';
import 'brite_transaction.dart';

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
  Stream<Query> createQuery(
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

  /// Like [IBriteDatabase.createQuery]
  Stream<Query> createRawQuery(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);

  ///
  /// Calls in action must only be done using the transaction object
  /// using the database will trigger a dead-lock
  /// A notification to queries for tables will be sent after the transaction is executed.
  ///
  Future<T> transactionAndTrigger<T>(
    Future<T> action(BriteTransaction txn), {
    bool exclusive,
  });
}

///
/// Common API for [BriteDatabase] and [Transaction] to execute SQL commands
///
abstract class BriteDatabaseExecutor implements sqlite_api.DatabaseExecutor {
  ///
  /// Execute an SQL query with no return value, and notify
  /// A notification to queries for [tables] will be sent after the statement is executed.
  ///
  Future<void> executeAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);

  ///
  /// Executes a raw SQL DELETE query
  ///
  /// Returns the number of changes made
  ///
  /// Only send tables trigger if rows were affected.
  ///
  Future<int> rawDeleteAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);

  ///
  /// Execute a raw SQL UPDATE query
  ///
  /// Returns the number of changes made
  /// Only send tables trigger if rows were affected.
  ///
  Future<int> rawUpdateAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);

  ///
  /// Execute a raw SQL INSERT query
  ///
  /// Returns the last inserted record id
  /// Only send tables trigger if the insert was successful.
  ///
  Future<int> rawInsertAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);
}

///
/// Wrap [sqlite_api.DatabaseExecutor] to implement [BriteDatabaseExecutor]
///
abstract class AbstractBriteDatabaseExecutor implements BriteDatabaseExecutor {
  final sqlite_api.DatabaseExecutor _delegate;

  ///
  const AbstractBriteDatabaseExecutor(this._delegate);

  ///
  @visibleForOverriding
  void sendTableTrigger(Iterable<String> tables);

  @override
  Future<void> execute(String sql, [List<dynamic> arguments]) =>
      _delegate.execute(sql, arguments);

  @override
  Future<void> executeAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]) async {
    await execute(sql, arguments);
    sendTableTrigger(tables);
  }

  @override
  BriteBatch batch() => BriteBatch(this, _delegate.batch());

  @override
  Future<int> delete(
    String table, {
    String where,
    List<dynamic> whereArgs,
  }) async {
    final int rows =
        await _delegate.delete(table, where: where, whereArgs: whereArgs);
    if (rows > 0) {
      sendTableTrigger({table});
    }
    return rows;
  }

  @override
  Future<int> rawDelete(String sql, [List<dynamic> arguments]) =>
      _delegate.rawDelete(sql, arguments);

  @override
  Future<int> rawDeleteAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]) async {
    final int rows = await rawDelete(sql, arguments);
    if (rows > 0) {
      sendTableTrigger(tables);
    }
    return rows;
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String where,
    List<dynamic> whereArgs,
    sqlite_api.ConflictAlgorithm conflictAlgorithm,
  }) async {
    final int rows = await _delegate.update(
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
      sendTableTrigger(tables);
    }
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic> arguments,
  ]) =>
      _delegate.rawQuery(sql, arguments);

  @override
  Future<List<Map<String, dynamic>>> query(
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
    Map<String, dynamic> values, {
    String nullColumnHack,
    sqlite_api.ConflictAlgorithm conflictAlgorithm,
  }) async {
    final int id = await _delegate.insert(
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
      sendTableTrigger(tables);
    }
    return id;
  }
}
