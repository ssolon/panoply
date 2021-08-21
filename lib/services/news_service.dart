import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:panoply/blocs/status_bloc.dart';
import 'package:panoply/models/header.dart';
import 'package:panoply/services/nntp_server.dart';

///
/// Communicate with NNTP server and handle the actual news logic.
///

abstract class NewsServiceEvent {}


class HeadersForGroupRequested extends NewsServiceEvent {

  final String groupName;
  final FetchCriteria criteria;

  HeadersForGroupRequested(this.groupName, this.criteria);

  @override
  String toString() {
    return "Fetch headers from $groupName for ${super.toString()}";
  }
}

abstract class NewsServiceState {}

/// Initial state
class NewsServiceInitialState extends NewsServiceState {}

class NewsServiceStartLoadingHeadersState extends NewsServiceState {
  final String groupName;
  NewsServiceStartLoadingHeadersState(this.groupName);
}

class NewsServiceDoneLoadingHeadersState extends NewsServiceState {
  final String groupName;
  final NntpServer server;
  final int count;
  final List<Header> headers;

  NewsServiceDoneLoadingHeadersState(
      this.groupName,
      this.server,
      this.count,
      this.headers);
}

@immutable
class NewsServiceStatusUpdateState extends NewsServiceState {
  final String status;
  NewsServiceStatusUpdateState(this.status);
}

@immutable
/// Statistics for [groupName] from (LIST)GROUP request to server
class NewsServiceGroupStatsState extends NewsServiceState {
  final String groupName;
  final int estimatedCount;
  final int lowWaterMark;
  final int highWaterMark;

  NewsServiceGroupStatsState(
      this.groupName,
      this.estimatedCount,
      this.lowWaterMark,
      this.highWaterMark
      );
}

@immutable
class NewsServiceHeaderFetchedState extends NewsServiceState {
  final Header header;
  NewsServiceHeaderFetchedState(this.header);
}

@immutable
class NewsServiceHeaderFetchErrorState extends NewsServiceState {
  final String error;

  NewsServiceHeaderFetchErrorState(this.error);
}

@immutable
class NewsServiceHeadersFetchDoneState extends NewsServiceState {
  final String groupName;
  final int headerCount;

  NewsServiceHeadersFetchDoneState(this.groupName, this.headerCount);
}
class NewsService extends Bloc<NewsServiceEvent, NewsServiceState> {

  NntpServer? primaryServer;
  final StatusBloc _statusBloc;
  final log = Loggy('NewsService');

  /// Current status of this service which can be used for a status indicator.
  /// Changes will be cause a notify event.
  String status = 'status';

  /// Name of the currently active server (if any).
  String get serverName => primaryServer?.name ?? '????';

  /// CTOR

  NewsService(this.primaryServer, this._statusBloc) : super(NewsServiceInitialState());

   @override
   Stream<NewsServiceState> mapEventToState(NewsServiceEvent event) async* {
     if (event is HeadersForGroupRequested) {
       yield* fetchHeadersForGroup(event);
     }
    // throw UnimplementedError();
  }

  /// Fetch headers for group according to the criteria in [request] and return
  /// one by one for further processing.
  Stream<NewsServiceState> fetchHeadersForGroup(HeadersForGroupRequested request) async* {
    var count = 0;
    final criteria = request.criteria;

     // Update our status
     _updateStatus("Fetching ${request.criteria.toString()}");

     // Get article numbers for group, this also selects the group

    try {
      final listNumbers = "LISTGROUP ${request.groupName} ${criteria.articleRange}";
      var groupResponse = await primaryServer!.executeMultilineRequest(
          listNumbers);

      if (groupResponse.isOK) {
        yield* _reportGroupStats(groupResponse);

        final articleNumbers = criteria.iterableFor(groupResponse.body);
        for (var articleNumber in articleNumbers) {
          final n = int.parse(articleNumber);

          final request = "HEAD $n";
          final headerResponse = await primaryServer!.executeMultilineRequest(request);
          _checkResponse(request, primaryServer!, headerResponse);

          final header = ArticleHeader(n, headerResponse.body);
          // TODO Date check
          count++;
          _updateStatus("Fetched $count headers");
          yield NewsServiceHeaderFetchedState(header);
        }
      }
      else {
        _checkResponse("fetch '$listNumbers'", primaryServer!, groupResponse);
      }

      // Update status to done

      _updateStatus("$count headers fetched for ${request.groupName}");
      yield NewsServiceHeadersFetchDoneState(request.groupName, count);
    }
    catch (e) {
      log.error("Exception during header fetch:$e");
      yield NewsServiceHeaderFetchErrorState("Exception fetching headers:$e");
    }
  }

  Stream<NewsServiceState> _reportGroupStats(Response response) async* {
     final items = response.statusLine.split(' ');
     assert(items.length > 3, "group status line items length=${items.length}");
     final count = int.parse(items[0]);
     final low = int.parse(items[1]);
     final high = int.parse(items[2]);
     final group = items[3];

     yield NewsServiceGroupStatsState(group, count, low, high);
  }
  void _updateStatus(String status) {
     _statusBloc.add(StatusBlocUpdatedStatusEvent('NewsService', status));
  }

  /// Fetch and return a complete article (header and body) for [header.msgId].
  Future<Article> fetchArticle(Header header) async {
     final request = "ARTICLE ${header.msgId}";
     final response = await primaryServer?.executeMultilineWithHeadersRequest(request);
     _checkResponse("fetch article msgId=${header.msgId} subject=$header.subject",
         primaryServer!, response!);

     return Article(
         ArticleHeader(header.number, response.headers),
         response.body
    );
  }

