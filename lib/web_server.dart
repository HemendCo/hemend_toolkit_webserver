import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:example_web_server/app_config/app_config.dart';
import 'package:example_web_server/db_toolkit.dart';
import 'package:example_web_server/tickets_side.dart';
import 'package:shelf/shelf_io.dart' as io show serve;
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_plus/shelf_plus.dart' as plus;
import 'package:uuid/uuid.dart';

import 'crashlytix_handler.dart';

Future<HttpServer> setupWebServer(AppConfig appConfig) async {
  // final ip = 'Debug';
  print('initializing server');

  final ip = (await dio.Dio().get('https://api.ipify.org?format=json')).data['ip'];
  final serverUrl = appConfig.serverAddressOverride ?? 'http://$ip:${appConfig.port}';
  final serverPref = appConfig.baseRoute;

  var app = Router().plus;
  DataBaseHandler.initHive(appConfig.dbPath);
  await CrashlytixHandler.initDb();
  await initTickets(app, serverUrl);
  app.post('${serverPref}upload/<path>', (Request req, String path) async {
    final recordedFiles = <String>[];
    print('file size: ${req.contentLength}');

    await for (final part in req.multipartFormData) {
      if (part.filename != null) {
        Directory('files/$path/').createSync(recursive: true);
        File('files/$path/${part.filename}').writeAsBytesSync(await part.part.readBytes());
        recordedFiles.add('files/$path/${part.filename}');
      }
    }

    dio.Dio()
        .post(
          'https://eo3w8iqr9l7rl5q.m.pipedream.net',
          data: {
            "text": recordedFiles.map((e) => '$serverUrl/$e').join('\n'),
            "alarm": true,
          },
        )
        .then((value) => null)
        .onError((error, stackTrace) => null);
    return Response.ok(
      {
        'status': 'ok',
        'path': recordedFiles,
      }.toString(),
    );
  });
  app.get(
    '${serverPref}apps/<path>/<appName>',
    (Request request, String path, String appName) async {
      final parent = Directory('files/$path/');
      final nameMatcher =
          RegExp((request.headers['parser'] ?? request.requestedUri.queryParameters['parser']).toString());
      final List<Map<String, dynamic>> results = [];
      await for (final item in parent.list(recursive: true)) {
        if (item is File) {
          final fileName = item.uri.pathSegments.last;
          if (fileName.startsWith(appName)) {
            final regexResult = nameMatcher.allMatches(fileName).toList();
            if (regexResult.isNotEmpty) {
              final match = regexResult.first;
              final name = match.namedGroup('name');
              final version = match.namedGroup('version');
              results.add(
                {
                  'name': name,
                  'version': version,
                  'download_url': '$serverUrl/files/$path/$fileName',
                },
              );
            }
          }
        }
      }
      if (results.isNotEmpty) {
        return Response.ok(jsonEncode(results));
      }
      return Response.notFound(jsonEncode({'error': 'nothing found'}));
    },
  );
  app.get('${serverPref}files/<path>/<fileName>', (Request request, String path, String fileName) {
    final file = File('files/$path/$fileName');

    if (!file.existsSync()) {
      return Response.notFound('File not found');
    }
    return file.readAsBytesSync();
  });
  app.get('${serverPref}images/<path>/<fileName>', (Request request, String path, String fileName) {
    final file = File('files/$path/$fileName');

    if (!file.existsSync()) {
      return Response.notFound('File not found');
    }

    final data = file.readAsBytesSync();

    return plus.Response.ok(
      data,
      headers: {
        'Content-Length': data.length.toString(),
        'Content-Type': 'image/png',
      },
    );
  });
  app.post('${serverPref}crashlytix/log', (
    Request request,
  ) async {
    print('Post Request: /crashlytix/log');
    final bodyString = await request.readAsString();
    print('unformatted string $bodyString');
    final bodyJson = jsonDecode(bodyString)['data'];
    print('body: $bodyJson');
    // final body = json.decode(bodyJson);
    CrashlytixHandler.logData(bodyJson);
    return Response.ok({'status': 'ok'}.toString());
  });
  app.post('${serverPref}records/log', (
    Request request,
  ) async {
    print('Post Request: /records/log');
    final bodyString = await request.readAsString();
    print('unformatted string $bodyString');
    final unique = Uuid().v1();
    final time = DateTime.now().millisecondsSinceEpoch;
    final file = File('raws/$time-$unique.json');
    file.createSync(recursive: true);
    await file.writeAsString(bodyString);
    return Response.ok(jsonEncode({
      'status': 'ok',
      'path': file.uri.pathSegments.last,
    }));
  });
  app.get('${serverPref}crashlytix/log', (
    Request request,
  ) async {
    final filters = (request.url.queryParameters['filters']?.split(',') ?? []).map(Uri.decodeFull).toList();
    final filterType = request.url.queryParameters['filterType']?.toLowerCase();
    final sortBy = request.url.queryParameters['sortBy'];
    final sortType = request.url.queryParameters['sortType']?.toLowerCase() ?? 'asc';
    final selectParams = (request.url.queryParameters['select']?.split(',') ?? []).map(Uri.decodeFull).toList();
    final logs = CrashlytixHandler.getLogs(
      filters: filters,
      filterType: filterType,
      sortBy: sortBy,
      sortType: sortType,
      select: selectParams,
    );

    print('Get Request: /crashlytix/log');
    if (request.url.queryParameters['type'] == 'json') {
      return Response.ok(jsonEncode(logs));
    }

    return Response.ok(
      outputView(jsonEncode(logs)),
      headers: {
        'Content-Type': 'text/html',
      },
    );
  });

  print('starting to serve');
  var server = await io.serve(app, appConfig.host, appConfig.port);
  // print('Crashlytix is running on http://${appConfig.host}:${appConfig.port}/crashlytix/log');
  return server;
}

