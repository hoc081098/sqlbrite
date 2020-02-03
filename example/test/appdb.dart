import 'package:example/data/app_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('description', () {
    WidgetsFlutterBinding.ensureInitialized();
    final appDb1 = AppDb.getInstance();
    final appDb2 = AppDb.getInstance();
    expect(identical(appDb1, appDb2), isTrue);
  });
}
