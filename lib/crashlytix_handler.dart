import 'package:hive/hive.dart';

import 'db_toolkit.dart';

abstract class CrashlytixHandler {
  static late LazyBox<Map> db;
  static Future<void> initDb() async {
    db = DataBaseHandler.initCrashlytixDb();
  }

  static Future<void> logData(Map data) async {
    db.add(data);
  }

  static Future<List<Map>> getLogs({
    List<String> filters = const [],
    String? filterType,
    String? sortBy,
    String? sortType,
    List<String> select = const [],
  }) async {
    final logs = List<Map>.from(await db.getValues().toList());
    final filterResult = _filterLogs(logs, filters, filterType ?? 'and');
    final sortResult = _sortWith(filterResult, sortBy, sortType);
    final selectResult = _selectFrom(sortResult, select);
    return selectResult;
  }

  static List<Map> _filterLogs(List<Map> logs, List<String> filters, String? filterType) {
    var result = <Map>[];
    if (filters.isEmpty) {
      return logs;
    }

    for (final filter in filters) {
      final operator = _getOperatorOf(filter);
      final filterKey = filter.split(operator)[0].split('.');

      result.addAll(
        logs.where(
          (log) => _compare(
            left: _getValueByLinks(log, filterKey).toString(),
            operator: operator,
            right: filter.split(operator)[1],
          ),
        ),
      );
    }
    if (filterType == 'and') {
      for (final filter in filters) {
        final operator = _getOperatorOf(filter);
        final filterKey = filter.split(operator)[0].split('.');

        result = result
            .where(
              (log) => _compare(
                left: _getValueByLinks(log, filterKey).toString(),
                operator: operator,
                right: filter.split(operator)[1],
              ),
            )
            .toList();
      }
    }
    return result;
  }

  static String _getOperatorOf(String input) {
    if (input.contains('==')) {
      return '==';
    }
    if (input.contains('!=')) {
      return '!=';
    }
    if (input.contains('>=')) {
      return '>=';
    }
    if (input.contains('<=')) {
      return '<=';
    }
    if (input.contains('>')) {
      return '>';
    }
    if (input.contains('<')) {
      return '<';
    }
    throw Exception('no operator found');
  }

  static bool _compare({
    required String left,
    required String operator,
    required String right,
  }) {
    final leftValue = _castToReal(left);
    final rightValue = _castToReal(right);
    switch (operator) {
      case '==':
        return leftValue == rightValue;
      case '!=':
        return leftValue != rightValue;
      case '>':
        return leftValue.compareTo(rightValue) > 0;
      case '>=':
        return leftValue.compareTo(rightValue) >= 0;
      case '<':
        return leftValue.compareTo(rightValue) < 0;
      case '<=':
        return leftValue.compareTo(rightValue) <= 0;
      default:
        return false;
    }
  }

  static dynamic _castToReal(String input) {
    // return input;
    if (input == 'false' || input == 'true') {
      return input == 'true';
    }
    if (int.tryParse(input) != null) {
      return int.parse(input);
    }
    if (double.tryParse(input) != null) {
      return double.parse(input);
    }
    return input;
  }

  static dynamic _getValueByLinks(Map element, List<String> links) {
    if (links.isEmpty) {
      return element;
    }
    final link = links.first;
    final linksRest = links.sublist(1);
    if (element[link] is Map) {
      return _getValueByLinks(element[link], linksRest);
    } else {
      return element[link];
    }
  }

  static List<Map> _sortWith(
    List<Map> filterResult,
    String? sortBy, [
    String? sortType = 'asc',
  ]) {
    if (sortBy == null) {
      return filterResult;
    }
    final sortResult = List<Map>.from(filterResult)
      ..sort((a, b) {
        final left = _getValueByLinks(a, sortBy.split('.'));
        final right = _getValueByLinks(b, sortBy.split('.'));
        if (left is String && right is String) {
          return sortType == 'asc' ? left.compareTo(right) : right.compareTo(left);
        } else if (left is int && right is int) {
          return sortType == 'asc' ? left.compareTo(right) : right.compareTo(left);
        } else if (left is double && right is double) {
          return sortType == 'asc' ? left.compareTo(right) : right.compareTo(left);
        } else if (left is DateTime && right is DateTime) {
          return sortType == 'asc' ? left.compareTo(right) : right.compareTo(left);
        } else {
          return 0;
        }
      });
    return sortResult;
  }

  static List<Map> _selectFrom(List<Map> sortResult, List<String> select) {
    if (select.isEmpty) {
      return sortResult;
    }
    List<Map> result = <Map>[];
    for (final log in sortResult) {
      final selectResult = <String, dynamic>{};
      for (final selectKey in select) {
        final selectKeySplit = selectKey.split('.');
        final value = _getValueByLinks(log, selectKeySplit);
        selectResult[selectKey] = value;
      }
      result.add(selectResult);
    }

    return result;
  }
}
