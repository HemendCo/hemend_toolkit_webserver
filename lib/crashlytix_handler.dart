import 'package:hive/hive.dart';

import 'db_toolkit.dart';

abstract class CrashlytixHandler {
  static late Box<Map> db;
  static Future<void> initDb() async {
    db = await DataBaseHandler.initCrashlytixDb();
  }

  static Future<void> logData(Map data) async {
    db.add(data);
  }

  static List<Map> getLogs() {
    return List<Map>.from(db.values);
  }
}
