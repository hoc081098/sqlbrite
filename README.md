# SQL Brite ![alt text](https://avatars3.githubusercontent.com/u/6407041?s=32&v=4)

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Tests](https://github.com/hoc081098/sqlbrite/actions/workflows/flutter.yml/badge.svg)](https://github.com/hoc081098/sqlbrite/actions/workflows/flutter.yml)
[![Build example](https://github.com/hoc081098/sqlbrite/actions/workflows/build-example.yml/badge.svg)](https://github.com/hoc081098/sqlbrite/actions/workflows/build-example.yml)
[![Pub](https://img.shields.io/pub/v/sqlbrite)](https://pub.dev/packages/sqlbrite)
[![Pub](https://img.shields.io/pub/v/sqlbrite?include_prereleases)](https://pub.dev/packages/sqlbrite)
[![Build Status](https://travis-ci.com/hoc081098/sqlbrite.svg?branch=master)](https://travis-ci.com/hoc081098/sqlbrite)
[![codecov](https://codecov.io/gh/hoc081098/sqlbrite/branch/master/graph/badge.svg)](https://codecov.io/gh/hoc081098/sqlbrite)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-pedantic-40c4ff.svg)](https://github.com/dart-lang/pedantic)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fhoc081098%2Fsqlbrite&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

-   Reactive stream wrapper around `sqflite` for Flutter inspired by [sqlbrite](https://github.com/square/sqlbrite)
-   Streaming sqflite
-   RxDart reactive stream sqflite for Flutter
-   A lightweight wrapper around sqflite which introduces reactive stream semantics to SQL operations.

## Getting Started

1. Depend on it: In your flutter project, add the dependency to your `pubspec.yaml`

```yaml
dependencies:
  ...
  sqlbrite: <latest_version>
```

2.  Install it: You can install packages from the command line with Flutter:

```shell script
$ flutter packages get
```

3. Import it: Now in your Dart code, you can use:

```dart
import 'package:sqlbrite/sqlbrite.dart';
```

## Usage

### 1. Wrap your database in a `BriteDatabase`:

```dart
final Database db = await openDb();
final briteDb = BriteDatabase(db);
final briteDb = BriteDatabase(db, logger: null); // disable logging.
```

### 2. Using

-   The `BriteDatabase.createQuery` method is similar to `Database.query`. Listen to the returned `Stream<Query>` which will immediately notify with a `Query` to run.
-   These queries will run once to get the current data, then again whenever the given table is modified though the `BriteDatabase`.

#### Create entity model
```dart
class Entity {
  factory Entity.fromJson(Map<String, dynamic> map) { ... }
  
  factory Entity.empty() { ... }

  Map<String, dynamic> toJson() { ... }
}
```

#### Use `mapToOne` extension method on `Stream<Query>`
```dart
// Emits a single row, emit error if the row doesn't exist or more than 1 row in result set.
final Stream<Entity> singleQuery$ = briteDb.createQuery(
  'table',
  where: 'id = ?',
  whereArgs: [id],
  limit: 1,
).mapToOne((row) => Entity.fromJson(row));
```

#### Use `mapToOneOrDefault` extension method on `Stream<Query>`
```dart
// Emits a single row, or the given default value if the row doesn't exist, or emit error if more than 1 row in result set
final Stream<Entity> singleOrDefaultQuery$ = briteDb.createQuery(
  'table',
  where: 'id = ?',
  whereArgs: [id],
  limit: 1,
).mapToOneOrDefault(
  (row) => Entity.fromJson(row),
  defaultValue: Entity.empty()
);
```

#### Use `mapToList` extension method on `Stream<Query>`
```dart
// Emits a list of rows.
final Stream<List<Entity>> listQuery$ = briteDb.createQuery(
  'table',
  where: 'name LIKE ?',
  whereArgs: [queryName],
).mapToList((row) => Entity.fromJson(row));
```

#### Same API like `Database`

```dart

// will trigger query stream again
briteDb.insert(
  'table',
  Entity(...).toJson()
);

// will trigger query stream again
briteDb.update(
  'table',
  Entity(...).toJson(),
  where: 'id = ?',
  whereArgs: [id],
);

// will trigger query stream again
briteDb.update(
  'table',
  where: 'id = ?',
  whereArgs: [id],
);

```

#### Full power of `RxDart` operators
-   You can use RxDart operators to control the frequency of notifications to subscribers.
-   The full power of RxDart's operators are available for combining, filtering, and triggering any number of queries and data changes.

```dart
briteDb
    .createQuery(
      'table',
      where: 'name LIKE ?',
      whereArgs: [queryName],
    )
    .debounceTime(const Duration(milliseconds: 500))
    .where(filterQuery) // query is lazy, this lets you not even execute it if you don't need to
    .mapToList((row) => Entity.fromJson(row))
    .listen(updateUI);
```

## Philosophy

SQL Brite's only responsibility is to be a mechanism for coordinating and composing the notification
of updates to tables such that you can update queries as soon as data changes.

This library is not an ORM. It is not a type-safe query mechanism. It's not going to perform database migrations for you.

## License
    MIT License
    Copyright (c) 2019 - 2022 Petrus Nguyễn Thái Học
