import 'package:example_web_server/example_web_server.dart' as web_server_handler;

Future<void> main(List<String> arguments) async {
  final server = await web_server_handler.setupWebServer();
  print('Serving on http://${server.address.host}:${server.port}');
}