extension ListBreaker<T> on List<T> {
  Iterable<Iterable<T>> splitByPart(List<T> splitter) {
    final parts = <Iterable<T>>[];
    int start = 0;
    for (int i = 0; i < length; i++) {
      if (this[i] == splitter[0]) {
        if (splitter.length == 1) {
          parts.add(sublist(start, i));
          start = i + 1;
        } else {
          if (i + splitter.length <= length && sublist(i, i + splitter.length).join('') == splitter.join('')) {
            parts.add(sublist(start, i));
            start = i + splitter.length;
            i += splitter.length - 1;
          }
        }
      }
    }
    parts.add(sublist(start, length));
    return parts;
  }

  Iterable<Iterable<T>> breakToPieceOfSize(int pieceSize) {
    final result = <Iterable<T>>[];
    var current = <T>[];
    for (var item in this) {
      current.add(item);
      if (current.length == pieceSize) {
        result.add(current);
        current = <T>[];
      }
    }
    if (current.isNotEmpty) {
      result.add(current);
    }
    return result;
  }

  Iterable<Iterable<T>> breakToPiecesOfSizes(List<int> pieceSizes) {
    final result = <Iterable<T>>[];
    int pieceIndex = 0;
    var current = <T>[];
    for (var item in this) {
      current.add(item);
      if (current.length == pieceSizes[pieceIndex]) {
        pieceIndex++;
        result.add(current);
        current = <T>[];
      }
    }
    if (current.isNotEmpty) {
      result.add(current);
    }
    return result;
  }
}

