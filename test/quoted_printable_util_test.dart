import 'package:panoply/util/quoted_printable.dart';
import 'package:test/test.dart';

void main() {

  group('fromHexChars', () {

    test('space', () {
      expect(fromHexChars('20'), ' ', reason: 'space');
    });

    test('underscore', () {
      expect(fromHexChars('5f'), '_', reason: 'lower case f');
      expect(fromHexChars('5F'), '_', reason: 'upper case F');
    });
  });

  group('convertLeadingHexChars', () {
    test('empty', () {
      expect(convertLeadingHexChars(''), '', reason:'empty string');
    });

    test('space', () {
      expect(convertLeadingHexChars('20stuff'), ' stuff', reason: 'space');
    });

    test('underscore', () {
      expect(convertLeadingHexChars('5fstuff'), '_stuff', reason: 'lower case f');
      expect(convertLeadingHexChars('5Fstuff'), '_stuff', reason: 'upper case F');
    });
  });

  group('quotedPrintable', () {

    test('empty', () {
      final lines = <String>[];
      final qp = QuotedPrintable(lines);
      expect(qp.toList(), isEmpty, reason:'empty source');
    });

    test('empty string', () {
      final lines = [''];
      final qp = QuotedPrintable(lines);
      expect(qp, containsAllInOrder(['']), reason:'empty string');
    });

    test('empty strings', () {
      final lines = ['', '', ''];
      final qp = QuotedPrintable(lines);
      expect(qp, containsAllInOrder(['', '', '']), reason:'empty strings');
    });

    test('blank strings', () {
      final lines = [' ', '   ', ''];
      final qp = QuotedPrintable(lines);
      expect(qp, containsAllInOrder([' ', '   ', '']), reason:'blank strings');
    });

    test('plain string', () {
      final lines = ['Line 1'];
      final qp = QuotedPrintable(lines);
      expect(qp, containsAllInOrder(['Line 1']), reason:'plain string');
    });

    test('plain strings', () {
      final lines = ['Line 1', '   ', 'Line3'];
      final qp = QuotedPrintable(lines);
      expect(qp, containsAllInOrder(['Line 1', '   ', 'Line3']), reason:'plain strings');
    });

    test('encoded chars', () {
      final lines = ['Line=201', '=20=20=20', 'Line3=5f=3d'];
      final qp = QuotedPrintable(lines);
      expect(qp, containsAllInOrder(['Line 1', '   ', 'Line3_=']), reason:'encoded strings');
    });

    test('soft break chars', () {
      final lines = ['Line0', 'Line=201=', '=20=20=20=', 'Line3=5f=3d', 'Line4'];
      final qp = QuotedPrintable(lines);
      expect(qp, containsAllInOrder(['Line0', 'Line 1   Line3_=', 'Line4']), reason:'soft break');
    });
  });
}