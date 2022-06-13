import 'package:hive/hive.dart';

abstract class DataBaseHandler {
  static Future<Box<Map>> initCrashlytixDb() {
    Hive.init('/home/motalleb/Documents/crashlytix_data');
    return Hive.openBox<Map>('crashlytix_logs');
  }
}
