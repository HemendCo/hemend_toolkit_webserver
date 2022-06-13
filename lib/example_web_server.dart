import 'dart:io';

import 'package:shelf/shelf.dart' show Request, Response;
import 'package:shelf/shelf_io.dart' as io show serve;
import 'package:shelf_router/shelf_router.dart' show Router;

Future<HttpServer> setupWebServer() async {
  var app = Router();

  app.get('/hello', (Request request) {
    return Response.ok('hello-world');
  });

  app.get('/user/<user>', (Request request, String user) {
    return Response.ok('hello $user');
  });

  var server = await io.serve(app, '0.0.0.0', 1025);
  return server;
}
