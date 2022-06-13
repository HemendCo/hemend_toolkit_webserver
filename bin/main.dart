import 'package:example_web_server/app_config/app_config.dart';
import 'package:example_web_server/example_web_server.dart' as web_server_handler;

Future<void> main(List<String> arguments) async {
  final appConfig = AppConfig.fromArgs(arguments);
  final server = await web_server_handler.setupWebServer(appConfig);
  print('Serving on http://${server.address.host}:${server.port}');
}
