import 'package:sqflite/sqlite_api.dart' as sqlite_api;

import 'api.dart';

///
class BriteTransaction extends AbstractBriteDatabaseExecutor
    implements sqlite_api.Transaction {
  final Set<String> _tables;

  ///
  BriteTransaction(sqlite_api.Transaction txn, this._tables) : super(txn);

  @override
  void sendTableTrigger(Iterable<String> tables) => _tables.addAll(tables);
}
