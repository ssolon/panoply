import 'dart:convert';

import 'package:loggy/loggy.dart';
import 'package:test/test.dart';

import 'package:panoply/services/nntp_server.dart';

const userName='ssolon';
const passWord='Techprox0';

void main() {
  Loggy.initLoggy();

  late NntpServer server;

  setUp(() {
    // server = NntpServer("test_no_auth", "nntp.aioe.org");
    // server = NntpServer("faux-server", 'localhost', 65432);
    server = NntpServer('usenetserver', 'news.usenetserver.com');
  });

  tearDown(() {
    server.close();
  });

  group('Response Handling', () {
    test('Make empty header', () {
      final response = server.makeResponse([], []);

      expect(response.statusCode, invalidHeaderFormat);
      expect(response.statusLine, '');
      expect(response.isOK, false);

      expect(response.headers, []);
      expect(response.body, []);
    });

    test('Short header', () {
      final response = server.makeResponse(['300'], []);

      expect(response.statusCode, '300');
      expect(response.statusLine, '');
      expect(response.isOK, true);

      expect(response.headers, []);
      expect(response.body, []);
    });

    test('Error header', () {
      final response = server.makeResponse(['400 Error four hundred'], []);

      expect(response.statusCode, '400');
      expect(response.statusLine, 'Error four hundred');
      expect(response.isOK, false);

      expect(response.headers, []);
      expect(response.body, []);
    });

    test('All values', () {
      final response = server.makeResponse(['300 All is good'], ['The body.']);

      expect(response.statusCode, '300');
      expect(response.statusLine, 'All is good');
      expect(response.isOK, true);

      expect(response.headers, []);
      expect(response.body, ['The body.']);
    });

    test('Single line response', () async {
      final stream = Stream.fromIterable(['300 Some stuff in the header']);
      final response = await server.handleSingleLineResponse(stream);

      expect(response.statusCode, '300');
      expect(response.statusLine, 'Some stuff in the header');
      expect(response.isOK, true);

      expect(response.headers, []);
      expect(response.body, []);
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
      final response = await server.handleMultiLineResponse(stream, null);

      expect(response.statusCode, '101');
      expect(response.statusLine, 'Capability list:');
      expect(response.isOK, true);

      expect(response.body.length, responseLines.length-2);  // Terminating dot line and status removed
    });

    test('Header map response', () async {
      final responseLines = [
      '220 488627 <3d07898e391c018c.466453ad2196c56c@2b4feea2bb522d08.1074e0a2001768f0> article\r\n',
      'Subject: 3ca86b8695a06cc7-4dc61d23a4d0f2ac-183926bb9a269b5f-12d6e977dae61b4a\r\n',
      'From: Test User <test-user@nospam.example>\r\n',
      'Date: Fri, 30 Jul 2021 20:41:08 CEST\r\n',
      'Newsgroups: alt.test\r\n',
      'Message-Id: <3d07898e391c018c.466453ad2196c56c@2b4feea2bb522d08.1074e0a2001768f0>\r\n',
      'Organization: XSNews\r\n',
      'Path: aioe.org!adore2!usenet.pasdenom.info!usenet.goja.nl.eu.org!weretis.net!feeder8.news.weretis.net!news.mixmin.net!feed.abavia.com!abe002.abavia.com!abp002.abavia.com!news.xsnews.nl!not-for-mail\r\n',
      'Lines: 3\r\n',
      'Injection-Date: Fri, 30 Jul 2021 20:41:08 +0200\r\n',
      'Injection-Info: news.xsnews.nl; mail-complaints-to="abuse@xsnews.nl"\r\n',
      'Xref: aioe.org alt.test:488627\r\n',
      '\r\n',
      'body1\r\n',
      'body2\r\n',
      'body3\r\n',
      '.\r\n',
      ];

      final stream = Stream.fromIterable(responseLines).transform(LineSplitter());
      final response = await server.handleMultiLineResponse(stream, null, hasHeaders:true, mappedHeader: true);

      expect(response.statusCode, '220');
      expect(response.isOK, true);

      // Check some fields

      expect(response.header['Subject'], '3ca86b8695a06cc7-4dc61d23a4d0f2ac-183926bb9a269b5f-12d6e977dae61b4a');
      expect(response.header['Xref'], 'aioe.org alt.test:488627');
      expect(response.header['Lines'], '3');
      expect(response.header['foo'], null);

      expect(response.body[0], 'body1');
      expect(response.body[1], 'body2');
      expect(response.body[2], 'body3');
    });
  });

  group('Error handling', () {
    //!!!! Autoconnect renders these tests invalid
    // test('SingleLine request without connection should throw', () {
    //   expect(() => server.executeSingleLineRequest('foo'), throwsA(isA<ConnectionClosedException>()));
    // });
    //
    // test('MultiLine request without connection should throw', () {
    //   expect(() => server.executeMultilineRequest('foo'), throwsA(isA<ConnectionClosedException>()));
    // });
    //!!!!

    test('Connect to non-existent host should throw', () {
      final badserver = NntpServer('bogus', '');
      expect(badserver.connect, throwsA(isA<FailedToOpenConnectionException>()));
    });

  });

  group("Capabilities", () {
    late Capabilities c;

    setUp(() {
      c = Capabilities();
    });

    test('Empty has nothing', () {
      expect(c.capabilities.isEmpty, true);
      expect(c.has('foo'), false);
      expect(c.has('foo', 'bar'), false);
    });
    
    test('Single no options', () {
      expect(c.capabilities.isEmpty, true);
      c.add('first');

      expect(c.has('first'), true);
      expect(c.has('foo'), false);
    });

    test('Two no options', () {
      c.add('first');
      c.add('second');
      expect(c.has('second'), true);
      expect(c.has('first'), true);
    });

    test('Three no options', () {
      c.add('third ');
      c.add('first');
      c.add('second ');

      expect(c.has('first'), true);
      expect(c.has('second'), true);
      expect(c.has('third'), true);

      expect(c.has('foo'), false);
      expect(c.has('first', 'opt1'), false);
    });

    test('Single one option', () {
      c.add('first opt1');
      expect(c.has('first'), true);
      expect(c.has('first', 'opt1'), true);
    });

    test('Three some options', () {
      c.add('FIRST');
      c.add('second opt21');
      c.add('third opt31 OPT32 opt33');

      expect(c.has('first'), true);
      expect(c.has('SECOND'), true);
      expect(c.has('second', 'opt21'), true);
      expect(c.has('third'), true);
      expect(c.has('third', 'OPT31'), true);
      expect(c.has('third', 'opt32'), true);
      expect(c.has('third', 'opt33'), true);

      expect(c.has('first', 'opt21'), false);
      expect(c.has('second', 'opt31'), false);
      expect(c.has('third', 'opt21'), false);
    });

  });

  group("Integration tests using nntp.aioe.org or such", () {

    test('Connect to server without credentials', () async {
      expect(server, isNotNull);
      expect(server.isClosed, true, reason: "Server starts closed");
      expect(server.isOpen, false, reason: "Server starts no open");

      final response = await server.connect();
      expect(server.isClosed, false, reason: "Server not closed after connect");
      expect(server.isOpen, true, reason: "Server open after connect");
      expect(response.statusCode, '200');
      expect(response.isOK, true, reason: "Connect worked");

      await expectLater(
          server.close(), completes, reason: "Close should complete");
      expect(server.isClosed, true, reason: "Server closed after close");
    });

    test('Connect to server with credentials', () async {
      server.authInfo = AuthInfo(userName, passWord);
      expect(server, isNotNull);
      expect(server.isClosed, true, reason: "Server starts closed");
      expect(server.isOpen, false, reason: "Server starts no open");

      final response = await server.connect();
      expect(server.isClosed, false, reason: "Server not closed after connect");
      expect(server.isOpen, true, reason: "Server open after connect");
      expect(response.statusCode, '200');
      expect(response.isOK, true, reason: "Connect worked");

      await expectLater(
          server.close(), completes, reason: "Close should complete");
      expect(server.isClosed, true, reason: "Server closed after close");
    });

    test('Close connection on server close (quit->done)', () async {
      expect(server, isNotNull);
      expect(server.isClosed, true, reason: "Server starts closed");
      expect(server.isOpen, false, reason: "Server starts no open");

      final response = await server.connect();
      expect(server.isClosed, false, reason: "Server not closed after connect");
      expect(server.isOpen, true, reason: "Server open after connect");
      expect(response.statusCode, '200');
      expect(response.isOK, true, reason: "Connect worked");

      final quitResponse = await server.executeSingleLineRequest("quit");
      expect(quitResponse.isOK, true);
      expect(quitResponse.statusCode, '205');
    });

    test('Get capabilities', () async {
      server.authInfo = AuthInfo(userName, passWord);
      final connectResponse = await server.connect();
      expect(connectResponse.isOK, true);

      final response = await server.executeMultilineRequest("capabilities");
      expect(response.isOK, true);
      expect(response.statusCode, '101');

      final quitResponse = await server.executeSingleLineRequest("quit");
      expect(quitResponse.isOK, true);
      expect(quitResponse.statusCode,'205');
    });
  });

  // test('See what happens on connection close', () async {
  //   server = NntpServer("faux_server", "localhost", 65432);
  //   final response = await server.connect();
  //   expect(response.isOK, true);
  //   //!!!! Wait while we see what happens when a disconnect arrives
  //   print("!!!! Waiting...");
  //   await Future.delayed(Duration(minutes: 1));
  //   print("...done!!!!");
  // });
}