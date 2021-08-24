
import 'dart:convert';

import 'package:panoply/models/header.dart';
import 'package:test/test.dart';

void main() {

  group('Getters', () {

    test('With values', () {
      final h = ArticleHeader(1234, testHeader2);
      expect(h.number, 1234, reason: 'number');
      expect(h.subject, 'Re: OT? - Sigh', reason: 'subject');
      expect(h.from, 'Test 2 <test2@gmail.com>',
          reason: 'from');
      expect(h.date, 'Mon, 9 Aug 2021 23:31:33 -0000 (UTC)', reason: 'date');
      expect(h.msgId, r'<sesdsl$7pf$1@dont-email.me>', reason: 'msgId');
      expect(h.references,
          r'<sep82b$vc1$1@dont-email.me> <sepbfq$bvg$1@dont-email.me>',
          reason: 'references');
      expect(h.bytes, 1024, reason: 'bytes');
      expect(h.lines, 124, reason: 'lines');
    });

    test('With multiline values', () {
      final h = ArticleHeader(1234, testHeader5);
      expect(h.number, 1234, reason: 'number');
      expect(h.subject, 'Re: OT? - Yep', reason: 'subject');
      expect(h.from, 'Test 5 <test5@gmail.com>',
          reason: 'from');
      expect(h.date, 'Sat, 21 Aug 2021 19:26:40 -0700', reason: 'date');
      expect(h.msgId, r'<9Jidnb74U6FBKLz8nZ2dnUU7-eudnZ2d@giganews.com>', reason: 'msgId');
      expect(h.references,
          r'<sfr771$1j4p$1@gioia.aioe.org> <0a63a809-75f8-4d24-9721-92541c0e51d9n@googlegroups.com>',
          reason: 'references');
      expect(h.bytes, 0, reason: 'bytes');
      expect(h.lines, 16, reason: 'lines');
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

    test('Bogus value(s)', () {
      final h = ArticleHeader(4321, testHeader5);

      expect(h.getString('foo'), '', reason:'bogus not there');
      expect(h.getInt('bar'), 0, reason:'bogus not there');
    });

    test('Many multi lines', () {
      final h = ArticleHeader(4321, testHeaderMultiContinueLines);

      final r = h.references.split(' ');
      expect(r.length, 10, reason:'references');
      expect(r[0], r'<s4sgij$hj0$1@dont-email.me>');
      expect(r[1], r'<s4sh0n$1loj$1@gioia.aioe.org>');
      expect(r[2], r'<s4sler$hj0$4@dont-email.me>');
      expect(r[3], r'<s4v3af$rv4$1@gioia.aioe.org>');
      expect(r[4], r'<sfujuh$l09$2@dont-email.me>');
      expect(r[5], r'<Kt6dnTvIGpy2lL78nZ2dnUU7-XednZ2d@giganews.com>');
      expect(r[6], r'<7VDUI.84259$Qp7.22991@fx46.iad>');
      expect(r[7], r'<sfvvlh$eec$2@gioia.aioe.org>');
      expect(r[8], r'<euWUI.50796$Oz2.12756@fx47.iad>');
      expect(r[9], r'<sg1hsn$t8n$2@gioia.aioe.org>');

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

  group('Threading', ()
  {
    test('One header', () {
      final h0 = ArticleHeader(1, testHeader0);
      final headers = HeadersForGroup.empty('testThreading1')
          .mergeHeaders([h0]);

      expect(headers.thread(), headers, reason: 'thread returns hfg');
      expect(headers.headers.length, 1, reason: 'only h0 loaded');

      expect(h0.isChild, false, reason: 'h1 is not child');
      expect(h0.children.length, 0, reason: 'no children');
    });

    test('two headers not threaded', () {
      final h0 = ArticleHeader(1, testHeader0);
      final h3 = ArticleHeader(3, testHeader3);
      final headers = HeadersForGroup.empty('testThreading1')
          .mergeHeaders([h0, h3]);

      expect(headers.thread(), headers, reason: 'thread returns hfg');
      expect(headers.headers.length, 2, reason: 'h0,h3 loaded');

      expect(h0.isChild, false, reason: 'h0 is not child');
      expect(h0.children.length, 0, reason: 'h0 no children');

      expect(h3.isChild, false, reason: 'h3 is not child');
      expect(h3.children.length, 0, reason: 'h3 no children');
    });

    test('three headers one threaded', () {
      final h0 = ArticleHeader(1, testHeader0);
      final h1 = ArticleHeader(2, testHeader1);
      final h3 = ArticleHeader(3, testHeader3);
      final headers = HeadersForGroup.empty('testThreading1')
          .mergeHeaders([h0, h1, h3]);

      expect(headers.thread(), headers, reason: 'thread returns hfg');
      expect(headers.headers.length, 3, reason: 'h0,h1,h3 loaded');

      expect(h0.isChild, false, reason: 'h0 is not child');
      expect(h0.children.length, 1, reason: 'h1 has 1 child');

      expect(h1.isChild, true, reason: 'h1 is child');
      expect(h1.children.length, 0, reason: 'h1 no children');

      expect(h3.isChild, false, reason: 'h3 is not child');
      expect(h3.children.length, 0, reason: 'h3 no children');
    });

    test('four headers one threaded', () {
      final h0 = ArticleHeader(1, testHeader0);
      final h1 = ArticleHeader(2, testHeader1);
      final h2 = ArticleHeader(3, testHeader2);
      final h3 = ArticleHeader(4, testHeader3);
      final headers = HeadersForGroup.empty('testThreading1')
          .mergeHeaders([h0, h1, h2, h3]);

      expect(headers.thread(), headers, reason: 'thread returns hfg');
      expect(headers.headers.length, 4, reason: 'h0,h1,h2, h3 loaded');

      expect(h0.isChild, false, reason: 'h0 is not child');
      expect(h0.children.length, 1, reason: 'h1 has 1 child');

      expect(h1.isChild, true, reason: 'h1 is child');
      expect(h1.children.length, 1, reason: 'h1 has 1 child');

      expect(h2.isChild, true, reason: 'h2 is child');
      expect(h2.children.length, 0, reason: 'h2 no children');

      expect(h3.isChild, false, reason: 'h3 is not child');
      expect(h3.children.length, 0, reason: 'h3 no children');
    });

    test('three headers one threaded with gap (h1)', () {
      final h0 = ArticleHeader(1, testHeader0);
      final h2 = ArticleHeader(3, testHeader2);
      final h3 = ArticleHeader(4, testHeader3);
      final headers = HeadersForGroup.empty('testThreading1')
          .mergeHeaders([h0, h2, h3]);

      expect(headers.thread(), headers, reason: 'thread returns hfg');
      expect(headers.headers.length, 3, reason: 'h0,h2, h3 loaded');

      expect(h0.isChild, false, reason: 'h0 is not child');
      expect(h0.children.length, 1, reason: 'h1 has 1 child');

      expect(h2.isChild, true, reason: 'h2 is child');
      expect(h2.children.length, 0, reason: 'h2 no children');

      expect(h3.isChild, false, reason: 'h3 is not child');
      expect(h3.children.length, 0, reason: 'h3 no children');
    });

    test('Six headers two threaded', () {
      final h0 = ArticleHeader(1, testHeader0);
      final h1 = ArticleHeader(2, testHeader1);
      final h2 = ArticleHeader(3, testHeader2);
      final h3 = ArticleHeader(4, testHeader3);
      final h4 = ArticleHeader(5, testHeader4);
      final h5 = ArticleHeader(6, testHeader5);
      final h6 = ArticleHeader(7, testHeader6);

      final headers = HeadersForGroup.empty('testThreading1')
          .mergeHeaders([h0, h1, h2, h3, h4, h5, h6]);

      expect(headers.thread(), headers, reason: 'thread returns hfg');
      expect(headers.headers.length, 7, reason: 'h0,h1,h2,h3,h4,h5,h6 loaded');

      expect(h0.from, 'Test 0 <test0@gmail.com>');
      expect(h0.isChild, false, reason: 'h0 is not child');
      expect(h0.children.length, 1, reason: 'h1 has 1 child');

      expect(h1.from, 'Test 1 <test1@gmail.com>');
      expect(h1.isChild, true, reason: 'h1 is child');
      expect(h1.children.length, 1, reason: 'h1 has 1 child');

      expect(h2.from, 'Test 2 <test2@gmail.com>');
      expect(h2.isChild, true, reason: 'h2 is child');
      expect(h2.children.length, 0, reason: 'h2 has no children');

      expect(h3.from, 'Test 3 <test3@gmail.com>');
      expect(h3.isChild, false, reason: 'h3 is not child');
      expect(h3.children.length, 2, reason: 'h3 has two children');

      expect(h4.from, 'Test 4 <test4@gmail.com>');
      expect(h4.isChild, true, reason: 'h4 is child');
      expect(h4.children.length, 1, reason: 'h4 has one child');

      expect(h5.from, 'Test 5 <test5@gmail.com>');
      expect(h5.isChild, true, reason: 'h5 is child');
      expect(h5.children.length, 0, reason: 'h5 has no children');

      expect(h6.from, 'Test 6 <test6@gmail.com>');
      expect(h6.isChild, true, reason: 'h6 is child');
      expect(h6.children.length, 0, reason: 'h6 no children');
    });
  });
}

final testHeader0 = fixHeaderLines(r'''Path: aioe.org!eternal-september.org!reader02.eternal-september.org!.POSTED!not-for-mail
    From: Test 0 <test0@gmail.com>
    Newsgroups: rec.outdoors.rv-travel
    Subject: OT? - Sigh
    Date: Sun, 8 Aug 2021 13:33:48 -0500
    Organization: A noiseless patient Spider
    Lines: 4
    Message-ID: <sep82b$vc1$1@dont-email.me>
    Mime-Version: 1.0
    Content-Type: text/plain; charset=utf-8; format=flowed
    Content-Transfer-Encoding: 7bit
    Injection-Date: Sun, 8 Aug 2021 18:33:47 -0000 (UTC)
    Injection-Info: reader02.eternal-september.org; posting-host="59435aef94660cbfdd2a4e419eedd2b3";
      logging-data="32129"; mail-complaints-to="abuse@eternal-september.org";	posting-account="U2FsdGVkX1/TRrRwWA4qqOkA8alFqanM/CAKcDz3jbk="
    User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:78.0) Gecko/20100101
     Thunderbird/78.12.0
    Cancel-Lock: sha1:GNxKjD3st6aUg/VS1O2udV6AuIw=
    Content-Language: en-US
    X-Mozilla-News-Host: news://eternal-september.org:119
    Xref: aioe.org rec.outdoors.rv-travel:349298'''
);

final testHeader1 =  fixHeaderLines(r'''Path: aioe.org!eternal-september.org!reader02.eternal-september.org!.POSTED!not-for-mail
    From: Test 1 <test1@gmail.com>
    Newsgroups: rec.outdoors.rv-travel
    Subject: Re: OT? - Sigh
    Date: Sun, 8 Aug 2021 19:32:11 -0000 (UTC)
    Organization: A noiseless patient Spider
    Lines: 114
    Message-ID: <sepbfq$bvg$1@dont-email.me>
    References: <sep82b$vc1$1@dont-email.me>
    Mime-Version: 1.0
    Content-Type: text/plain; charset=UTF-8
    Content-Transfer-Encoding: 8bit
    Injection-Date: Sun, 8 Aug 2021 19:32:11 -0000 (UTC)
    Injection-Info: reader02.eternal-september.org; posting-host="de2352ae10ce038321fe00cb93c877da";
      logging-data="12272"; mail-complaints-to="abuse@eternal-september.org";	posting-account="U2FsdGVkX19bKfCNNKEAguAgPsgiqihuXypr+qjHau8="
    User-Agent: Pan/0.146 (Hic habitat felicitas; d7a48b4
     gitlab.gnome.org/GNOME/pan.git)
    Cancel-Lock: sha1:pRwHnGm8hu9YzurgGWVZNU7MS8w=
    Xref: aioe.org rec.outdoors.rv-travel:349300'''
);


final testHeader2 = fixHeaderLines(r'''Path: aioe.org!eternal-september.org!reader02.eternal-september.org!.POSTED!not-for-mail
    From: Test 2 <test2@gmail.com>
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
    Xref: aioe.org rec.outdoors.rv-travel:349310'''
);

final testHeader3 = fixHeaderLines(r'''Path: aioe.org!fy8XBelaBel5lZatSY33qg.user.46.165.242.91.POSTED!not-for-mail
    From: Test 3 <test3@gmail.com>
    Newsgroups: rec.outdoors.rv-travel
    Subject: OT? - Yep
    Date: Sat, 21 Aug 2021 10:47:45 -0500
    Organization: Aioe.org NNTP Server
    Message-ID: <sfr771$1j4p$1@gioia.aioe.org>
    Mime-Version: 1.0
    Content-Type: text/plain; charset=utf-8; format=flowed
    Content-Transfer-Encoding: 8bit
    Injection-Info: gioia.aioe.org; logging-data="52377"; posting-host="fy8XBelaBel5lZatSY33qg.user.gioia.aioe.org"; mail-complaints-to="abuse@aioe.org";
    User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:78.0)
     Gecko/20100101 Thunderbird/78.13.0
    X-Mozilla-News-Host: news://news.aioe.net:119
    Content-Language: en-US
    X-Notice: Filtered by postfilter v. 0.9.2
    Xref: aioe.org rec.outdoors.rv-travel:349632'''
);

final testHeader4 = fixHeaderLines(r'''X-Received: by 2002:a37:9e11:: with SMTP id h17mr14111933qke.370.1629563696878;
        Sat, 21 Aug 2021 09:34:56 -0700 (PDT)
    X-Received: by 2002:aca:4e4e:: with SMTP id c75mr7032797oib.60.1629563696579;
     Sat, 21 Aug 2021 09:34:56 -0700 (PDT)
    Path: aioe.org!news.mixmin.net!proxad.net!feeder1-2.proxad.net!209.85.160.216.MISMATCH!news-out.google.com!nntp.google.com!postnews.google.com!google-groups.googlegroups.com!not-for-mail
    Newsgroups: rec.outdoors.rv-travel
    Date: Sat, 21 Aug 2021 09:34:56 -0700 (PDT)
    In-Reply-To: <sfr771$1j4p$1@gioia.aioe.org>
    Injection-Info: google-groups.googlegroups.com; posting-host=2601:643:200:8400:ddb2:a8ab:df7a:18ba;
     posting-account=7M96DAkAAADh9aje_aot6f0DlvCfcFij
    NNTP-Posting-Host: 2601:643:200:8400:ddb2:a8ab:df7a:18ba
    References: <sfr771$1j4p$1@gioia.aioe.org>
    User-Agent: G2/1.0
    MIME-Version: 1.0
    Message-ID: <0a63a809-75f8-4d24-9721-92541c0e51d9n@googlegroups.com>
    Subject: Re: OT? - Yep
    From: Test 4 <test4@gmail.com>
    Injection-Date: Sat, 21 Aug 2021 16:34:56 +0000
    Content-Type: text/plain; charset="UTF-8"
    Content-Transfer-Encoding: quoted-printable
    Xref: aioe.org rec.outdoors.rv-travel:349637'''
);

final testHeader5 = fixHeaderLines(r'''Path: aioe.org!feeder1.feed.usenet.farm!feed.usenet.farm!tr3.eu1.usenetexpress.com!feeder.usenetexpress.com!tr3.iad1.usenetexpress.com!border1.nntp.dca1.giganews.com!nntp.giganews.com!buffer1.nntp.dca1.giganews.com!news.giganews.com.POSTED!not-for-mail
    NNTP-Posting-Date: Sat, 21 Aug 2021 21:26:36 -0500
    Reply-To: i09172@removethisspamblockerstuff-yahoo.com
    Subject: Re: OT? - Yep
    Newsgroups: rec.outdoors.rv-travel
    References: <sfr771$1j4p$1@gioia.aioe.org>
     <0a63a809-75f8-4d24-9721-92541c0e51d9n@googlegroups.com>
    From: Test 5 <test5@gmail.com>
    Date: Sat, 21 Aug 2021 19:26:40 -0700
    User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:78.0) Gecko/20100101 Thunderbird/78.13.0
    MIME-Version: 1.0
    In-Reply-To: <0a63a809-75f8-4d24-9721-92541c0e51d9n@googlegroups.com>
    Content-Type: text/plain; charset=utf-8; format=flowed
    Content-Language: en-US
    Content-Transfer-Encoding: 7bit
    Message-ID: <9Jidnb74U6FBKLz8nZ2dnUU7-eudnZ2d@giganews.com>
    Lines: 16
    X-Usenet-Provider: http://www.giganews.com
    X-Trace: sv3-oDTm9x/AydiP9PsTQvtWh6szGfjaeocZCYdy2rOjAF2V/1h7dNL6GuOQq2XoxDMZBs/U3uoBdZfWQfJ!i8SEEhQCkT/dxMxHgDWXQwLsQjDc7WFyB+7wQIYqH1m2T+maZ4VWzLWSr4MpyRvukyl5Eb1oYKY=
    X-Complaints-To: abuse@giganews.com
    X-DMCA-Notifications: http://www.giganews.com/info/dmca.html
    X-Abuse-and-DMCA-Info: Please be sure to forward a copy of ALL headers
    X-Abuse-and-DMCA-Info: Otherwise we will be unable to process your complaint properly
    X-Postfilter: 1.3.40
    X-Original-Bytes: 2307
    Xref: aioe.org rec.outdoors.rv-travel:349647'''
);

final testHeader6 = fixHeaderLines(r'''X-Received: by 2002:ac8:5848:: with SMTP id h8mr23276890qth.254.1629562038364;
        Sat, 21 Aug 2021 09:07:18 -0700 (PDT)
    X-Received: by 2002:a05:6808:21a0:: with SMTP id be32mr6629621oib.148.1629562038144;
     Sat, 21 Aug 2021 09:07:18 -0700 (PDT)
    Path: aioe.org!news.dns-netz.com!news.freedyn.net!newsreader4.netcologne.de!news.netcologne.de!peer01.ams1!peer.ams1.xlned.com!news.xlned.com!peer03.iad!feed-me.highwinds-media.com!news.highwinds-media.com!news-out.google.com!nntp.google.com!postnews.google.com!google-groups.googlegroups.com!not-for-mail
    Newsgroups: rec.outdoors.rv-travel
    Date: Sat, 21 Aug 2021 09:07:17 -0700 (PDT)
    In-Reply-To: <sfr771$1j4p$1@gioia.aioe.org>
    Injection-Info: google-groups.googlegroups.com; posting-host=70.71.79.196; posting-account=C-Xg9QoAAAArxG0HG9CbWJY1Fzhk25KS
    NNTP-Posting-Host: 70.71.79.196
    References: <sfr771$1j4p$1@gioia.aioe.org>
    User-Agent: G2/1.0
    MIME-Version: 1.0
    Message-ID: <eb3d9a4a-9d5a-4c21-8211-5e0d45d91dc2n@googlegroups.com>
    Subject: Re: OT? - Yep
    From: Test 6 <test6@gmail.com>
    Injection-Date: Sat, 21 Aug 2021 16:07:18 +0000
    Content-Type: text/plain; charset="UTF-8"
    X-Received-Bytes: 1277
    Xref: aioe.org rec.outdoors.rv-travel:349634'''
);

final testHeaderMultiContinueLines  = [
  r"Path: aioe.org!news.snarked.org!border2.nntp.dca1.giganews.com!nntp.giganews.com!buffer2.nntp.dca1.giganews.com!news.giganews.com.POSTED!not-for-mail",
  r"NNTP-Posting-Date: Mon, 23 Aug 2021 20:37:55 -0500",
  r"Reply-To: i09172@removethisspamblockerstuff-yahoo.com",
  r"Subject: Re: Bruce's Beach",
  r"Newsgroups: rec.outdoors.rv-travel",
  r"References: <s4sgij$hj0$1@dont-email.me> <s4sh0n$1loj$1@gioia.aioe.org>",
  r" <s4sler$hj0$4@dont-email.me> <s4v3af$rv4$1@gioia.aioe.org>",
  r" <sfujuh$l09$2@dont-email.me> <Kt6dnTvIGpy2lL78nZ2dnUU7-XednZ2d@giganews.com>",
  r" <7VDUI.84259$Qp7.22991@fx46.iad> <sfvvlh$eec$2@gioia.aioe.org>",
  r" <euWUI.50796$Oz2.12756@fx47.iad> <sg1hsn$t8n$2@gioia.aioe.org>",
  r"From: Test Multi <testmulti@yahoo.com>",
  r"Date: Mon, 23 Aug 2021 18:37:58 -0700",
  r"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:78.0) Gecko/20100101",
  r" Thunderbird/78.13.0",
  r"MIME-Version: 1.0",
  r"In-Reply-To: <sg1hsn$t8n$2@gioia.aioe.org>",
  r"Content-Type: text/plain; charset=utf-8; format=flowed",
  r"Content-Language: en-US",
  r"Content-Transfer-Encoding: 8bit",
  r"Message-ID: <8tqdnSTKV5Lu0Ln8nZ2dnUU7-eudnZ2d@giganews.com>",
  r"Lines: 57",
  r"X-Usenet-Provider: http://www.giganews.com",
  r"X-Trace: sv3-wALD5Lg49fwS73XCZ+iIgiuf6UCY0ibjlZtTB3oP+Zp74dANk0nurHTobpE7C4Bq2ZTR2u/YGqUEdIi!869zNY71bqL6YJvEBhYhLxKCS7b9jXizlo4dGu/hRQf/cbteShEmHpPpfELJNPgHmLBxWhM26LA=",
  r"X-Complaints-To: abuse@giganews.com",
  r"X-DMCA-Notifications: http://www.giganews.com/info/dmca.html",
  r"X-Abuse-and-DMCA-Info: Please be sure to forward a copy of ALL headers",
  r"X-Abuse-and-DMCA-Info: Otherwise we will be unable to process your complaint properly",
  r"X-Postfilter: 1.3.40",
  r"X-Original-Bytes: 4179",
  r"Xref: aioe.org rec.outdoors.rv-travel:349680"
];

List<String> fixHeaderLines(String lines) {
  return lines.split('\n')
      .map((l) => (l.startsWith('    ') ? l.substring(4) : l).trimRight())
      .toList();
}