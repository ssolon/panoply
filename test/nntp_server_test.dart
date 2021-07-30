import 'dart:convert';

import 'package:loggy/loggy.dart';
import 'package:test/test.dart';

import 'package:panoply/services/nntp_server.dart';

void main() {
  Loggy.initLoggy();

  late NntpServer server;

  setUp(() {
    server = NntpServer("test_no_auth", "nntp.aioe.org");
  });

  group('Response Handling', () {
    test('Make empty header', () {
      final response = server.makeResponse('', '');

      expect(response.statusCode, equals(invalidHeaderFormat));
      expect(response.isOK, equals(false));

      expect(response.header, equals(''));
      expect(response.body, equals(''));
    });

    test('Short header', () {
      final response = server.makeResponse('300', '');

      expect(response.statusCode, equals(300));
      expect(response.isOK, true);

      expect(response.header, equals(''));
      expect(response.body, equals(''));
    });

    test('Error header', () {
      final response = server.makeResponse('400 Error four hundred', '');

      expect(response.statusCode, equals(400));
      expect(response.isOK, false);

      expect(response.header, 'Error four hundred');
      expect(response.body, '');
    });

    test('All values', () {
      final response = server.makeResponse('300 All is good', 'The body.');

      expect(response.statusCode, 300);
      expect(response.isOK, true);

      expect(response.header, 'All is good');
      expect(response.body, 'The body.');
    });

    test('Single line response', () async {
      final stream = Stream.fromIterable(['300 Some stuff in the header']);
      final response = await server.handleSingleLineResponse(stream);

      expect(response.statusCode, 300);
      expect(response.isOK, true);

      expect(response.header, 'Some stuff in the header');
      expect(response.body, '');
    });

    test('Multiline header response', () async {
      final responseLines = [
      '101 Capability list:\r\n',
      'VERSION 2\r\n',
      'IMPLEMENTATION INN 2.6.1\r\n',
      'AUTHINFO SASL\r\n',
      'COMPRESS DEFLATE\r\n',
      'HDR\r\n',
      'LIST ACTIVE ACTIVE.TIMES COUNTS DISTRIB.PATS DISTRIBUTIONS HEADERS MODERATORS MOTD NEWSGROUPS OVERVIEW.FMT SUBSCRIPTIONS\r\n',
      'NEWNEWS\r\n',
      'OVER\r\n',
      'POST\r\n',
      'READER\r\n',
      'SASL DIGEST-MD5 NTLM CRAM-MD5\r\n',
      'STARTTLS\r\n',
      'XPAT\r\n',
      '.\r\n'
      ];

      final stream = Stream.fromIterable(responseLines).transform(LineSplitter());

      // stream.takeWhile((l) => l.trimRight() != ".").forEach(print);
      final response = await server.handleMultiLineResponse(stream);

      expect(response.statusCode, 101);
      expect(response.isOK, true);

      final lines = response.header.trimRight().split('\n');
      expect(lines.length, responseLines.length-1);  // Terminating dot line removed
    });
  });

  group("Integration tests using nntp.aioe.org", ()
  {
    test('Connect to server without credentials', () async {
      expect(server, isNotNull);
      expect(server.isClosed, true, reason: "Server starts closed");
      expect(server.isOpen, false, reason: "Server starts no open");

      final response = await server.connect();
      expect(server.isClosed, false, reason: "Server not closed after connect");
      expect(server.isOpen, true, reason: "Server open after connect");
      expect(response.statusCode, equals(200));
      expect(response.isOK, true, reason: "Connect worked");

      await expectLater(
          server.close(), completes, reason: "Close should complete");
      expect(server.isClosed, true, reason: "Server closed after close");
    });
  });
}