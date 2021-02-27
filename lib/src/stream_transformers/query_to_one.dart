import 'dart:async';

import '../api.dart';

// TODO: Remove assert
// ignore_for_file: unnecessary_null_comparison

class _Wrapper<T> {
  final T value;

  _Wrapper(this.value);
}

/// Transform [Stream<Query>] to [Stream<T>]
Stream<T> _queryToOneStreamTransformer<T>(
  final Stream<Query> stream,
  final T Function(Map<String, Object?> row) rowMapper,
  final _Wrapper<T>? defaultValue,
) {
  assert(rowMapper != null);

  final controller = stream.isBroadcast
      ? StreamController<T>.broadcast(sync: true)
      : StreamController<T>(sync: true);
  StreamSubscription<Query>? subscription;

  void add(List<Map<String, Object?>> rows) {
    final length = rows.length;

    if (length > 1) {
      controller.addError(StateError('Query returned more than 1 row'));
      return;
    }

    if (length == 0) {
      if (defaultValue != null) {
        controller.add(defaultValue.value);
      } else {
        controller.addError(StateError('Query returned 0 row'));
      }
      return;
    }

    final T result;
    try {
      result = rowMapper(rows[0]);
    } catch (e, s) {
      controller.addError(e, s);
      return;
    }

    controller.add(result);
  }

  controller.onListen = () {
    subscription = stream.listen(
      (query) {
        Future<List<Map<String, Object?>>> future;
        try {
          future = query();
        } catch (e, s) {
          controller.addError(e, s);
          return;
        }

        subscription!.pause();
        future
            .then(add, onError: controller.addError)
            .whenComplete(subscription!.resume);
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    if (!stream.isBroadcast) {
      controller.onPause = () => subscription!.pause();
      controller.onResume = () => subscription!.resume();
    }
  };
  controller.onCancel = () {
    final toCancel = subscription;
    subscription = null;
    return toCancel?.cancel();
  };

  return controller.stream;
}

/// Transform [Query] to single value.
/// [Stream<Query>] to [Stream<T>].
extension MapToOneOrDefaultQueryStreamExtensions on Stream<Query> {
  ///
  /// Given a function mapping the current row to T, transform each
  /// emitted [Query] which returns a single row to T.
  ///
  /// It is an [StateError] for a query to pass through this operator with more than 1 row in its result
  /// set. Use `LIMIT 1` on the underlying SQL query to prevent this. Emits [defaultValue]
  /// when result sets has 0 rows
  ///
  ///
  Stream<T> mapToOneOrDefault<T>(
          T Function(Map<String, Object?> row) rowMapper, T defaultValue) =>
      _queryToOneStreamTransformer(this, rowMapper, _Wrapper(defaultValue));
}

/// Transform [Query] to single value
extension MapToOneQueryStreamExtensions on Stream<Query> {
  ///
  /// Given a function mapping the current row to T, transform each
  /// emitted [Query] which returns a single row to T.
  ///
  /// It is an [StateError] for a query to pass through this operator with more than 1 row in its result
  /// set. Use `LIMIT 1` on the underlying SQL query to prevent this.
  /// Emits a [StateError] when result sets has 0 rows.
  ///
  Stream<T> mapToOne<T>(T Function(Map<String, Object?> row) rowMapper) =>
      _queryToOneStreamTransformer(this, rowMapper, null);
}
