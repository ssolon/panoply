// A server that can speak the NNTP protocol.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:loggy/loggy.dart';

enum ConnectionState { closed, open, loggedIn, error }

class Response {
  final int statusCode;
  final String body;

  bool get isOk => statusCode == 200; // TODO Handle other status codes?

  Response(this.statusCode, this.body);
}

/// A news server that handles the connection (and other stuff).
class NntpServer with UiLoggy{
  String name;
  String hostName;
  int    portNumber;
  String? username;
  String? password;

  var connectTimeout = Duration(seconds: 5000);

  var _connectionState = ConnectionState.closed;
  bool get isClosed => _connectionState == ConnectionState.closed;
  bool get isOpen => _connectionState == ConnectionState.open;
  bool get isLoggedIn => _connectionState == ConnectionState.loggedIn;

  String connectionError = "";
  Socket? _socket;
  // StreamSubscription? _stream;
  Stream<String>? _stream;

  NntpServer(this.name, this.hostName, [this.portNumber = 119, username, password]);

  void handleError(String errorMessage) {
    //TODO There should be a listener to receive these and display appropriately
    connectionError = "connection=$name $errorMessage";
    _connectionState = ConnectionState.error;
    loggy.error("ERROR: $connectionError");
  }

  bool get isConnectionOpen => _connectionState == ConnectionState.open;

  bool get authNeeded {
    return username != null;
  }

  /// Authenticate using username/password on open socket.
  bool authenticate() {
    if (!isOpen) {
      handleError("Can't authenticate in connectState=$_connectionState");
      return false;
    }
    else {
      //TODO Authenticate
      return false;
    }
  }

  Future<Response> connect() async {
    loggy.debug("Start connect to server hostName=$hostName");

    switch (_connectionState) {
      case ConnectionState.error:
        handleError("Can't open connection which had an error");
        break;

      case ConnectionState.closed:
        // Create a new socket and connect
      try {
        loggy.debug("About to connect to hostName=$hostName on portNumber=$portNumber");

        _socket = await Socket.connect(hostName, portNumber, timeout: connectTimeout);
        _connectionState = ConnectionState.open;
        loggy.debug("Socket opened");

        _stream = _socket?.encoding.decoder.bind(_socket!).transform(LineSplitter());
      }
      catch (e) {
        handleError("Failed to connect to hostName=$hostName portNumber=$portNumber: $e");
      }

    }
    loggy.debug("ConnectToServer for name=$name done.");
    return makeSingleLineResponse(_stream!);
  }

  Future<Response> makeSingleLineResponse (Stream<String> stream) async {
    final val = (await stream.first);
    //TODO Error handling here?
    final status = int.parse(val.substring(0,3)); // First 3 chars always status code
    final body = val.substring(3);
    return Response(status, body);
  }

  Future<void> close() async {
    if (isClosed) {
      handleError("Attempt to close a closed nntp connection");
    }
    else {
      // await _stream?.cancel();
      _stream = null;
      await _socket?.close();
      _connectionState = ConnectionState.closed;
    }
  }
}
