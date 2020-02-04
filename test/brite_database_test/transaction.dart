import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqlbrite/src/brite_database.dart';

import '../mocks.dart';

void main() {
  group('Transaction', () {
    Database db;
    BriteDatabase briteDb;

    setUp(() {
      db = MockDatabase();
      briteDb = BriteDatabase(db);
    });

    test('Triggers query again after transactionAndTrigger completes',
        () async {
      final transaction = MockTransaction();
      when(transaction.insert('Table', <String, dynamic>{}))
          .thenAnswer((_) => Future.value(0));
      when(transaction.delete('Table')).thenAnswer((_) => Future.value(1));
      when(
        transaction.update(
          'Table',
          <String, dynamic>{},
        ),
      ).thenAnswer((_) => Future.value(1));

      when(
        db.transaction<dynamic>(
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
        emitsInOrder([
          isQuery,
          isQuery, // insert
          isQuery, // delete
          isQuery, // update
        ]),
      );
      await briteDb.transactionAndTrigger<int>((transaction) {
        return transaction.insert(
          'Table',
          <String, dynamic>{},
        );
      });
      await briteDb.transactionAndTrigger<int>((transaction) {
        return transaction.delete('Table');
      });
      await briteDb.transactionAndTrigger<int>((transaction) {
        return transaction.update(
          'Table',
          <String, dynamic>{},
        );
      });
      await expect;
    });
  });
}
