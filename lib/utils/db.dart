import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> getAppDb() async {
  return await databaseFactory.openDatabase(
    "${(await getApplicationDocumentsDirectory()).path}/miteru/db",
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) {
        db.execute("""
            CREATE TABLE IF NOT EXISTS SearchHistory (
            query TEXT,
            searchtime TEXT
          )""");
      },
    ),
  );
}
