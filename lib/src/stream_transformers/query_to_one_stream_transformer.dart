import 'dart:async';

import '../type_defs.dart';

///
class QueryToOneStreamTransformer<T> extends StreamTransformerBase<Query, T> {
  final StreamTransformer<Query, T> _transformer;

  ///
  QueryToOneStreamTransformer(
    T Function(Map<String, dynamic> row) mapper,
    bool emitDefault, {
    T defaultValue,
  }) : _transformer = _buildTransformer(mapper, defaultValue, emitDefault);

  @override
  Stream<T> bind(Stream<Query> stream) => _transformer.bind(stream);

  static StreamTransformer<Query, T> _buildTransformer<T>(
    T Function(Map<String, dynamic> row) mapper,
    T defaultValue,
    bool emitDefault,
  ) {
    ArgumentError.checkNotNull(mapper, 'mapper');
    ArgumentError.checkNotNull(emitDefault, 'emitDefault');

    return StreamTransformer<Query, T>((input, cancelOnError) {
      StreamController<T> controller;
      StreamSubscription<Query> subscription;

      void add(List<Map<String, dynamic>> rows) {
        if (rows.length > 1) {
          controller.addError(StateError('Query returned more than 1 row'));
          return;
        }

        if (rows.isEmpty) {
          if (emitDefault) {
            controller.add(defaultValue);
          } else {
            // TODO: Should throw error when rows is empty and not emit default
            // TODO: Current do nothing
          }
        } else {
          try {
            controller.add(mapper(rows.first));
          } catch (e, s) {
            controller.addError(e, s);
          }
        }
      }

      void onListen() {
        subscription = input.listen(
          (Query event) {
            Future<List<Map<String, dynamic>>> newValue;
            try {
              newValue = event();
            } catch (e, s) {
              controller.addError(e, s);
              return;
            }
            if (newValue != null) {
              subscription.pause();
              newValue
                  .then(add, onError: controller.addError)
                  .whenComplete(subscription.resume);
            }
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      }

      if (input.isBroadcast) {
        controller = StreamController<T>.broadcast(
          onListen: onListen,
          onCancel: () => subscription.cancel(),
          sync: true,
        );
      } else {
        controller = StreamController<T>(
          onListen: onListen,
          onPause: () => subscription.pause(),
          onResume: () => subscription.resume(),
          onCancel: () => subscription.cancel(),
          sync: true,
        );
      }
      return controller.stream.listen(null);
    });
  }
}
