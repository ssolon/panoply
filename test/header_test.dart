
import 'dart:convert';

import 'package:panoply/models/header.dart';
import 'package:test/test.dart';

void main() {

  group('Getters', () {

    test('With values', () {
      final h = ArticleHeader(1234, testHeader1);
      expect(h.number, 1234, reason: 'number');
      expect(h.subject, 'Re: OT? - Sigh', reason: 'subject');
      expect(h.from, 'Technobarbarian <test1@gmail.com>',
          reason: 'from');
      expect(h.date, 'Mon, 9 Aug 2021 23:31:33 -0000 (UTC)', reason: 'date');
      expect(h.msgId, r'<sesdsl$7pf$1@dont-email.me>', reason: 'msgId');
      expect(h.references,
          r'<sep82b$vc1$1@dont-email.me> <sepbfq$bvg$1@dont-email.me>',
          reason: 'references');
      expect(h.bytes, 1024, reason: 'bytes');
      expect(h.lines, 124, reason: 'lines');
    });

    test('Without values', () {
      final h = ArticleHeader(1234, <String>[]);
      expect(h.number, 1234, reason: 'number');
      expect(h.subject, '', reason: 'subject');
      expect(h.from, '', reason: 'from');
      expect(h.date, '', reason: 'date');
      expect(h.msgId, '', reason: 'msgId');
      expect(h.references, '', reason: 'references');
      expect(h.bytes, 0, reason: 'bytes');
      expect(h.lines, 0, reason: 'lines');
    });

    test('Empty value(s)', () {
      final h = ArticleHeader(4321,[
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
    test('round trip json list', () {
      final lines=[
        'From: Technobarbarian <test1@gmail.com>',
        'Newsgroups: rec.outdoors.rv-travel',
        'Subject: Re: OT? - Sigh',
      ];

      final h = ArticleHeader(1, lines);
      final j = jsonEncode(h.toJson());
      final newh = ArticleHeader.fromJson(jsonDecode(j));

      expect(h.number, newh.number, reason: 'Number');
      expect(h.subject, newh.subject, reason: 'Subject');
      expect(h.getString('Newsgroups'), h.getString('Newsgroups'),
          reason: 'Newsgroups');
    });

    test('HeadersForGroup - ArticleHeader', () {
      List<String> headerLinesTemplate (i) => [
        'From: Test$i <test$i@gmail.com>',
        'Newsgroups: rec.outdoors.rv-travel',
        'Subject: Re: OT? - Sigh',
        'Message-ID: <message-id-$i>',
      ];

      final h1lines = [
        'From: Test1 <test1@gmail.com>',
        'Newsgroups: rec.outdoors.rv-travel',
        'Subject: Re: OT? - Sigh',
        'Message-ID: <message-id-1>',
      ];

      final h2lines = [
        'From: Test2 <test1@gmail.com>',
        'Newsgroups: rec.outdoors.rv-travel',
        'Subject: Re: OT? - Sigh',
        'Message-ID: <message-id-2>',
      ];

      final h3lines = [
        'From: Test1 <test1@gmail.com>',
        'Newsgroups: rec.outdoors.rv-travel',
        'Subject: Re: OT? - Sigh',
        'Message-ID: <message-id-3>',
      ];

      final headers = Map<String, ArticleHeader>();
      headers['<message-id-1>'] = ArticleHeader(1, headerLinesTemplate(1));
      headers['<message-id-2>'] = ArticleHeader(2, headerLinesTemplate(2));
      headers['<message-id-3>'] = ArticleHeader(3, headerLinesTemplate(3));

      final headersForGroup = HeadersForGroup('test', headers);

      final j = jsonEncode(headersForGroup.toJson());
      final newDecoded = jsonDecode(j);
      final newH = HeadersForGroup.fromJson('test1', newDecoded);

      expect(newH.groupName, 'test1', reason: 'groupName');
      expect(newH.lastArticleNumber, 3, reason: 'lastArticleNumber');
      expect(newH.firstArticleNumber, 1, reason: 'firstArticleNumber');

      expect(newH.headers.length, 3, reason: 'headers.length');

      for (var j = 0; j < 3; j++) {
        final lines = headerLinesTemplate(j+1);
        final key = "<message-id-${j+1}>";
        expect("${newH.headers[key].runtimeType}", 'ArticleHeader', reason: 'headers[$j] runtimeType');
        expect(newH.headers[key]?.number, j+1, reason: 'article number[$j]');
        expect(newH.headers[key]?.from, lines[0].substring(6), reason: 'from[$j]');
        expect(newH.headers[key]?.getString('Newsgroups'), lines[1].substring(12), reason: "newsgroups[$j]");
        expect(newH.headers[key]?.subject, h1lines[2].substring(9), reason: 'header #$j subject');
      }
    });
  });
}

final testHeader1 = r'''Path: aioe.org!eternal-september.org!reader02.eternal-september.org!.POSTED!not-for-mail
    From: Technobarbarian <test1@gmail.com>
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
