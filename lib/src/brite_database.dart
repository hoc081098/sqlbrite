import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqlite_api.dart' as sqlite_api;

import '../sqlbrite.dart';
import 'api.dart';
import 'brite_transaction.dart';

///
class BriteDatabase extends AbstractBriteDatabaseExecutor
    implements IBriteDatabase {
  static const _tag = '>> [BRITE_DATABASE]';

  final _triggers = PublishSubject<Set<String>>()
    ..listen((triggeredTable) =>
        print('$_tag ${'Triggered'.padRight(10, ' ')} = $triggeredTable'));
  final sqlite_api.Database _db;

  ///
  BriteDatabase(this._db) : super(_db);

  @override
  void sendTableTrigger(Iterable<String> tables) {
    _triggers.add(tables.toSet());
  }

  @override
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

  @override
  Stream<Query> createRawQuery(
    Iterable<String> tables,
    String sql, [
    List<dynamic> arguments,
  ]) {
    return _createQuery(
      tables,
      () => _db.rawQuery(sql, arguments),
    );
  }

  Stream<Query> _createQuery(
    Iterable<String> tables,
    Query query,
  ) {
    return _triggers
        .where((triggeredTables) => tables.any(triggeredTables.contains))
        .mapTo(query)
        .startWith(query)
        .doOnData((_) => print('$_tag ${'Query'.padRight(10, ' ')} = $tables'));
  }

  @override
  Future<void> close() => _db.close();

  @deprecated
  @override
  Future<T> devInvokeMethod<T>(String method, [arguments]) =>
      _db.devInvokeMethod(method, arguments);

  @deprecated
  @override
  Future<T> devInvokeSqlMethod<T>(
    String method,
    String sql, [
    List arguments,
  ]) =>
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
  Future<T> transaction<T>(
    Future<T> action(sqlite_api.Transaction txn), {
    bool exclusive,
  }) =>
      _db.transaction(action, exclusive: exclusive);

  @override
  Future<T> transactionAndTrigger<T>(
    Future<T> Function(BriteTransaction txn) action, {
    bool exclusive,
  }) async {
    Set<String> tables;

    final T result = await _db.transaction(
      (txn) async {
        final briteTransaction = BriteTransaction(txn);
        final result = await action(briteTransaction);
        tables = briteTransaction.tables;
        return result;
      },
      exclusive: exclusive,
    );

    sendTableTrigger(tables);
    return result;
  }
}
