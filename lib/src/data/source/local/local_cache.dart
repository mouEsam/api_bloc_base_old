import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class LocalCache {
  static const String dbPath = 'sample.db';

  final Database _db;

  const LocalCache._(this._db);

  static Future<LocalCache> create() async {
    DatabaseFactory dbFactory = databaseFactoryIo;
    final directory = await getApplicationDocumentsDirectory();
    Database db =
        await dbFactory.openDatabase('${directory.path}/cache/$dbPath');
    return LocalCache._(db);
  }
}
