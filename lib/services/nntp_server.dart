// A server that can speak the NNTP protocol.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:loggy/loggy.dart';

enum ConnectionState { closed, open, loggedIn, error }

// Status codes we may need

const invalidHeaderFormat = '500';  // No status code. Should be command specific?

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

  //TODO Error handling
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

  /// Open a connection the the server at [name]/[portNumber] and return the
  /// response.
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


  /// Fix string [l] by unstuffing any leading dot.
  String fixLine(String l) {
    return (l.startsWith("..") ? l.substring(1) : l);
  }

  String trunc(String s, [int maxLength=100]) {
    return s.length > maxLength ? s.substring(0, maxLength) + "..." : s;
  }

  /// Make a status value from the first line of [headers] and remove status value.
  String _makeStatus(List<String> headers) {
    final String status;  // Always 3 numrtic characters
    if (headers.length > 0) {
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
    // loggy.debug("Created Response statusCode='$status' header='${trunc(responseHeader)}' body='${trunc(body)}'");

    // First line is always status -- if there

    final String statusLine;
    final List<String> headers;
    if (headerLines.length > 0) {
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
