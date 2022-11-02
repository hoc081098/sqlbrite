import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlbrite/sqlbrite.dart' show Query;
import 'dart:async' as _i3;
import 'package:sqflite_common/sqlite_api.dart' as _i2;

final isQuery = isA<Query>();

@GenerateNiceMocks(
  [
    MockSpec<Database>(
      onMissingStub: OnMissingStub.throwException,
      fallbackGenerators: {
        #transaction: fallbackTransaction,
        #devInvokeMethod: fallbackDevInvokeMethod,
        #devInvokeSqlMethod: fallbackDevInvokeSqlMethod
      },
    ),
    MockSpec<Transaction>(onMissingStub: OnMissingStub.throwException),
    MockSpec<Batch>(onMissingStub: OnMissingStub.throwException),
    MockSpec<QueryCursor>(onMissingStub: OnMissingStub.throwException),
  ],
)
// ignore: unused_element
void _genMocks() {}

_i3.Future<T> fallbackTransaction<T>(
  _i3.Future<T> Function(_i2.Transaction)? action, {
  bool? exclusive,
}) =>
    _default<T>();

_i3.Future<T> fallbackDevInvokeMethod<T>(String? method, [dynamic arguments]) =>
    _default<T>();

_i3.Future<T> fallbackDevInvokeSqlMethod<T>(String? method, String? sql,
        [List<Object?>? arguments]) =>
    _default<T>();

Future<T> _default<T>() {
  if (T == int) {
    return _i3.Future.value(0 as T);
  }
  return _i3.Future.value(null as T);
}
