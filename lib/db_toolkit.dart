import 'package:hive/hive.dart';

abstract class DataBaseHandler {
  static void initHive(String path) {
    Hive.init(path);
  }

  static Future<Box<Map>> initCrashlytixDb() {
    return Hive.openBox<Map>('crashlytix_logs');
  }

  static Future<Box<Map>> ticketsDb() {
    return Hive.openBox<Map>('tickets_db');
  }
}
