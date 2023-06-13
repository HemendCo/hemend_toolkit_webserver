import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:example_web_server/db_toolkit.dart';
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:dio/dio.dart' as dio;

const _hookAddress = 'https://eo2znn8ui16eecf.m.pipedream.net';
Future<String> _recordFile(String id, String name, Uint8List data) async {
  final fileName = '$id/${DateTime.now().toIso8601String()}-$name.png';
  final file = File('files/$fileName');
  await file.create(recursive: true);
  await file.writeAsBytes(data);
  return 'images/$fileName';
}

Future<void> initTickets(RouterPlus app, String baseServerAddress) async {
  final ticketsBox = await DataBaseHandler.ticketsDb();
  final client = dio.Dio(dio.BaseOptions(baseUrl: _hookAddress));
  app.get(
    '/tickets/getAll',
    (Request request) async {
      final id = request.headers['id'];
      if (id == null) {
        return Response.notFound('');
      }
      final tickets = await ticketsBox
          .getValues()
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
          formInfo[field.name] = Utf8Decoder().convert(await field.part.readBytes());
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
          '$baseServerAddress/$fileName',
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
      await client.post(
        '/',
        data: {
          'id': formInfo['id'],
          'text': formInfo['text'],
          'assets': formInfo['assets'],
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
          'dateTime': DateTime.now().toUtc().millisecondsSinceEpoch,
        },
      );
      return Response.ok('');
    },
  );
}
