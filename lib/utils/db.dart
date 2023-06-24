import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> getAppDb() async {
  return await databaseFactory.openDatabase(
    "${(await getApplicationDocumentsDirectory()).path}/miteru/db",
    options: OpenDatabaseOptions(
      version: 2,
      onCreate: (db, version) {
        db.execute(
          """
            CREATE TABLE IF NOT EXISTS SearchHistory (
              query TEXT,
              searchtime TEXT,
              UNIQUE(query)
            );
          """
        );
      },
    ),
  );
}

/// DO NOT USE IN PRODUCTION CODE, DEBUG PURPOSES ONLY
/// (Although it shouldn't work in prod anyways)
void purgeTheDatabase() async {
  if (!kDebugMode) {
    return;
  }
  databaseFactory.deleteDatabase(
      "${(await getApplicationDocumentsDirectory()).path}/miteru/db");
}
