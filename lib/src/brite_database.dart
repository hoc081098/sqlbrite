import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqlite_api.dart' as sqlite_api;

import '../sqlbrite.dart';
import 'api.dart';
import 'brite_transaction.dart';

///
/// [IBriteDatabase] implementation
///
/// Streaming database
///
class BriteDatabase extends AbstractBriteDatabaseExecutor
    implements IBriteDatabase {
  static const _tag = '>>> [Brite database]';

  final _triggers = PublishSubject<Set<String>>();
  StreamSubscription<Set<String>> _subscription;

  final sqlite_api.Database _db;

  /// Construct a [BriteDatabase] backed by a [sqlite_api.Database]
  BriteDatabase(this._db) : super(_db) {
    _subscription = _triggers.listen((tables) {
      final description = 'Send triggered'.padRight(16, ' ');
      print('$_tag $description : ${tables.description}');
    });
  }

  @override
  void sendTableTrigger(Iterable<String> tables) =>
      _triggers.add(tables.toSet());

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
  ]) =>
      _createQuery(tables, () => _db.rawQuery(sql, arguments));

  Stream<Query> _createQuery(
    Iterable<String> tables,
    Query query,
  ) {
    return _triggers
        .where((triggeredTables) => tables.any(triggeredTables.contains))
        .mapTo(query)
        .startWith(query)
        .shareValue()
        .doOnData((_) => print(
            '$_tag ${'Send query'.padRight(16, ' ')} : ${tables.description}'));
  }

  @override
  Future<void> close() async {
    await _triggers.close();
    await _subscription.cancel();
    await _db.close();
  }

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
    Future<T> Function(sqlite_api.Transaction txn) action, {
    bool exclusive,
  }) =>
      _db.transaction(action, exclusive: exclusive);

  @override
  Future<T> transactionAndTrigger<T>(
    Future<T> Function(sqlite_api.Transaction txn) action, {
    bool exclusive,
  }) async {
    Set<String> tables;

    final result = await _db.transaction(
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

extension _ToStringExtension on Iterable<String> {
  String get description {
    final joined = map((e) => "'$e'").join(', ');
    return '[$joined]';
  }
}
