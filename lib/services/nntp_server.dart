// A server that can speak the NNTP protocol.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:loggy/loggy.dart';

enum ConnectionState { closed, open, loggedIn, error }

// Status codes we may need

const invalidHeaderFormat = '500';  // No status code. Should be command specific?

// Base exception for all our exceptions.
class NntpServerException implements Exception {
  final String message;

  NntpServerException(this.message);

  @override toString() {
    return "${this.runtimeType.toString()}:$message";
  }
}

/// Couldn't open the connection for some reason which hopefully is explained
/// in the [message].
class FailedToOpenConnectionException extends NntpServerException {
  FailedToOpenConnectionException(String message): super(message);
}

/// Attempt to perform an operation when the connection is not open.
class ConnectionClosedException extends NntpServerException {
  ConnectionClosedException(String message): super(message);
}

/// Connection is already open on [connect] request.
class ConnectionAlreadyOpenException extends NntpServerException {
  ConnectionAlreadyOpenException(String message): super(message);
}

/// Received an [error] from the connection/stream.
class UnexpectedError extends NntpServerException {
  UnexpectedError(String message): super(message);
}

/// General response from the server.
///
/// The returned [statusCode] is parsed out, leaving the rest of the first line
/// as [statusLine]. Additional header lines are in [headers] and those responses
/// that return a set of key/value pairs can be accessed as [header[key]].
///
/// Finally, the body is, unsurprisingly in [body].
///
/// All strings have terminating \r\n removed.
///

class Response {
  final String statusCode;
  final String statusLine;
  final List<String> headers;
  final Map<String, String> header;
  final List<String> body;


  /// Predicate that tests [statusCode].
  bool get isOK => int.parse(statusCode) < 400;

  /// CTOR
  Response(this.statusCode, this.statusLine, this.headers, this.body, this.header);

  /// Parse 'key: value' lines into the returned map.
  static Map<String, String> parseHeaderLinesToMap(List<String> headerLines) {
    final re = RegExp(r'(\w+):\s*(.*)');
    final Map<String, String> valuesMap = {};

    headerLines.forEach((element) {
      var match = re.firstMatch(element);
      if (match != null && match.groupCount > 1) {
        valuesMap[match.group(1)!] = match.group(2) ?? '';
      }
    });

    return valuesMap;
  }
}

/// A news server that handles the connection and basic communication.
///
/// This is a very simple layer that handles traffic back an forth but doesn't
/// do any sort of interpretation or understanding and only deals with connection
/// and communication format errors.
///
/// Errors are handled by throwing exceptions which can happen at any time since
/// the server may close the connection when it chooses (usually will timeout).
///
class NntpServer with UiLoggy{
  String name;
  String hostName;
  int    portNumber;

  var connectTimeout = Duration(seconds: 5000);

  var _connectionState = ConnectionState.closed;
  bool get isClosed => _connectionState == ConnectionState.closed;
  bool get isOpen => _connectionState == ConnectionState.open;

  String connectionError = "";
  Socket? __realSocket; // Use getter _socket
  Stream<String>? __realStream; // Use getter _stream

  String _exceptionMessage(detail) => "$detail: name=$name hostName=$hostName portNumber=$portNumber";

  /// Return socket for host access. Throws exception if connection closed.
  Socket get _socket {
    if (__realSocket != null) {
      return __realSocket!;
    }

    throw ConnectionClosedException(_exceptionMessage('Socket null'));
  }

  /// Return stream for host. Throws exception if stream inaccessible (connection closed?).
  Stream<String> get _stream {
    if (__realStream != null) {
      return __realStream!;
    }

    throw ConnectionClosedException(_exceptionMessage('Stream null'));
  }
  NntpServer(this.name, this.hostName, [this.portNumber = 119]);

  void _handleError(String what, String errorMessage) {
    throw UnexpectedError(_exceptionMessage("$what:$errorMessage"));
  }

  /// Do we think the connection is open (might not be now, or soon not to be)
  bool get isConnectionOpen => _connectionState == ConnectionState.open;

  /// Converts to server coding and adds CRLF.
  List<int> encodeForServer(String s) => _socket.encoding.encoder.convert(s + '\r\n');

