import 'dart:async';

import 'package:collection/collection.dart';
import 'package:example/data/app_db.dart';
import 'package:example/data/item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

import 'data/faker.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _dateFormatter = DateFormat.Hms().add_yMMMd();

  late final StateStream<ViewState> items$ = AppDb.getInstance()
      .getAllItems()
      .map((items) => ViewState.success(items))
      .onErrorReturnWith((e, s) => ViewState.failure(e, s))
      .debug(identifier: '<<STATE>>', log: debugPrint)
      .publishState(ViewState.loading)
    ..connect().addTo(compositeSubscription);

  final compositeSubscription = CompositeSubscription();

  @override
  void initState() {
    super.initState();
    final _ = items$;
  }

  @override
  void dispose() {
    compositeSubscription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('sqlbrite example'),
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        child: StreamBuilder<ViewState>(
          stream: items$,
          initialData: items$.value,
          builder: (context, snapshot) {
            final state = snapshot.requireData;

            if (state.error != null) {
              debugPrint('Error: ${state.error!.error}');
              debugPrint('Stacktrace: ${state.error!.stackTrace}');

              return Center(
                child: Text(
                  'Error: ${state.error!.error}',
                  style: Theme.of(context).textTheme.headline6,
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final items = state.items;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return ListTile(
                  title: Text(item.content),
                  subtitle:
                      Text('Created: ${_dateFormatter.format(item.createdAt)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () => _remove(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _update(item),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _add() async {
    final item = Item(
      null,
      contents.random(),
      DateTime.now(),
    );
    final success = await AppDb.getInstance().insert(item);
    debugPrint('Add: $success');
  }

  void _remove(Item item) async {
    final success = await AppDb.getInstance().remove(item);
    debugPrint('Remove: $success');
  }

  void _update(Item item) async {
    final success = await AppDb.getInstance().update(
      item.copyWith(
        contents.random(),
      ),
    );
    debugPrint('Update: $success');
  }
}

class ViewState {
  final List<Item> items;
  final bool isLoading;
  final AsyncError? error;

  static const loading = ViewState._([], true, null);

  const ViewState._(this.items, this.isLoading, this.error);

  ViewState.success(List<Item> items) : this._(items, false, null);

  ViewState.failure(Object e, StackTrace s)
      : this._([], false, AsyncError(e, s));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewState &&
          runtimeType == other.runtimeType &&
          const ListEquality<Item>().equals(items, other.items) &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => items.hashCode ^ isLoading.hashCode ^ error.hashCode;

  @override
  String toString() =>
      'ViewState{items.length: ${items.length}, isLoading: $isLoading, error: $error}';
}
