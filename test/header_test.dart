
import 'dart:convert';

import 'package:panoply/models/header.dart';
import 'package:test/test.dart';

void main() {

  group('Getters', () {

    test('With values', () {
      final h = Header(1234, testHeader1);
      expect(h.number, 1234, reason: 'number');
      expect(h.subject, 'Re: OT? - Sigh', reason: 'subject');
      expect(h.from, 'Technobarbarian <Technobarbarian-ztopzpam@gmail.com>',
          reason: 'from');
      expect(h.date, 'Mon, 9 Aug 2021 23:31:33 -0000 (UTC)', reason: 'date');
      expect(h.msgId, r'<sesdsl$7pf$1@dont-email.me>', reason: 'msgId');
      expect(h.references,
          r'<sep82b$vc1$1@dont-email.me> <sepbfq$bvg$1@dont-email.me>',
          reason: 'references');
      expect(h.bytes, 1024, reason: 'bytes');
      expect(h.lines, 124, reason: 'lines');
      expect(h.xref, 'aioe.org rec.outdoors.rv-travel:349310', reason: 'xref');
    });

    test('Without values', () {
      final h = Header(1234, <String>[]);
      expect(h.number, 1234, reason: 'number');
      expect(h.subject, '', reason: 'subject');
      expect(h.from, '', reason: 'from');
      expect(h.date, '', reason: 'date');
      expect(h.msgId, '', reason: 'msgId');
      expect(h.references, '', reason: 'references');
      expect(h.bytes, 0, reason: 'bytes');
      expect(h.lines, 0, reason: 'lines');
      expect(h.xref, '', reason: 'xref');
    });

    test('Empty value(s)', () {
      final h = Header(4321,[
        'nospace:',
        'onespace: '
      ]);

      expect(h.getString('nospace'), '', reason:'nospace');
      expect(h.getString('onespace'), '', reason:'onespace');
      expect(h.getInt('nospace'), 0, reason:'int nospace');
      expect(h.getInt('onespec'), 0, reason:'int onespace');
    });

  });

  group("Criteria", () {
    test("allHeaders", () {
      final c = FetchCriteria(FetchOp.allHeaders, null);
      final l = [1,2,3,4,5];

      expect(c.articleRange, '', reason: 'articleRange');
      expect(c.iterableFor(l).toList(), l);
    });

    test("newHeaders", () {
      final c = FetchCriteria(FetchOp.newHeaders, 3);
      final l = [1,2,3,4,5];

      expect(c.articleRange, '3-', reason:'articleRange');
      expect(c.iterableFor(l).toList(), l, reason: 'iterable');
    });

    test("lastNHeaders", () {
      final c = FetchCriteria(FetchOp.lastNHeaders, 3);
      final l = [1,2,3,4,5];

      expect(c.articleRange, '', reason:'articleRange');
      expect(c.iterableFor(l).toList(), [3,4,5], reason: 'iterable');
    });

    test("lastNDays", () {
      final c = FetchCriteria(FetchOp.lastNDays, 3);
      final l = [1,2,3,4,5];

      expect(c.articleRange, '', reason:'articleRange');
      expect(c.iterableFor(l).toList(), [5,4,3,2,1], reason: 'iterable');
    });

  });

  group('Persistence', () {
    test('round trip json', () {
      final lines=[
        'From: Technobarbarian <Technobarbarian-ztopzpam@gmail.com>',
        'Newsgroups: rec.outdoors.rv-travel',
        'Subject: Re: OT? - Sigh',
      ];

      final h = Header(1, lines);
      final j = jsonEncode(h.toJson());
      final j2 = jsonEncode([1,2,3]);
      final newl = jsonDecode(j2);
      final newh = Header.fromJson(jsonDecode(j));

      expect(h.number, newh.number, reason: 'Number');
      expect(h.subject, newh.subject, reason: 'Subject');
      expect(h.getString('Newsgroups'), h.getString('Newsgroups'),
          reason: 'Newsgroups');
    });
  });
}

final testHeader1 = r'''Path: aioe.org!eternal-september.org!reader02.eternal-september.org!.POSTED!not-for-mail
    From: Technobarbarian <Technobarbarian-ztopzpam@gmail.com>
    Newsgroups: rec.outdoors.rv-travel
    Subject: Re: OT? - Sigh
    Date: Mon, 9 Aug 2021 23:31:33 -0000 (UTC)
    Organization: A noiseless patient Spider
    Lines: 124
    Bytes: 1024
    Message-ID: <sesdsl$7pf$1@dont-email.me>
    References: <sep82b$vc1$1@dont-email.me> <sepbfq$bvg$1@dont-email.me>
    Mime-Version: 1.0
    Content-Type: text/plain; charset=UTF-8
    Content-Transfer-Encoding: 8bit
    Injection-Date: Mon, 9 Aug 2021 23:31:33 -0000 (UTC)
    Injection-Info: reader02.eternal-september.org; posting-host="0abb8fd9cfcc434e8f20572285282683";
    logging-data="7983"; mail-complaints-to="abuse@eternal-september.org";	posting-account="U2FsdGVkX1/Ny5Tq5hfWkouJeaYewMYYYXhw5eYnkXc="
    User-Agent: Pan/0.146 (Hic habitat felicitas; d7a48b4
    gitlab.gnome.org/GNOME/pan.git)
    Cancel-Lock: sha1:8zGQxa8wcZEpamE27upal41qW4c=
    Xref: aioe.org rec.outdoors.rv-travel:349310'''.split('\n').map((e) =>
    e.trim()).toList();
