import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

class AppConfig {
  final int port;
  final String host;
  const AppConfig({
    required this.port,
    required this.host,
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
    try {
      final parsedData = parser.parse(args);
      if (!parsedData.wasParsed('host')) {
        final addressess = NetworkInterface.list(type: InternetAddressType.IPv4);
        addressess.then(
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
      );
    } catch (e) {
      print(parser.usage);
      exit(64);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'port': port,
      'host': host,
    };
  }

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      port: map['port']?.toInt() ?? 8080,
      host: map['host'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AppConfig.fromJson(String source) => AppConfig.fromMap(json.decode(source));

  @override
  String toString() => 'AppConfig(port: $port, host: $host)';
}
