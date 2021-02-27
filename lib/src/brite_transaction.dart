import 'package:meta/meta.dart';
import 'package:sqflite/sqlite_api.dart' as sqlite_api;

import 'api.dart';

/// A [sqlite_api.Transaction] that captures notified table names
@internal
class BriteTransaction extends AbstractBriteDatabaseExecutor
    implements sqlite_api.Transaction {
  final _tables = <String>{};

  /// Get notified table names
  Set<String> get tables => Set.unmodifiable(_tables);

  /// Construct a [BriteTransaction] backed by a [sqlite_api.Transaction]
  BriteTransaction(sqlite_api.Transaction txn) : super(txn);

  @override
  void sendTableTrigger(Iterable<String> tables) => _tables.addAll(tables);
}
