import 'package:example/data/app_db.dart';
import 'package:example/data/item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final _dateFormatter = DateFormat.Hms().add_yMMMd();

  MyHomePage({Key key}) : super(key: key);

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('sqlbrite example'),
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        child: StreamBuilder<List<Item>>(
          stream: AppDb.getInstance().getAllItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            final items = snapshot.data;

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return ListTile(
                  title: Text(item.content),
                  subtitle:
                      Text('Created: ${_dateFormatter.format(item.createdAt)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () => _remove(item),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _add,
      ),
    );
  }

  void _add() async {
    final item = Item(
      null,
      randomString(20),
      DateTime.now(),
    );
    final success = await AppDb.getInstance().insert(item);
    print('Add: $success');
  }

  void _remove(Item item) async {
    final success = await AppDb.getInstance().remove(item);
    print('Remove: $success');
  }
}