String outputView(String json) {
  return '''
<html lang="en">
<head>
    <style>
        @import url("https://fonts.googleapis.com/css?family=Source+Code+Pro");

        .json {
            font-family: "Source Code Pro", monospace;
            font-size: 16px;
        }

        .json>.json__item {
            display: block;
        }

        .json__item {
            display: none;
            margin-top: 10px;
            padding-left: 20px;
            -webkit-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
        }

        .json__item--collapsible {
            cursor: pointer;
            overflow: hidden;
            position: relative;
        }

        .json__item--collapsible::before {
            content: "+";
            position: absolute;
            left: 5px;
        }

        .json__item--collapsible::after {
            background-color: lightgrey;
            content: "";
            height: 100%;
            left: 9px;
            position: absolute;
            top: 26px;
            width: 1px;
        }

        .json__item--collapsible:hover>.json__key,
        .json__item--collapsible:hover>.json__value {
            text-decoration: underline;
        }

        .json__toggle {
            display: none;
        }

        .json__toggle:checked~.json__item {
            display: block;
        }

        .json__key {
            color: darkblue;
            display: inline;
        }

        .json__key::after {
            content: ": ";
        }

        .json__value {
            display: inline;
        }

        .json__value--string {
            color: green;
        }

        .json__value--number {
            color: blue;
        }

        .json__value--boolean {
            color: red;
        }
    </style>

</head>

<body translate="no" data-new-gr-c-s-check-loaded="14.1063.0" data-gr-ext-installed="">
    <div id=".target">
    </div>
    <script
        src="https://cpwebassets.codepen.io/assets/common/stopExecutionOnTimeout-1b93190375e9ccc259df3a57c1abc0e64599724ae30d7ea4c6877eb615f89387.js"></script>


    <script id="rendered-js">
        function jsonViewer(json, collapsible = false) {
            var TEMPLATES = {
                item: '<div class="json__item"><div class="json__key">%KEY%</div><div class="json__value json__value--%TYPE%">%VALUE%</div></div>',
                itemCollapsible: '<label class="json__item json__item--collapsible"><input type="checkbox" class="json__toggle"/><div class="json__key">%KEY%</div><div class="json__value json__value--type-%TYPE%">%VALUE%</div>%CHILDREN%</label>',
                itemCollapsibleOpen: '<label class="json__item json__item--collapsible"><input type="checkbox" checked class="json__toggle"/><div class="json__key">%KEY%</div><div class="json__value json__value--type-%TYPE%">%VALUE%</div>%CHILDREN%</label>'
            };


            function createItem(key, value, type) {
                var element = TEMPLATES.item.replace('%KEY%', key);

                if (type == 'string') {
                    element = element.replace('%VALUE%', '"' + value + '"');
                } else {
                    element = element.replace('%VALUE%', value);
                }

                element = element.replace('%TYPE%', type);

                return element;
            }

            function createCollapsibleItem(key, value, type, children) {
                var tpl = 'itemCollapsible';

                if (collapsible) {
                    tpl = 'itemCollapsibleOpen';
                }

                var element = TEMPLATES[tpl].replace('%KEY%', key);

                element = element.replace('%VALUE%', type);
                element = element.replace('%TYPE%', type);
                element = element.replace('%CHILDREN%', children);

                return element;
            }

            function handleChildren(key, value, type) {
                var html = '';

                for (var item in value) {
                    var _key = item,
                        _val = value[item];

                    html += handleItem(_key, _val);
                }

                return createCollapsibleItem(key, value, type, html);
            }

            function handleItem(key, value) {
                var type = typeof value;

                if (typeof value === 'object') {
                    return handleChildren(key, value, type);
                }

                return createItem(key, value, type);
            }

            function parseObject(obj) {
                _result = '<div class="json">';

                for (var item in obj) {
                    var key = item,
                        value = obj[item];

                    _result += handleItem(key, value);
                }

                _result += '</div>';

                return _result;
            }

            return parseObject(json);
        };



        var json = #JSON;


        var el = document.getElementById('.target');
        el.innerHTML = jsonViewer(json, true);
//# sourceURL=pen.js
    </script>







</body>
<grammarly-desktop-integration data-grammarly-shadow-root="true"></grammarly-desktop-integration>

</html>
'''
      .replaceAll('#JSON', json);
}
