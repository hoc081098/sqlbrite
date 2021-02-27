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
  final T Function(Map<String, Object?> row) mapper,
  final _Wrapper<T>? defaultValue,
) {
  assert(mapper != null);

  final controller = stream.isBroadcast
      ? StreamController<T>.broadcast(sync: true)
      : StreamController<T>(sync: true);
  StreamSubscription<Query>? subscription;

  void add(List<Map<String, Object?>> rows) {
    if (rows.length > 1) {
      controller.addError(StateError('Query returned more than 1 row'));
      return;
    }

    if (rows.isEmpty) {
      if (defaultValue != null) {
        controller.add(defaultValue.value);
      } else {
        controller.addError(StateError('Query returned 0 row'));
      }
    } else {
      try {
        controller.add(mapper(rows.first));
      } catch (e, s) {
        controller.addError(e, s);
      }
    }
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
          T Function(Map<String, Object?> row) mapper, T defaultValue) =>
      _queryToOneStreamTransformer(this, mapper, _Wrapper(defaultValue));
}

/// Transform [Query] to single value
extension MapToOneQueryStreamExtensions on Stream<Query> {
  ///
  /// Given a function mapping the current row to T, transform each
  /// emitted [Query] which returns a single row to T.
  ///
  /// It is an [StateError] for a query to pass through this operator with more than 1 row in its result
  /// set. Use `LIMIT 1` on the underlying SQL query to prevent this.
  /// Emits a [StateError] when result sets with 0 rows.
  ///
  Stream<T> mapToOne<T>(T Function(Map<String, Object?> row) mapper) =>
      _queryToOneStreamTransformer(this, mapper, null);
}
