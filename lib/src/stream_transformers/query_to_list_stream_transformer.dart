import 'dart:async';

import '../type_defs.dart';

///
class QueryToListStreamTransformer<T>
    extends StreamTransformerBase<Query, List<T>> {
  final StreamTransformer<Query, List<T>> _transformer;

  ///
  QueryToListStreamTransformer(T Function(Map<String, dynamic> row) mapper)
      : _transformer = _buildTransformer(mapper);

  @override
  Stream<List<T>> bind(Stream<Query> stream) => _transformer.bind(stream);

  static StreamTransformer<Query, List<T>> _buildTransformer<T>(
    T Function(Map<String, dynamic> row) mapper,
  ) {
    ArgumentError.checkNotNull(mapper, 'mapper');

    return StreamTransformer<Query, List<T>>((
      Stream<Query> input,
      bool cancelOnError,
    ) {
      StreamController<List<T>> controller;
      StreamSubscription<Query> subscription;

      void add(List<Map<String, dynamic>> rows) {
        try {
          final items = rows.map((row) => mapper(row)).toList(growable: false);
          controller.add(items);
        } catch (e, s) {
          controller.addError(e, s);
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
        controller = StreamController<List<T>>.broadcast(
          onListen: onListen,
          onCancel: () => subscription.cancel(),
          sync: true,
        );
      } else {
        controller = StreamController<List<T>>(
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
