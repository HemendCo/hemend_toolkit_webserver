import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:example_web_server/db_toolkit.dart';
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:dio/dio.dart' as dio;

const _hookAddress = 'https://eo2znn8ui16eecf.m.pipedream.net';
Future<String> _recordFile(String id, String name, Uint8List data) async {
  final file = File('files/$id/${DateTime.now().toIso8601String()}-$name.png');
  await file.create(recursive: true);
  await file.writeAsBytes(data);
  return file.path;
}

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
      final ticketData = request.multipartFormData;
      final formInfo = <String, dynamic>{'assets': []};
      final filesArray = <String, Uint8List>{};
      await for (final field in ticketData) {
        if (field.name.startsWith('asset')) {
          filesArray[field.name] = await field.part.readBytes();
        } else {
          formInfo[field.name] = String.fromCharCodes(await field.part.readBytes());
        }
      }
      if (formInfo['id'] == null) {
        return Response.badRequest();
      }
      for (final i in filesArray.entries) {
        final fileName = await _recordFile(
          formInfo['id'],
          i.key,
          i.value,
        );
        formInfo['assets'] = [
          ...formInfo['assets'],
          fileName,
        ];
      }
      await ticketsBox.add(
        {
          'sender': 'client',
          'id': formInfo['id'],
          'text': formInfo['text'],
          'assets': formInfo['assets'],
          'dateTime': DateTime.now().toUtc().millisecondsSinceEpoch,
        },
      );
      // await client.post(
      //   '/',
      //   data: {
      //     'id': ticketData['id'],
      //     'text': ticketData['text'],
      //   },
      // );
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
          'dateTime': DateTime.now().toUtc().millisecondsSinceEpoch,
        },
      );
      return Response.ok('');
    },
  );
}