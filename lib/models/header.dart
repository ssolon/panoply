import 'package:flutter/foundation.dart';

/// Header fetch request criteria

/// Type of fetch
enum FetchOp { lastNDays, newHeaders, allHeaders, lastNHeaders}

@immutable
class FetchCriteria {
  /// Type of fetch
  final FetchOp op;
  /// Value for value needing op. Meaning varies by op.
  final int? n;

  FetchCriteria(this.op, this.n);

  /// Create an iterable appropriate for this criteria
  Iterable<T> iterableFor<T>(List<T> list) {
    switch (op) {
      case FetchOp.newHeaders: // Should have been handled by articleRange
      case FetchOp.allHeaders:
        return list; // Just process everything

      case FetchOp.lastNHeaders:
        return list.skip(list.length - (n ?? 0));

      case FetchOp.lastNDays:
        return list.reversed; // Will have to fetch header to check date
    }
  }

  /// Return a string for a server request range from our criteria.
  String get articleRange {
    if (op == FetchOp.newHeaders) {
      if (n != null) {
        return "$n-";
      }
      else {
        throw Exception("FetchCriteria: null 'n' for newHeaders criteria");
      }
    }

    return '';
  }

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
  final int number;
  /// Has been read?
  bool isRead;
  /// Full lines of header (with name prefix).
  final List<String> full;

  // Getters on full lines

  String get subject => getString('subject');
  String get from => getString('from');
  String get date => getString('date');
  String get msgId => getString('message-id');
  String get references => getString('references');
  int get bytes => getInt('bytes');
  int get lines => getInt('lines');
  String get xref => getString('xref');

  Header(this.number, this.full, [this.isRead  = false]);

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

  @override
  String toString() {
    return 'Header{number: $number, isRead: $isRead, full: $full}';
  }
}

class ThreadedHeader extends Header {
  List<ThreadedHeader> refs;

  ThreadedHeader(int number, List<String> full, this.refs):super(number, full);

  ThreadedHeader.from(Header h, [this.refs=const []]): super(h.number, h.full, h.isRead) {
  }

  @override
  String toString() {
    return 'ThreadedHeader{Subject: $subject refs: $refs}';
  }
}
