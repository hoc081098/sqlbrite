import 'package:meta/meta.dart';
import 'package:sqflite/sqlite_api.dart' as sqlite_api;
import 'package:sqlbrite/src/brite_transaction.dart';

import '../sqlbrite.dart';
import 'brite_batch.dart';

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
    Future<T> Function(sqlite_api.Transaction txn) action, {
    bool exclusive,
  });
}

///
/// Common API for [BriteDatabase] and [BriteTransaction] to execute SQL commands
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
/// A batch is used to perform multiple operation as a single atomic unit.
/// A Batch object can be acquired by calling [Database.batch]. It provides
/// methods for adding operation. None of the operation will be
/// executed (or visible locally) until commit() is called.
///
abstract class IBriteBatch implements sqlite_api.Batch {
  ///
  void rawInsertAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);

  ///
  void rawUpdateAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);

  ///
  void rawDeleteAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]);

  ///
  void executeAndTrigger(
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

  /// Construct a [AbstractBriteDatabaseExecutor] backed by a [sqlite_api.DatabaseExecutor]
  const AbstractBriteDatabaseExecutor(this._delegate);

  /// Override this method to send notifications
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
  IBriteBatch batch() => BriteBatch(this, _delegate.batch());

  @override
  Future<int> delete(
    String table, {
    String where,
    List<dynamic> whereArgs,
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
  Future<int> rawDelete(String sql, [List<dynamic> arguments]) =>
      _delegate.rawDelete(sql, arguments);

  @override
  Future<int> rawDeleteAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
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
    Map<String, dynamic> values, {
    String where,
    List<dynamic> whereArgs,
    sqlite_api.ConflictAlgorithm conflictAlgorithm,
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
  Future<int> rawUpdate(String sql, [List<dynamic> arguments]) =>
      _delegate.rawUpdate(sql, arguments);

  @override
  Future<int> rawUpdateAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]) async {
    final rows = await rawUpdate(sql, arguments);
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
  Future<int> rawInsert(String sql, [List<dynamic> arguments]) =>
      _delegate.rawInsert(sql, arguments);

  @override
  Future<int> rawInsertAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]) async {
    final id = await rawInsert(sql, arguments);
    if (id != -1) {
      sendTableTrigger(tables);
    }
    return id;
  }
}
