import 'package:hive/hive.dart';

abstract class DataBaseHandler {
  static void initHive(String path) {
    Hive.init(path);
  }

  static LazyBox<Map> initCrashlytixDb() {
    return Hive.lazyBox<Map>('crashlytix_logs');
  }

  static LazyBox<Map> ticketsDb() {
    return Hive.lazyBox<Map>('tickets_db');
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
