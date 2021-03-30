import 'dart:async';

import '../api.dart';

/// Transform [Query] to list of values.
/// [Stream<Query>] to [Stream<List<T>>].
extension MapToListQueryStreamExtensions on Stream<Query> {
  ///
  /// Given a function mapping the current row to T, transform each
  /// emitted [Query] to a [List<T>].
  ///
  Stream<List<T>> mapToList<T>(T Function(Map<String, Object?> row) rowMapper) {
    final controller = isBroadcast
        ? StreamController<List<T>>.broadcast(sync: true)
        : StreamController<List<T>>(sync: true);
    StreamSubscription<Query>? subscription;

    void add(List<Map<String, Object?>> rows) {
      try {
        final items = rows.map((row) => rowMapper(row));
        controller.add(List.unmodifiable(items));
      } catch (e, s) {
        controller.addError(e, s);
      }
    }

    controller.onListen = () {
      subscription = listen(
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

      if (!isBroadcast) {
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
}
