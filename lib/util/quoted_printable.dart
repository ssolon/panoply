import 'dart:collection';
import 'dart:convert';
import 'package:fpdart/fpdart.dart';

/// quoted printable content type handling as an iterable of String.
class QuotedPrintable with IterableMixin<String> {
  final Iterable<String> _iterable;

  /// Create from another iterable.
  QuotedPrintable(this._iterable);

  @override
  Iterator<String> get iterator =>
      QuotedPrintableIterator.from(_iterable.iterator);
}

String fromHexChars(String hexChars) {
  return String.fromCharCode(int.parse(hexChars, radix: 16));
}

String convertLeadingHexChars(String s) {
  return s.length >= 2 ? fromHexChars(s.substring(0, 2)) + s.substring(2) : '';
}

class QuotedPrintableIterator implements Iterator<String> {
  final Iterator<String> _iterator;
  final decoder = Utf8Decoder(allowMalformed: true);

  QuotedPrintableIterator.from(this._iterator);

  @override
  String get current => _decode(_iterator.current);

  @override
  bool moveNext() => _iterator.moveNext();

  String _decode(String line) {
    String source = line;

    // Special case soft linebreak

    while (source.endsWith('=')) {
      // append next line, if any
      if (moveNext()) {
        source = source.substring(0, source.length - 1) + _iterator.current;
      } else {
        break;
      }
    }

    // All soft breaks have been handled above so now we're only left
    // actual character definitions (=xx).

    return source.contains('=') ? _decodeChars(source) : source;
  }

  /// Decode quoted printable characters from [source] which has soft line
  /// breaks already removed. We assume that the result is utf-8 and
  /// decode it.
  String _decodeChars(String source) {
    final result = source.split('=').splitAt(1).apply((first, second) =>
        first.join() + second.map(convertLeadingHexChars).join());

    return decoder.convert(result.codeUnits);
  }
}
