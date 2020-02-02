import 'dart:async';

import 'stream_transformers/query_to_list_stream_transformer.dart';
import 'stream_transformers/query_to_one_stream_transformer.dart';
import 'type_defs.dart';

///
extension MapToOneOrDefaultQueryStreamExtensions on Stream<Query> {
  ///
  /// Given a function mapping the current row to T, transform each
  /// emitted [Query] which returns a single row to T.
  ///
  /// It is an error for a query to pass through this operator with more than 1 row in its result
  /// set. Use `LIMIT 1` on the underlying SQL query to prevent this. Result sets with 0 rows
  /// emit [defaultValue].
  ///
  Stream<T> mapToOneOrDefault<T>(
    T mapper(Map<String, dynamic> row), {
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

///
extension MapToOneQueryStreamExtensions on Stream<Query> {
  ///
  /// Given a function mapping the current row to T, transform each
  /// emitted [Query] which returns a single row to T.
  ///
  /// It is an error for a query to pass through this operator with more than 1 row in its result
  /// set. Use `LIMIT 1` on the underlying SQL query to prevent this. Result sets with 0 rows
  /// do not emit an item.
  ///
  Stream<T> mapToOne<T>(T mapper(Map<String, dynamic> row)) =>
      transform(QueryToOneStreamTransformer(mapper, false));
}

///
extension MapToListQueryStreamExtensions on Stream<Query> {
  ///
  /// Given a function mapping the current row to T, transform each
  /// emitted [Query] to a [List<T].
  ///
  Stream<List<T>> mapToList<T>(T mapper(Map<String, dynamic> row)) =>
      transform(QueryToListStreamTransformer(mapper));
}
