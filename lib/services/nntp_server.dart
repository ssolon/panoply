// A server that can speak the NNTP protocol.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:loggy/loggy.dart';

enum ConnectionState { closed, open, loggedIn, error }

// Status codes we may need

const invalidHeaderFormat = 500;  // No status code. Should be command specific?

class Response {
  final int statusCode;
  final List<String> header;
  final List<String> body;

  bool get isOK => statusCode < 400;

  Response(this.statusCode, this.header, this.body);
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

        // _stream = _socket?.transform(_socket?.encoding.decoder)//.transform(LineSplitter());
        _stream = _socket?.encoding.decoder.bind(_socket!).transform(LineSplitter());
        // var resp = await _stream?.first;
        // loggy.debug("Connect response=$resp");
/*!!!!
        _stream = _socket?.listen((event) {
          loggy.debug("Received event=${_socket?.encoding.decoder.convert(event)} '$event' from name=$name");
        },
          onDone: () => loggy.debug("OnDone for name=$name"),
          onError: (error) => loggy.error("onError for name=$name"),
        );
        loggy.debug("Listen setup for name=$name");
!!!!*/
/*!!!!
        if (authNeeded) {
          return authenticate();
        }
!!!!*/
      }
      catch (e) {
        handleError("Failed to connect to hostName=$hostName portNumber=$portNumber: $e");
      }

    }
    loggy.debug("ConnectToServer for name=$name done.");
    return handleSingleLineResponse(_stream!);
  }

  // Future<Response> runCapabilities() {
  //   _socket.add("capabilities");
  //   return handleMultiLineResponse();
  // }


  /// fixLine by unstuffing any leading dot and adding back endline which
  /// we canonicalize to just newline.
  String fixLine(String l) {
    return (l.startsWith("..") ? l.substring(1) : l) + '\n';
  }

  String trunc(String s, [int maxLength=100]) {
    return s.length > maxLength ? s.substring(0, maxLength) + "..." : s;
  }

  /// Make a status value from the first line of [header] and remove status value.
  int _makeStatus(List<String> header) {
    final int status;
    if (header.length > 0) {
      status = header[0].length > 2 ? int.parse(header[0].substring(0,3)) : invalidHeaderFormat;
      header[0] = header[0].length > 3 ? header[0].substring(4) : "";
    }
    else {
      status = invalidHeaderFormat;
    }

    return status;
  }

  Response makeResponse(List<String> header, List<String> body) {
    final status = _makeStatus(header);
    // loggy.debug("Created Response statusCode='$status' header='${trunc(responseHeader)}' body='${trunc(body)}'");
    return Response(status, header, body);
  }

  Future<Response> handleSingleLineResponse (Stream<String> stream) async {
    return makeResponse([await stream.first], [""]);
    //TODO Error handling here?
  }

  Future<Response> handleMultiLineResponse(Stream<String> stream) async {
    List<String> header = [];
    List<String> body = [];
    var inHeader = true;

    await stream.takeWhile((l) => l.trimRight() != ".").forEach((element) {
      final line = fixLine(element.trimRight());

      if (inHeader) {
        if (inHeader && line == "") {
          inHeader = false;
        }
        else {
          header.add(line);
        }
      }
      else {
        body.add(line);
      }
    });

    return makeResponse(header, body);
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
