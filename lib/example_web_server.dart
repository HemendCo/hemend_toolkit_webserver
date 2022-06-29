import 'dart:convert';
import 'dart:io';

import 'package:example_web_server/app_config/app_config.dart';
import 'package:shelf/shelf_io.dart' as io show serve;
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_plus/shelf_plus.dart';

import 'crashlytix_handler.dart';

Future<HttpServer> setupWebServer(AppConfig appConfig) async {
  var app = Router().plus;
  await CrashlytixHandler.initDb(appConfig);
  app.post('/upload/<path>', (Request req, String path) async {
    final recordedFiles = <String>[];
    print(req);
    await for (final part in req.multipartFormData) {
      if (part.filename != null) {
        Directory('files/$path/').createSync(recursive: true);
        File('files/$path/${part.filename}').writeAsBytesSync(await part.part.readBytes());
        recordedFiles.add('files/$path/${part.filename}');
      }
    }
    return Response.ok({
      'status': 'ok',
      'path': recordedFiles,
    }.toString());
  });
  app.get('/files/<path>/<fileName>', (Request request, String path, String fileName) {
    final file = File('files/$path/$fileName');
    if (!file.existsSync()) {
      return Response.notFound('File not found');
    }
    return file.readAsBytesSync();
  });
  app.post('/crashlytix/log', (
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
  app.get('/crashlytix/log', (
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

    // final logs = CrashlytixHandler.getLogs();

    return Response.ok(
      outputView(jsonEncode(logs)),
      headers: {
        'Content-Type': 'text/html',
      },
    );
  });

  var server = await io.serve(app, appConfig.host, appConfig.port);
  // print('Crashlytix is running on http://${appConfig.host}:${appConfig.port}/crashlytix/log');
  return server;
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
