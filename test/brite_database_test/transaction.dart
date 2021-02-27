import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqlbrite/src/brite_database.dart';

import '../mocks.dart';
import '../mocks.mocks.dart';

void main() {
  group('Transaction', () {
    late MockDatabase db;
    late BriteDatabase briteDb;
    late MockTransaction transaction;

    setUp(() {
      db = MockDatabase();
      briteDb = BriteDatabase(db);
      transaction = MockTransaction();
    });

    test(
      'Triggers query again after transactionAndTrigger completes',
      () async {
        when(transaction.insert('Table', <String, Object?>{}))
            .thenAnswer((_) => Future.value(0));
        when(transaction.delete('Table')).thenAnswer((_) => Future.value(1));
        when(
          transaction.update(
            'Table',
            <String, Object?>{},
          ),
        ).thenAnswer((_) => Future.value(1));

        when(
          db.transaction<Object?>(
            any,
            exclusive: anyNamed('exclusive'),
          ),
        ).thenAnswer((invocation) {
          final action = invocation.positionalArguments[0] as Future<int>
              Function(Transaction);
          return action(transaction);
        });

        final stream$ = briteDb.createQuery('Table');
        final expect = expectLater(
          stream$,
          emitsInOrder(<Matcher>[
            isQuery,
            isQuery, // insert
            isQuery, // delete
            isQuery, // update
          ]),
        );
        await briteDb.transactionAndTrigger<int>((transaction) {
          return transaction.insert(
            'Table',
            <String, Object?>{},
          );
        });
        await briteDb.transactionAndTrigger<int>((transaction) {
          return transaction.delete('Table');
        });
        await briteDb.transactionAndTrigger<int>((transaction) {
          return transaction.update(
            'Table',
            <String, Object?>{},
          );
        });
        await expect;
      },
    );
  });
}
