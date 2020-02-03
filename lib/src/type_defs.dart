import 'dart:async';

///
typedef Query = Future<List<Map<String, dynamic>>> Function();

///
typedef Logger = void Function(String message);
