import 'package:hive/hive.dart';

abstract class DataBaseHandler {
  static Future<Box<Map>> initCrashlytixDb(String path) {
    Hive.init(path);
    return Hive.openBox<Map>('crashlytix_logs');
  }
}
