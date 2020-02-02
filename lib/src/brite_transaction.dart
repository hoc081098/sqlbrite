import 'package:collection/collection.dart' show UnmodifiableSetView;
import 'package:sqflite/sqlite_api.dart' as sqlite_api;

import 'api.dart';

///
class BriteTransaction extends AbstractBriteDatabaseExecutor
    implements sqlite_api.Transaction {
  final _tables = <String>{};

  /// Get table names
  Set<String> get tables => UnmodifiableSetView(_tables);

  ///
  BriteTransaction(sqlite_api.Transaction txn) : super(txn);

  @override
  void sendTableTrigger(Iterable<String> tables) => _tables.addAll(tables);
}
