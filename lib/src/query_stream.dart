import 'dart:async';

import 'api.dart';
import 'stream_transformers/query_to_list_stream_transformer.dart';
import 'stream_transformers/query_to_one_stream_transformer.dart';

/// Transform [Query] to single value
extension MapToOneOrDefaultQueryStreamExtensions on Stream<Query> {
  ///
  /// Given a function mapping the current row to T, transform each
  /// emitted [Query] which returns a single row to T.
  ///
  /// It is an error for a query to pass through this operator with more than 1 row in its result
  /// set. Use `LIMIT 1` on the underlying SQL query to prevent this. Emits [defaultValue]
  /// when result sets has 0 rows
  ///
  ///
  Stream<T> mapToOneOrDefault<T>(
    T Function(Map<String, dynamic> row) mapper, {
    T defaultValue,
  }) =>
      transform(
        QueryToOneStreamTransformer(
          mapper,
          true,
          defaultValue: defaultValue,
        ),
      );
}

/// Transform [Query] to single value
extension MapToOneQueryStreamExtensions on Stream<Query> {
  ///
  /// Given a function mapping the current row to T, transform each
  /// emitted [Query] which returns a single row to T.
  ///
  /// It is an error for a query to pass through this operator with more than 1 row in its result
  /// set. Use `LIMIT 1` on the underlying SQL query to prevent this. Result sets with 0 rows
  /// do not emit an item.
  ///
  Stream<T> mapToOne<T>(T Function(Map<String, dynamic> row) mapper) =>
      transform(QueryToOneStreamTransformer(mapper, false));
}

/// Transform [Query] to list of values
extension MapToListQueryStreamExtensions on Stream<Query> {
  ///
  /// Given a function mapping the current row to T, transform each
  /// emitted [Query] to a [List<T>].
  ///
  Stream<List<T>> mapToList<T>(T Function(Map<String, dynamic> row) mapper) =>
      transform(QueryToListStreamTransformer(mapper));
}
