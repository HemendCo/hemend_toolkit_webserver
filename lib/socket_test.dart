import 'dart:convert';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

Future<void> testWebSocket() async {
  var handler = webSocketHandler((webSocket, _) {
    webSocket.stream.listen(
      (message) async {
        print(message);
        final messageJson = jsonDecode(message.toString());
        bool theme = messageJson['theme'];
        while (true) {
          await Future.delayed(const Duration(seconds: 1), () {
            theme = !theme;
            webSocket.sink.add(jsonEncode({'theme': theme}));
          });
        }
      },
    );
  });

  shelf_io.serve(handler, '0.0.0.0', 8083).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}
