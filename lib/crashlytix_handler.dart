import 'package:example_web_server/app_config/app_config.dart';
import 'package:hive/hive.dart';

import 'db_toolkit.dart';

abstract class CrashlytixHandler {
  static late Box<Map> db;
  static Future<void> initDb(AppConfig config) async {
    db = await DataBaseHandler.initCrashlytixDb(config.dbPath);
  }

  static Future<void> logData(Map data) async {
    db.add(data);
  }

  static List<Map> getLogs() {
    return List<Map>.from(db.values);
  }
}
