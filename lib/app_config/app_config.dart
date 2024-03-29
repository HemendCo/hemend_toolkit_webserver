import 'dart:io';

import 'package:args/args.dart';

class AppConfig {
  final int port;
  final String host;
  final String dbPath;
  final String baseRoute;
  final String? serverAddressOverride;
  const AppConfig({
    required this.port,
    required this.host,
    required this.dbPath,
    required this.baseRoute,
    required this.serverAddressOverride,
  });

  factory AppConfig.fromArgs(List<String> args) {
    var parser = ArgParser();
    parser.addOption(
      'base-path',
      defaultsTo: Platform.environment['HEM_PATH'] ?? '/',
    );

    parser.addOption(
      'port',
      abbr: 'p',
      defaultsTo: Platform.environment['HEM_PORT'] ?? '8081',
      help: 'Port to run the server on',
      callback: (port) {
        if (port == null) {
          return;
        }
        final portValue = int.tryParse(port);
        if (portValue == null) {
          print('Port must be an integer');
          print(parser.usage);
          exit(64);
        }
        if (portValue < 1024) {
          print('Port must be greater than 1024');
          print(parser.usage);
          exit(64);
        }
      },
    );
    parser.addOption(
      'host',
      abbr: 'h',
      defaultsTo: Platform.environment['HEM_ADDRESS'] ?? '0.0.0.0',
      help: 'hostname to run the server on',
    );
    parser.addOption(
      'address-override',
      abbr: 'a',
      help: 'address Override',
      defaultsTo: Platform.environment['HEM_URL'],
    );

    parser.addOption(
      'db-path',
      abbr: 'd',
      defaultsTo: Platform.environment['HEM_DB_PATH'] ?? 'clogger_db',
      help: 'Path to the database',
      callback: (dbAddr) {
        if (dbAddr == null) {
          return;
        }
        final dbAddrValue = Uri.tryParse(dbAddr);
        if (dbAddrValue == null) {
          print('db-path must be a valid URI');
          print(parser.usage);
          exit(64);
        }
        final dbDir = Directory.fromUri(dbAddrValue);
        if (!dbDir.existsSync()) {
          print("db-path is a valid directory but don't exists, tring to create it");
          dbDir.createSync(recursive: true);
        }
      },
    );
    try {
      final parsedData = parser.parse(args);
      if (!parsedData.wasParsed('host')) {
        final addresses = NetworkInterface.list(type: InternetAddressType.IPv4);
        addresses.then(
          (value) => print('''no custom hostname provided will use its default value (0.0.0.0)
this address is open to lan and 
can be used to access the server from other machines connected to the same router via:
${value.map((e) => '${e.addresses.map((e) => e.address).join(' & ')} on ${e.name}').join('\n')}
'''),
        );
      }
      if (!parsedData.wasParsed('port')) {
        print('no custom port provided will use its default value (8081)\n');
      }
      return AppConfig(
        port: int.parse(parsedData['port']),
        host: parsedData['host'],
        baseRoute: parsedData['base-path'],
        serverAddressOverride: parsedData['address-override'],
        dbPath: parsedData['db-path'],
      );
    } catch (e) {
      print(parser.usage);
      exit(64);
    }
  }
}
