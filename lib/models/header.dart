import 'dart:collection';

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

/// Header information about an article.
///
/// This may also be from an overview and represents the fields from an overview
/// that MUST be present (per rfc3977) plus our own field(s).
abstract class Header {

  /// Have we read this article
  bool get isRead;
  set isRead(bool read);

  /// Article number in group
  int get number;

  /// Subject of article
  String get subject;

  /// Who posted the message
  String get from;

  /// Date of posting
  String get date;

  /// Unique message id
  String get msgId;

  /// Message id(s) of articles this post references.
  String get references;

  /// Length of article in bytes.
  int get bytes;

  /// Length of article in lines
  int get lines;

  /// Return an arbitrary header field by name.
  String getString(String name);

  /// Threaded children
  List<Header> get children;

  Map<String, dynamic> toJson();

  // Header.fromJson(String json);
}

/// Article Header from server which pulls fields from the list of text lines
/// passed back from the HEAD request.

class ArticleHeader extends Header {
  /// Number in the group -- if any -- else 0
  @override
  final int number;

  /// Has been read?
  @override
  bool isRead;

  @override
  List<Header> children=[];

  /// Full lines of header (with name prefix).
  final List<String> full;

  // Getters on full lines

  @override
  String get subject => getString('subject');

  @override
  String get from => getString('from');

  @override
  String get date => getString('date');

  @override
  String get msgId => getString('message-id');

  @override
  String get references => getString('references');

  @override
  int get bytes => getInt('bytes');

  @override
  int get lines => getInt('lines');

  ArticleHeader(this.number, this.full, [this.isRead = false]);

  /// Get header value for [name] or '' if not present.
  @override
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

  ArticleHeader.fromJson(Map<String, dynamic> json)
      : number = json['number'],
        isRead = json['isRead'],
        full = List<String>.from(json['full']);

  Map<String, dynamic> toJson() => {
    'number': number,
    'isRead': isRead,
    'full': full
  };

  @override
  String toString() {
    return 'Header{number: $number, isRead: $isRead, full: $full}';
  }
}

/// An article which has both the headers and the body.
class Article {
  final ArticleHeader headers;
  final List<String> body;

  Article(this.headers, this.body);
}

/// Headers for a group
class HeadersForGroup {
  String groupName;
  int firstArticleNumber = -1;
  int lastArticleNumber = -1;
  Map<String, Header> headers = {};

  HeadersForGroup(this.groupName, this.headers);

  HeadersForGroup.empty(this.groupName);
}

class HeaderListEntry extends LinkedListEntry<HeaderListEntry> {
  final Header header;

  HeaderListEntry(this.header);
}