  /// Fetch the body for [header.msgId].
  Future<List<String>> fetchBody(Header header) async {
    final request = "BODY ${header.msgId}";
    final response = await primaryServer?.executeMultilineRequest(request);
    return response?.body ?? [];
  }

  /// Handle a response from the server in an appropriate way returning true
  /// if everything is ok and throwing if not.
  bool _checkResponse(String description, NntpServer server, Response response) {
    if (response.isOK) {
      return true;
    }

    // For now just throw an general exception

    final message = "NewsService: $description failure from server=${server.name}"
        " statusCode=${response.statusCode} description=${response.statusLine}";
    throw Exception(message);
  }
}

final testHeaders = [header1, header2, header3];

final header1 = ArticleHeader(349365,
r'''Path: aioe.org!news.uzoreto.com!news-out.netnews.com!news.alt.net!fdc2.netnews.com!peer01.ams1!peer.ams1.xlned.com!news.xlned.com!peer03.iad!feed-me.highwinds-media.com!news.highwinds-media.com!fx39.iad.POSTED!not-for-mail
Newsgroups: rec.outdoors.rv-travel
X-Mozilla-News-Host: news://news.astraweb.com:119
From: Frank Howell <fphowell@usermail.com>
Subject: Holy Shit, a Libertarian might win Calf recall!
User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:51.0) Gecko/20100101
Firefox/51.0 SeaMonkey/2.48
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8; format=flowed
Content-Transfer-Encoding: 8bit
Lines: 14
Message-ID: <Aq1RI.4533$6h1.961@fx39.iad>
X-Complaints-To: https://www.astraweb.com/aup
NNTP-Posting-Date: Thu, 12 Aug 2021 04:27:12 UTC
Date: Wed, 11 Aug 2021 21:27:10 -0700
X-Received-Bytes: 1271
Xref: aioe.org rec.outdoors.rv-travel:349365'''.split('\n').toList());

final header2 = ArticleHeader(349364,
r'''Path: aioe.org!eternal-september.org!reader02.eternal-september.org!.POSTED!not-for-mail
From: Technobarbarian <Technobarbarian-ztopzpam@gmail.com>
Newsgroups: rec.outdoors.rv-travel
Subject: Re: OT? - For Your Enjoyment
Date: Thu, 12 Aug 2021 04:13:27 -0000 (UTC)
Organization: A noiseless patient Spider
Lines: 46
Message-ID: <sf2757$f1s$1@dont-email.me>
References: <sf1cqb$d2e$1@dont-email.me>
Mime-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Injection-Date: Thu, 12 Aug 2021 04:13:27 -0000 (UTC)
Injection-Info: reader02.eternal-september.org; posting-host="7f2a96c7df0c586d8c8681c9a11817a6";
logging-data="15420"; mail-complaints-to="abuse@eternal-september.org";	posting-account="U2FsdGVkX1+Vdkmy3mnoh/qboR7jDscZms70HQZ6qz0="
User-Agent: Pan/0.146 (Hic habitat felicitas; d7a48b4
gitlab.gnome.org/GNOME/pan.git)
Cancel-Lock: sha1:E6Hbf2UvZTzFtwA4I6MIh1BdCNI=
Xref: aioe.org rec.outdoors.rv-travel:349364'''.split('\n').toList());

final header3 = ArticleHeader(349363,
r'''Path: aioe.org!news.snarked.org!border2.nntp.dca1.giganews.com!nntp.giganews.com!buffer2.nntp.dca1.giganews.com!buffer1.nntp.dca1.giganews.com!news.giganews.com.POSTED!not-for-mail
NNTP-Posting-Date: Wed, 11 Aug 2021 21:00:37 -0500
Newsgroups: rec.outdoors.rv-travel
X-Mozilla-News-Host: snews://news.giganews.com:563
Reply-To: i09172@removethisspamblockerstuff-yahoo.com
From: kmiller <i09172@removethisspamblockerstuff-yahoo.com>
Subject: Move To Oklahoma
Date: Wed, 11 Aug 2021 19:00:38 -0700
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:78.0) Gecko/20100101
Thunderbird/78.12.0
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8; format=flowed
Content-Language: en-US
Content-Transfer-Encoding: 7bit
Message-ID: <ZPOdnY80nrBYHYn8nZ2dnUU7-ffNnZ2d@giganews.com>
Lines: 8
X-Usenet-Provider: http://www.giganews.com
X-Trace: sv3-CuLITj+l/fHPMNZZ0Pi0V4N9kSHxcrsDxVX8SOPR8lU/cLi0ZZuVbOjvkxmWJtJtUN+tsE3uy7W/fYX!mh7vH5ahuTABWLtvLB4SjzM22tuH1HdlBAmtXKDHnk3DW4jPbcE6FSjWHCOKf7wHGrmi4zMDWb4=
X-Complaints-To: abuse@giganews.com
X-DMCA-Notifications: http://www.giganews.com/info/dmca.html
X-Abuse-and-DMCA-Info: Please be sure to forward a copy of ALL headers
X-Abuse-and-DMCA-Info: Otherwise we will be unable to process your complaint properly
X-Postfilter: 1.3.40
X-Original-Bytes: 1442
Xref: aioe.org rec.outdoors.rv-travel:349363'''.split('\n').toList());