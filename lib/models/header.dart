import 'package:flutter/foundation.dart';

/// Header fetch request criteria

enum FetchOp { lastNDays, newHeaders, allHeaders, lastNHeaders}

@immutable
class FetchCriteria {
  final FetchOp op;
  final int? n;

  FetchCriteria(this.op, this.n);

  @override
  String toString() {
    final String c;
    switch (op) {
      case FetchOp.lastNDays: c = "last $n days"; break;
      case FetchOp.newHeaders: c = 'new'; break;
      case FetchOp.allHeaders: c = 'all'; break;
      case FetchOp.lastNHeaders: c = 'latest $n headers'; break;
    }

    return c;
  }

}

/// Article Header

class Header {
  /// Number in the group -- if any -- else 0
  int number;
  /// Full lines of header (with name prefix).
  List<String> full;

  // Getters on full lines

  String get subject => getString('subject');
  String get from => getString('from');
  String get date => getString('date');
  String get msgId => getString('message-id');
  String get references => getString('references');
  int get bytes => getInt('bytes');
  int get lines => getInt('lines');
  String get xref => getString('xref');


  String getString(String name) {
    final checkName = name.toLowerCase() + ':';
    final chkLength = checkName.length;

    bool hit(String e) =>
        e.length >= chkLength
            ? e.substring(0, chkLength).toLowerCase() == checkName
            : false;

    final l = full.firstWhere(hit, orElse: () => '');
    return (l.isNotEmpty) ? l.substring(checkName.length).trim() : '';
  }

  int getInt(String name) {
    final s = getString(name);
    return s.isEmpty ? 0 : int.parse(s);
  }

  Header(this.number, this.full);


}

class ThreadedHeader extends Header {
  List<ThreadedHeader>? refs;

  ThreadedHeader(int number, List<String> full, this.refs):super(number, full);
}