  /// Open a connection the the server at [name]/[portNumber] and return the
  /// response.
  Future<Response> connect() async {
    loggy.debug("Start connect to server hostName=$hostName");

    switch (_connectionState) {
      case ConnectionState.open:
        throw ConnectionAlreadyOpenException(_exceptionMessage('Connection already open'));

      case ConnectionState.closed:

        // Create a new socket and connect

        loggy.debug("About to connect to hostName=$hostName on portNumber=$portNumber");

        try {
          __realSocket = await Socket.connect(hostName, portNumber, timeout: connectTimeout);
          if (__realSocket == null) {
            throw FailedToOpenConnectionException(_exceptionMessage('failed to connect - socket null!'));
          }}
        on SocketException catch (e) {
          throw FailedToOpenConnectionException(_exceptionMessage("Exception opening connection:$e"));
        }

        _connectionState = ConnectionState.open;
        loggy.debug("Socket opened");

        // Is this useful or are errors thrown?
        var _errorHandlerStream = _socket.handleError((error) {
          _handleError("Stream error", error);
        });

        __realStream = _socket.encoding.decoder
            .bind(_socket)
            .transform(const LineSplitter())
            .asBroadcastStream();

        _stream.listen((event) { },
            onError: (error) => _handleError('listen on stream error', error),
            onDone: () {
              loggy.debug("name=$name hostName=$hostName portNumber=$portNumber is done!");
              _connectionState = ConnectionState.closed;
              _socket.destroy();
            });
    }

    loggy.debug("ConnectToServer for name=$name done.");
    return handleSingleLineResponse(_stream);
  }

  /// Execute a multiline request.
  Future<Response> executeMultilineRequest(String request) async {
    _socket.add(encodeForServer(request));
    var responseStream = _stream;
    return handleMultiLineResponse(responseStream);
  }

  /// Execute a single line request.
  Future<Response> executeSingleLineRequest(String request) async {
    _socket.add(encodeForServer(request));
    return handleSingleLineResponse(_stream);
  }

  /// Fix string [l] by unstuffing any leading dot.
  String fixLine(String l) {
    return (l.startsWith("..") ? l.substring(1) : l);
  }

  String trunc(String s, [int maxLength=100]) {
    return s.length > maxLength ? s.substring(0, maxLength) + "..." : s;
  }

  /// Make a status value from the first line of [headers] and remove status value.
  String _makeStatus(List<String> headers) {
    final String status;  // Always 3 numeric characters
    if (headers.isNotEmpty) {
      status = headers[0].length > 2 ? headers[0].substring(0,3) : invalidHeaderFormat;
      headers[0] = headers[0].length > 3 ? headers[0].substring(4) : "";
    }
    else {
      status = invalidHeaderFormat;
    }

    return status;
  }

  /// Create a [Response] object from [headerLines], [body] parsing [headerLines]
  /// into a map when [mappedHeader] is true.
  Response makeResponse(List<String> headerLines, List<String> body, [mappedHeader=false]) {
    final statusCode = _makeStatus(headerLines);

    // First line is always status -- if there

    final String statusLine;
    final List<String> headers;
    if (headerLines.isNotEmpty) {
      statusLine = headerLines[0].trimRight();
      headers = headerLines.skip(1).toList(); // First line is always status
    }
    else {
      statusLine ='';  // So everybody else doesn't have to check
      headers = [];
    }

    // Parse any possible header map values

    final Map<String, String> headerMap = mappedHeader
        ? Response.parseHeaderLinesToMap(headers)
        : {};

    return Response(statusCode, statusLine, headers, body, headerMap);
  }

  /// Handle the response to a command which returns a single line, which
  /// will be parsed into [statusCode] and [statusLine].
  Future<Response> handleSingleLineResponse (Stream<String> stream) async {
    return makeResponse([await stream.first], []);
    //TODO Error handling here?
  }

  ///
  /// Handle the response to a command which returns multiple lines.
  ///
  /// The status line will be parsed into [statusCode] and [statusLine] and
  /// additional header lines will be available as [headers] with the body
  /// as [body].
  ///
  /// If the header contains 'key: value' specifications setting [mappedHeader]
  /// will parse them and make them available as [header(key)].
  ///
  Future<Response> handleMultiLineResponse(Stream<String> stream, [mappedHeader=false]) async {
    List<String> header = [];
    List<String> body = [];
    var inHeader = true;

    await stream.takeWhile((l) => l.trimRight() != ".").forEach((element) {
      final line = fixLine(element.trimRight());

      if (inHeader) {
        if (line == "") {
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

    return makeResponse(header, body, mappedHeader);
  }

  Future<void> close() async {
    if (!isClosed) {
      _connectionState = ConnectionState.closed;
      return _socket.destroy();
    }
  }
}
