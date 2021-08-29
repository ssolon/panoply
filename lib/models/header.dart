import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

/// Header fetch request criteria

/// Type of fetch
enum FetchOp { lastNDays, newHeaders, allHeaders, lastNHeaders}

@immutable
class FetchCriteria {
  /// Type of fetch
  final FetchOp op;
  /// Number of days for days op
  final int? numberOfDays;
  /// Number of headers for headers op
  final int? numberOfHeaders;

  FetchCriteria(this.op, {int? this.numberOfDays, int? this.numberOfHeaders});

  /// Create an iterable appropriate for this criteria
  Iterable<T> iterableFor<T>(List<T> list) {
    switch (op) {
      case FetchOp.newHeaders: // Should have been handled by articleRange
      case FetchOp.allHeaders:
        return list; // Just process everything

      case FetchOp.lastNHeaders:
        return list.skip(list.length - (numberOfHeaders ?? 0));

      case FetchOp.lastNDays:
        return list.reversed; // Will have to fetch header to check date
    }
  }

  /// Return a string for a server request range from our criteria.
  String get articleRange {
    if (op == FetchOp.newHeaders) {
      if (numberOfHeaders != null) {
        return "$numberOfHeaders-";
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
      case FetchOp.lastNDays: c = "last $numberOfDays days"; break;
      case FetchOp.newHeaders: c = 'new'; break;
      case FetchOp.allHeaders: c = 'all'; break;
      case FetchOp.lastNHeaders: c = 'latest $numberOfHeaders headers'; break;
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

  /// This header is the child of another header
  bool get isChild;
  set isChild(bool value);

  /// Threaded children
  LinkedHashSet<Header> get children;

  /// Return all the headers as just a list of strings
  List<String> get raw;

  Map<String, dynamic> toJson();

  Header();

  factory Header.fromJson(Map<String, dynamic> json) {
    final headerType = json.keys.first;
    if (headerType == ArticleHeader.persistTypeName) {
      return ArticleHeader.fromJson(json);
    }

    throw Exception("Unknown article header type=$headerType");

  }
}

/// Article Header from server which pulls fields from the list of text lines
/// passed back from the HEAD request.

class ArticleHeader extends Header {
  static const persistTypeName = 'a';

  /// Number in the group -- if any -- else 0
  @override
  final int number;

  /// Has been read?
  @override
  bool isRead;

  @override
  bool isChild;

  @override
  LinkedHashSet<Header> children=LinkedHashSet<Header>();

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

  ArticleHeader(this.number, this.full,
      [this.isRead = false, this.isChild=false]);

  /// Get header value for [name] or '' if not present.
  @override
  String getString(String name) {
    final checkName = name.toLowerCase() + ':';
    final checkLength = checkName.length;

    bool skip(String e) =>
        e.length >= checkLength
            ? e.substring(0, checkLength).toLowerCase() != checkName
            : true;

    bool cont(String e) => e.startsWith(' ');

    final l = full
        .span(skip)
        .second.takeWhile((e) => !skip(e) || cont(e))
        .join();
    return (l.isNotEmpty) ? l.substring(checkName.length).trim() : '';
  }

  int getInt(String name) {
    final s = getString(name);
    return s.isEmpty ? 0 : int.parse(s);
  }

  factory ArticleHeader.fromJson(Map<String, dynamic> json) {
    final h = json[persistTypeName];
    if (h == null) {
      throw Exception("ArticleHeader.fromJson couldn't find entry for $persistTypeName");
    }
    return ArticleHeader(
        h['number'],
        List<String>.from(h['full']),
        h['isRead'] as bool
    );

  }

  List<String> get raw {
    return full;
  }

  Map<String, dynamic> toJson() => {
    persistTypeName: {
      'number': number,
      'isRead': isRead,
      'full': full
    }
  };

  @override
  String toString() {
    return '${persistTypeName}{number: $number, isRead: $isRead,'
        'isChild: $isChild, msgId: $msgId, full: $full}';
  }
}

/// An article which has both the headers and the body.
class Article {
  final Header headers;
  final List<String> body;

  Article(this.headers, this.body);
}

/// Headers for a group
class HeadersForGroup {
  static const persistTypeName = 'HeadersForGroup';

  String groupName;
  int firstArticleNumber = -1;
  int lastArticleNumber = -1;
  Map<String, Header> headers = {};

  HeadersForGroup(this.groupName, this.headers);

  HeadersForGroup.empty(this.groupName);

  /// Merge headers from [newHeaders] updating meta data
  /// in [destination] and returning this.
  HeadersForGroup mergeHeaders(
      Iterable<Header> newHeaders) {

    for (final h in newHeaders) {
      firstArticleNumber = firstArticleNumber == -1
          ? h.number : min(firstArticleNumber, h.number);
      lastArticleNumber = lastArticleNumber  == -1
          ? h.number : max(lastArticleNumber, h.number);

      headers.putIfAbsent(h.msgId, () => h);
    }

    return this;
  }

  Map<String, dynamic> toJson()  {
    final result = Map<String, dynamic>();
    result[persistTypeName] =
        headers.values.map((h) => h.toJson()).toList();
    return result;
  }

  /// Instantiate from a json dump recreating the meta data which isn't
  /// persisted.
  factory HeadersForGroup.fromJson(String groupName, dynamic json) {

    // Special case empty state
    if ((json as Map).isEmpty) {
      return HeadersForGroup.empty(groupName);
    }

    final headers = json[persistTypeName];
    if (headers == null) {
      throw Exception("HeadersForGroup.fromJson Failed to find $persistTypeName");
    }

    // Merge into an empty object which will build the metadata.

    return HeadersForGroup.empty(groupName)
        .mergeHeaders(headers.map<Header>((h) => Header.fromJson(h))
    );

  }

  /// Reset the threading
  HeadersForGroup resetThreading() {
    for (final h in headers.values) {
      h.children.clear();
      h.isChild = false;
    }

    return this;
  }

  /// Thread the contents
  HeadersForGroup thread() {
    for (final h in headers.values) {
      final refs = h.references.split(' ');
      for (final r in refs.reversed) {
        if (headers.containsKey(r)) {
          headers[r]!.children.add(h);
          h.isChild = true;
          break;
        }
      }
    }

    return this;
  }
}

class HeaderListEntry extends LinkedListEntry<HeaderListEntry> {
  final Header header;
  bool showChildren;

  HeaderListEntry(this.header, [this.showChildren = false]);
}