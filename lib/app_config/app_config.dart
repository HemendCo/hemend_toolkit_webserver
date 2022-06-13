import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

class AppConfig {
  final int port;
  final String host;
  final String dbPath;
  const AppConfig({
    required this.port,
    required this.host,
    required this.dbPath,
  });

  factory AppConfig.fromArgs(List<String> args) {
    var parser = ArgParser();
    parser.addOption(
      'port',
      abbr: 'p',
      defaultsTo: '8081',
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
      defaultsTo: '0.0.0.0',
      help: 'hostname to run the server on',
    );

    parser.addOption(
      'db-path',
      abbr: 'd',
      defaultsTo: 'clogger_db',
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
        dbPath: parsedData['db-path'],
      );
    } catch (e) {
      print(parser.usage);
      exit(64);
    }
  }
}
