import 'dart:convert';

import 'package:example_web_server/db_toolkit.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:dio/dio.dart' as dio;

const _hookAddress = 'https://eo2znn8ui16eecf.m.pipedream.net';
Future<void> initTickets(RouterPlus app) async {
  final ticketsBox = await DataBaseHandler.ticketsDb();
  final client = dio.Dio(dio.BaseOptions(baseUrl: _hookAddress));
  app.get(
    '/tickets/getAll',
    (Request request) {
      final id = request.headers['id'];
      if (id == null) {
        return Response.notFound('');
      }
      final tickets = ticketsBox.values
          .where(
            (element) => element['id'] == id,
          )
          .toList();
      return Response.ok(jsonEncode(tickets));
    },
  );
  app.post(
    '/tickets/send',
    (Request request) async {
      final ticketData = await request.body.asJson;
      await ticketsBox.add(
        {
          'sender': 'client',
          'id': ticketData['id'],
          'text': ticketData['text'],
        },
      );
      await client.post(
        '/',
        data: {
          'id': ticketData['id'],
          'text': ticketData['text'],
        },
      );
      return Response.ok('');
    },
  );
  app.post(
    '/tickets/reply',
    (Request request) async {
      final replyData = await request.body.asJson;
      await ticketsBox.add(
        {
          'sender': 'operator',
          'id': replyData['id'],
          'text': replyData['text'],
        },
      );
      return Response.ok('');
    },
  );
}
