import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_profile_fixture.dart';

const sent = '2026-11-20T12:34:56.123456Z';
Map<String, Object?> requestJson({String state = 'Pending'}) => {
  'sender-id': otherProfileServerId,
  'receiver-id': profileServerId,
  'date-sent': sent,
  'state': state,
  'date-resolved': state == 'Pending'
      ? '0001-01-01T00:00:00Z'
      : '2026-11-20T13:00:00Z',
};
http.Response jsonResponse(Object? body, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );
