import 'package:loggy/loggy.dart';
import 'package:test/test.dart';

import 'package:panoply/services/nntp_server.dart';

void main() {
  Loggy.initLoggy();

  test('Connect to server without credentials', () async {
    var server = NntpServer("test_no_auth", "nntp.aioe.org");

    expect(server, isNotNull);
    expect(server.isClosed, true, reason: "Server starts closed");
    expect(server.isOpen, false, reason: "Server starts no open");

    final response = await server.connect();
    expect(server.isClosed, false, reason:"Server not closed after connect");
    expect(server.isOpen, true, reason: "Server open after connect");
    expect(response.statusCode, equals(200));
    expect(response.isOk, true, reason: "Connect worked");

    await expectLater(server.close(), completes, reason: "Close should complete");
    expect(server.isClosed, true, reason: "Server closed after close");

  });
}