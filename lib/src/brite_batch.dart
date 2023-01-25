import 'package:meta/meta.dart';
import 'package:sqflite/sqlite_api.dart' as sqlite_api;

import 'api.dart';

/// [IBriteBatch] implementation
@internal
class BriteBatch implements IBriteBatch {
  final AbstractBriteDatabaseExecutor _executor;
  final sqlite_api.Batch _delegate;
  final _tables = <String>{};

  /// Construct a [BriteBatch] with a [AbstractBriteDatabaseExecutor]
  /// and backed by a [sqlite_api.Batch]
  BriteBatch(this._executor, this._delegate);

  @override
  Future<List> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    final list = await _delegate.commit(
      exclusive: exclusive,
      noResult: noResult,
      continueOnError: continueOnError,
    );
    _executor.sendTableTrigger(_tables);
    return list;
  }

  @override
  void delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    _delegate.delete(table, whereArgs: whereArgs, where: where);
    _tables.add(table);
  }

  @override
  void execute(String sql, [List<Object?>? arguments]) {
    _delegate.execute(sql, arguments);
  }

  @override
  void insert(
    String table,
    JSON values, {
    String? nullColumnHack,
    sqlite_api.ConflictAlgorithm? conflictAlgorithm,
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
  void query(
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
  }

  @override
  void rawDelete(String sql, [List<Object?>? arguments]) {
    _delegate.rawDelete(sql, arguments);
  }

  @override
  void rawInsert(String sql, [List<Object?>? arguments]) {
    _delegate.rawInsert(sql, arguments);
  }

  @override
  void rawQuery(String sql, [List<Object?>? arguments]) {
    _delegate.rawQuery(sql, arguments);
  }

  @override
  void rawUpdate(String sql, [List<Object?>? arguments]) {
    _delegate.rawUpdate(sql, arguments);
  }

  @override
  void update(
    String table,
    JSON values, {
    String? where,
    List<Object?>? whereArgs,
    sqlite_api.ConflictAlgorithm? conflictAlgorithm,
  }) {
    _delegate.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
    _tables.add(table);
  }

  @override
  void rawDeleteAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]) {
    rawDelete(sql, arguments);
    _tables.addAll(tables);
  }

  @override
  void rawInsertAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]) {
    rawInsert(sql, arguments);
    _tables.addAll(tables);
  }

  @override
  void rawUpdateAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]) {
    rawUpdate(sql, arguments);
    _tables.addAll(tables);
  }

  @override
  void executeAndTrigger(
    Iterable<String> tables,
    String sql, [
    List<Object?>? arguments,
  ]) {
    execute(sql, arguments);
    _tables.addAll(tables);
  }

  @override
  Future<List<Object?>> apply({bool? noResult, bool? continueOnError}) async {
    final result = await _delegate.apply(
      noResult: noResult,
      continueOnError: continueOnError,
    );

    _executor.sendTableTrigger(_tables);

    return result;
  }

  @override
  int get length => _delegate.length;
}
