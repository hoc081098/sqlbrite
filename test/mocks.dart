import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlbrite/sqlbrite.dart' show Query;

final isQuery = isA<Query>();

@GenerateMocks(
  [],
  customMocks: [
    MockSpec<Database>(),
    MockSpec<Transaction>(),
    MockSpec<Batch>(),
  ],
)
// ignore: unused_element
void _genMocks() {}
