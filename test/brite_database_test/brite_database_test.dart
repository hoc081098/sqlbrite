import 'package:flutter_test/flutter_test.dart';

import 'create_query.dart' as create_query;
import 'delegate_to_db.dart' as delegate_to_db;

void main() {
  group('Brite database', () {
    delegate_to_db.main();
    create_query.main();
  });
}
