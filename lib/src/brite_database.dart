import 'dart:async';

import 'package:rxdart_ext/rxdart_ext.dart';
import 'package:sqflite/sqlite_api.dart' as sqlite_api;

import 'api.dart';
import 'brite_transaction.dart';

/// Logs changed tables or sent query.
typedef BriteDatabaseLogger = void Function(String message);

///
/// [IBriteDatabase] implementation.
///
/// Streaming database.
///
class BriteDatabase extends AbstractBriteDatabaseExecutor
    implements IBriteDatabase {
  static const _tag = '💎 Brite database →';
  static const _width = 16;

  final _changedTablesSubject = PublishSubject<Set<String>>();
  StreamSubscription<Set<String>>? _subscription;

  /// Delegate.
  final sqlite_api.Database _db;

  /// Set to `null` to disable logging.
  final BriteDatabaseLogger? logger;

  /// Construct a [BriteDatabase] backed by a [sqlite_api.Database].
  /// To disable logging, pass `null` to [logger].
  BriteDatabase(this._db, {this.logger = print}) : super(_db) {
    final logger = this.logger;
    if (logger != null) {
      final description = 'Changed tables'.padRight(_width, ' ');

      _subscription = _changedTablesSubject.listen(
          (tables) => logger('$_tag $description : ${tables.description}'));
    }
  }

  @override
  void sendTableTrigger(Iterable<String> tables) =>
      _changedTablesSubject.add(Set.unmodifiable(tables));

  @override
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
    List<Object?>? arguments,
  ]) =>
      _createQuery(tables, () => _db.rawQuery(sql, arguments));

  Stream<Query> _createQuery(
    Iterable<String> tables,
    Query query,
  ) {
    final query$ = _changedTablesSubject
        .toSingleSubscriptionStream()
        .where((triggeredTables) => tables.any(triggeredTables.contains))
        .mapTo(query)
        .startWith(query);

    final logger = this.logger;
    if (logger != null) {
      return query$.doOnData((_) => logger(
          '$_tag ${'Send query'.padRight(_width, ' ')} : ${tables.description}'));
    }

    return query$;
  }

  @override
  Future<void> close() async {
    final cancel = _subscription?.cancel();
    if (cancel != null) {
      await cancel;
    }
    await _changedTablesSubject.close();
    await _db.close();
  }

  @Deprecated('Dev only')
  @override
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]) =>
      _db.devInvokeMethod(method, arguments);

  @Deprecated('Dev only')
  @override
  Future<T> devInvokeSqlMethod<T>(String method, String sql,
          [List<Object?>? arguments]) =>
      _db.devInvokeSqlMethod(method, sql, arguments);

  @override
  bool get isOpen => _db.isOpen;

  @override
  String get path => _db.path;

  @override
  Future<T> transaction<T>(
    Future<T> Function(sqlite_api.Transaction txn) action, {
    bool? exclusive,
  }) =>
      _db.transaction(action, exclusive: exclusive);

  @override
  Future<T> transactionAndTrigger<T>(
    Future<T> Function(sqlite_api.Transaction txn) action, {
    bool? exclusive,
  }) async {
    late Set<String> tables;

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
