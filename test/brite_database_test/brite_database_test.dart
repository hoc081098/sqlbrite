import 'package:flutter_test/flutter_test.dart';

import 'batch.dart' as batch;
import 'create_query.dart' as create_query;
import 'create_raw_query.dart' as create_raw_query;
import 'delegate_to_db.dart' as delegate_to_db;
import 'transaction.dart' as transaction;

void main() {
  group('Brite database', () {
    delegate_to_db.main();
    create_query.main();
    create_raw_query.main();
    transaction.main();
    batch.main();
  });
}
