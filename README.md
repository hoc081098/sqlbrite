SQL Brite ![alt text](https://avatars3.githubusercontent.com/u/6407041?s=32&v=4)
=========

[![Pub](https://img.shields.io/pub/vpre/sqlbrite.svg)](https://pub.dartlang.org/packages/sqlbrite)
[![Build Status](https://travis-ci.org/hoc081098/sqlbrite.svg?branch=master)](https://travis-ci.org/hoc081098/sqlbrite)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)


sqlbrite for flutter inspired by [sqlbrite](https://github.com/square/sqlbrite) - A lightweight wrapper around sqflite which introduces reactive stream semantics to SQL operations

Getting Started
-----

1. Depend on it: In your flutter project, add the dependency to your `pubspec.yaml`

```yaml
dependencies:
  ...
  sqlbrite: ^1.1.0
```

2.  Install it: You can install packages from the command line with Flutter:

```
$ flutter packages get
```

3. Import it: Now in your Dart code, you can use:

```dart
import 'package:sqlbrite/sqlbrite.dart';
```

Usage
-----

Wrap your database in a `BriteDatabase`:

```dart
final Database db;
final briteDb = BriteDatabase(db);
```

The `BriteDatabase.createQuery` method is similar to `Database.query`. Listen to the returned
`Observable<Query>` which will immediately notify with a `Query` to run.

```dart

class Entity {
  factory Entity.fromJson(Map<String, dynamic> map) {
    return Entity(...);
  }
}

// Emits a single row, doesn't emit if the row dosen't exist, emit error if more than 1 row in result set
final Observable<Entity> singleQuery$ = briteDb.createQuery(
  'table',
  where: 'id = ?',
  whereArgs: [id],
  limit: 1,
).mapToOne((row) => Entity.fromJson(row));

// Emits a single row, or the given default value if the row doesn't exist, or emit error if more than 1 row in result set
final Observable<Entity> singleOrDefaultQuery$ = briteDb.createQuery(
  'table',
  where: 'id = ?',
  whereArgs: [id],
  limit: 1,
).mapToOneOrDefault((row) => Entity.fromJson(row));

// Emits a list of rows.
final Observable<List<Entity>> listQuery$ = briteDb.createQuery(
  'table',
  where: 'name LIKE ?',
  whereArgs: [queryName],
).mapToList((row) => Entity.fromJson(row));
```

Since queries are just regular RxDart `Observable` objects, operators can also be used to
control the frequency of notifications to subscribers. The full power of RxDart's operators are available for combining, filtering, and triggering any number of queries and data changes.

```dart
briteDb
    .createQuery(
      'table',
      where: 'name LIKE ?',
      whereArgs: [queryName],
    )
    .debounceTime(const Duration(milliseconds: 500))
    .where((Query query) => /*filtering query*/) // query is lazy, this lets you not even execute it if you don't need to
    .transform(QueryToListStreamTransformer((Map<String, dynamic> row) => Entity.fromJson(row)))
    .listen((List<Entity> entities) => /*do something*/);
```


Philosophy
----------

SQL Brite's only responsibility is to be a mechanism for coordinating and composing the notification
of updates to tables such that you can update queries as soon as data changes.

This library is not an ORM. It is not a type-safe query mechanism. It's not going to perform database migrations for you.



License
-------

    MIT License

    Copyright (c) 2019 Petrus Nguyễn Thái Học

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
