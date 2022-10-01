import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final databaseFactory = databaseFactoryFfi;

Future<Database> initDeleteDbAndOpen(String dbName) async {
  // Init ffi loader if needed.
  sqfliteFfiInit();

  final path = await initDeleteDb(dbName);
  return await databaseFactory.openDatabase(path);
}

Future<String> initDeleteDb(String dbName) async {
  final databasesPath = await createDirectory(null);
  final path = join(databasesPath, dbName);
  await databaseFactory.deleteDatabase(path);
  return path;
}

Future<String> createDirectory(String? path) async {
  path = await fixDirectoryPath(path);
  try {
    await Directory(path).create(recursive: true);
  } catch (_) {}
  return path;
}

/// Fix directory path relative to the databases path if possible.
Future<String> fixDirectoryPath(String? path) async {
  if (path == null) {
    path = await databaseFactory.getDatabasesPath();
  } else {
    if (!isInMemoryPath(path) && isRelative(path)) {
      path = join(await databaseFactory.getDatabasesPath(), path);
    }
  }
  return path;
}

bool isInMemoryPath(String path) => path == inMemoryDatabasePath;
