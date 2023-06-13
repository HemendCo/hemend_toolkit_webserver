import 'package:hive/hive.dart';

abstract class DataBaseHandler {
  static void initHive(String path) {
    Hive.init(path);
  }

  static Future<LazyBox<Map>> initCrashlytixDb() {
    return Hive.openLazyBox<Map>('crashlytix_logs');
  }

  static Future<LazyBox<Map>> ticketsDb() {
    return Hive.openLazyBox<Map>('tickets_db');
  }
}

extension BoxMap<T> on LazyBox<T> {
  Stream<T> getValues() async* {
    for (final i in keys) {
      final data = await get(i);
      if (data != null) {
        yield data;
      }
    }
  }
}
