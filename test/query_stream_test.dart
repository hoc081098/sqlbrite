import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart_ext/rxdart_ext.dart';
import 'package:sqlbrite/src/api.dart';
import 'package:sqlbrite/src/query_stream.dart';

Stream<Query> _queryStream(int numberOfRows) {
  return Stream<Query>.value(
    () => Future.value(
      List.filled(
        numberOfRows,
        <String, Object?>{},
      ),
    ),
  );
}

void main() {
  group('Query Stream', () {
    group('mapToOneOrDefault', () {
      test('works', () async {
        // emits default value
        final defaultValue = {'default': 42};
        final stream0 =
            _queryStream(0).mapToOneOrDefault((row) => row, defaultValue);
        await expectLater(
          stream0,
          emits(defaultValue),
        );

        // emit mapped value
        final stream1 = _queryStream(1).mapToOneOrDefault((row) => row, null);
        await expectLater(
          stream1,
          emits(<String, Object?>{}),
        );

        // emit error when query returned more than 1 row
        final stream2 = _queryStream(2).mapToOneOrDefault((row) => row, null);
        await expectLater(
          stream2,
          emitsError(isInstanceOf<StateError>()),
        );
      });

      // test('shouldThrowA', () {
      //   expect(
      //     () => _queryStream(0).mapToOneOrDefault(null, null),
      //     throwsArgumentError,
      //   );
      // });

      test('shouldThrowB', () async {
        final stream = Stream<Query>.error(Exception())
            .mapToOneOrDefault((_) => true, null);
        await expectLater(
          stream,
          emitsError(isA<Exception>()),
        );
      });

      test('shouldThrowC', () async {
        var i = 0;

        final stream = Rx.concat([
          _queryStream(1),
          _queryStream(1),
          _queryStream(1),
        ]).mapToOneOrDefault((row) {
          if (i++ == 1) {
            throw Exception();
          } else {
            return row;
          }
        }, null);
        await expectLater(
          stream,
          emitsInOrder(<Matcher>[
            isMap,
            emitsError(isException),
            isMap,
          ]),
        );
      });

      test('shouldThrowD', () async {
        final queryStream = _queryStream(1)
            .map<Query>((_) => () => Future.error(Exception('Query error')))
            .mapToOneOrDefault((row) => row, null);

        await expectLater(
          queryStream,
          emitsError(isException),
        );
      });

      test('shouldThrowE', () async {
        final queryStream = _queryStream(1)
            .map<Query>((_) => () => throw Exception('Query error'))
            .mapToOneOrDefault((row) => row, null);

        await expectLater(
          queryStream,
          emitsError(isException),
        );
      });

      test('isBroadcast', () async {
        final broadcastController = StreamController<Query>.broadcast();
        final stream1 = broadcastController.stream
            .mapToOneOrDefault((row) => row, null)
              ..listen(null);
        expect(
          stream1.isBroadcast,
          isTrue,
        );

        final controller = StreamController<Query>();
        final stream2 = controller.stream.mapToOneOrDefault((row) => row, null)
          ..listen(null);
        expect(
          stream2.isBroadcast,
          isFalse,
        );

        await Future.wait<void>(
            [broadcastController.close(), controller.close()]);
      });

      test('asBroadcastStream', () async {
        final stream = _queryStream(1)
            .mapToOneOrDefault((row) => row, null)
            .asBroadcastStream();

        // listen twice on same stream
        stream.listen(null);
        stream.listen(null);

        // code should reach here
        await expectLater(true, true);
      });

      test('pause.resume', () async {
        late StreamSubscription<Map<String, Object?>?> subscription;

        subscription = _queryStream(1)
            .delay(const Duration(milliseconds: 500))
            .mapToOneOrDefault((i) => i, null)
            .listen(
          expectAsync1(
            (data) {
              expect(data, isMap);
              subscription.cancel();
            },
          ),
        );

        subscription.pause();
        subscription.resume();
      });
    });

    group('mapToOne', () {
      test('works', () async {
        // nothing is emitted
        final stream0 = _queryStream(0).mapToOne((row) => row);
        await expectLater(
          stream0,
          emitsError(isStateError),
        );

        // emit mapped value
        final stream1 = _queryStream(1).mapToOne((row) => row);
        await expectLater(
          stream1,
          emits(<String, Object?>{}),
        );

        // emit error when query returned more than 1 row
        final stream2 = _queryStream(2).mapToOne((row) => row);
        await expectLater(
          stream2,
          emitsError(isInstanceOf<StateError>()),
        );
      });

      // test('shouldThrowA', () {
      //   expect(
      //     () => _queryStream(0).mapToOne<int?>(null),
      //     throwsArgumentError,
      //   );
      // });

      test('shouldThrowB', () async {
        final stream = Stream<Query>.error(Exception()).mapToOne((_) => true);
        await expectLater(
          stream,
          emitsError(isA<Exception>()),
        );
      });

      test('shouldThrowC', () async {
        var i = 0;

        final stream = Rx.concat([
          _queryStream(1),
          _queryStream(1),
          _queryStream(1),
        ]).mapToOne((row) {
          if (i++ == 1) {
            throw Exception();
          } else {
            return row;
          }
        });
        await expectLater(
          stream,
          emitsInOrder(<Matcher>[
            isMap,
            emitsError(isException),
            isMap,
          ]),
        );
      });

      test('shouldThrowD', () async {
        final queryStream = _queryStream(1)
            .map<Query>((_) => () => Future.error(Exception('Query error')))
            .mapToOne((row) => row);

        await expectLater(
          queryStream,
          emitsError(isException),
        );
      });

      test('shouldThrowE', () async {
        final queryStream = _queryStream(1)
            .map<Query>((_) => () => throw Exception('Query error'))
            .mapToOne((row) => row);

        await expectLater(
          queryStream,
          emitsError(isException),
        );
      });

      test('isBroadcast', () async {
        final broadcastController = StreamController<Query>.broadcast();
        final stream1 = broadcastController.stream.mapToOne((row) => row)
          ..listen(null);
        expect(
          stream1.isBroadcast,
          isTrue,
        );

        final controller = StreamController<Query>();
        final stream2 = controller.stream.mapToOne((row) => row)..listen(null);
        expect(
          stream2.isBroadcast,
          isFalse,
        );

        await Future.wait<void>(
            [broadcastController.close(), controller.close()]);
      });

      test('asBroadcastStream', () async {
        final stream =
            _queryStream(1).mapToOne((row) => row).asBroadcastStream();

        // listen twice on same stream
        stream.listen(null);
        stream.listen(null);

        // code should reach here
        await expectLater(true, true);
      });

      test('pause.resume', () async {
        late StreamSubscription<Map<String, Object?>> subscription;

        subscription = _queryStream(1)
            .delay(const Duration(milliseconds: 500))
            .mapToOne((i) => i)
            .listen(
          expectAsync1(
            (data) {
              expect(data, isMap);
              subscription.cancel();
            },
          ),
        );

        subscription.pause();
        subscription.resume();
      });
    });

    group('mapToList', () {
      test('works', () async {
        // emit empty list
        final stream0 = _queryStream(0).mapToList((row) => row);
        await expectLater(
          stream0,
          emits(<Map<String, Object?>>[]),
        );

        // emit list that contains single mapped value
        final stream1 = _queryStream(1).mapToList((row) => row);
        await expectLater(
          stream1,
          emits([<String, Object?>{}]),
        );

        // emit list that contains 2 mapped values
        final stream2 = _queryStream(2).mapToList((row) => row);
        await expectLater(
          stream2,
          emits([
            <String, Object?>{},
            <String, Object?>{},
          ]),
        );
      });

      // test('shouldThrowA', () {
      //   expect(
      //     () => _queryStream(0).mapToList<int>(null),
      //     throwsArgumentError,
      //   );
      // });

      test('shouldThrowB', () async {
        final stream = Stream<Query>.error(Exception()).mapToList((_) => true);
        await expectLater(
          stream,
          emitsError(isA<Exception>()),
        );
      });

      test('shouldThrowC', () async {
        var i = 0;

        final stream = Rx.concat([
          _queryStream(1),
          _queryStream(1),
          _queryStream(1),
        ]).mapToList((row) {
          if (i++ == 1) {
            throw Exception();
          } else {
            return row;
          }
        });
        await expectLater(
          stream,
          emitsInOrder(<Object>[
            [<String, Object?>{}],
            emitsError(isException),
            [<String, Object?>{}],
          ]),
        );
      });

      test('shouldThrowD', () async {
        final queryStream = _queryStream(1)
            .map<Query>((_) => () => Future.error(Exception('Query error')))
            .mapToList((row) => row);

        await expectLater(
          queryStream,
          emitsError(isException),
        );
      });

      test('shouldThrowE', () async {
        final queryStream = _queryStream(1)
            .map<Query>((_) => () => throw Exception('Query error'))
            .mapToList((row) => row);

        await expectLater(
          queryStream,
          emitsError(isException),
        );
      });

      test('isBroadcast', () async {
        final broadcastController = StreamController<Query>.broadcast();
        final stream1 = broadcastController.stream.mapToList((row) => row)
          ..listen(null);
        expect(
          stream1.isBroadcast,
          isTrue,
        );

        final controller = StreamController<Query>();
        final stream2 = controller.stream.mapToList((row) => row)..listen(null);
        expect(
          stream2.isBroadcast,
          isFalse,
        );

        await Future.wait<void>(
            [broadcastController.close(), controller.close()]);
      });

      test('asBroadcastStream', () async {
        final stream =
            _queryStream(1).mapToList((row) => row).asBroadcastStream();

        // listen twice on same stream
        stream.listen(null);
        stream.listen(null);

        // code should reach here
        await expectLater(true, true);
      });

      test('pause.resume', () async {
        late StreamSubscription<List<Map<String, Object?>>> subscription;

        subscription = _queryStream(1)
            .delay(const Duration(milliseconds: 500))
            .mapToList((i) => i)
            .listen(
          expectAsync1(
            (data) {
              expect(data, isList);
              subscription.cancel();
            },
          ),
        );

        subscription.pause();
        subscription.resume();
      });
    });
  });
}
