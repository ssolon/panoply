import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:panoply/models/header.dart';
import 'package:panoply/services/news_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

abstract class HeadersBlocEvent {} //TODO Equatable?

/// Load headers for [groupName].
class HeadersBlocLoadEvent extends HeadersBlocEvent {
  final String groupName;

  HeadersBlocLoadEvent(this.groupName);
}

class HeadersBlocSaveEvent extends HeadersBlocEvent {
  final HeadersForGroup headers;

  HeadersBlocSaveEvent(this.headers);
}

/// Fetch headers based on [criteria] from the server
class HeadersForGroupFetchEvent extends HeadersBlocEvent {
  final String groupName;
  final FetchCriteria criteria;

  HeadersForGroupFetchEvent(this.groupName, this.criteria);
}

/// [header] was fetched from the nntp server.
class HeadersBlocHeaderFetchedEvent extends HeadersBlocEvent {
  final Header header;

  HeadersBlocHeaderFetchedEvent(this.header);
}

/// Something changed in [header].
class HeadersBlocHeaderChangedEvent extends HeadersBlocEvent {
  final Header header;

  HeadersBlocHeaderChangedEvent(this.header);
}

/// Finished fetching headers from NewsService
class HeadersBlocHeaderFetchDoneEvent extends HeadersBlocEvent {
  final String groupName;

  HeadersBlocHeaderFetchDoneEvent(this.groupName);
}

abstract class HeadersBlocState {}

class HeadersBlocInitialState extends HeadersBlocState {}

class HeadersBlocLoadingState extends HeadersBlocState {
  final String groupName;

  HeadersBlocLoadingState(this.groupName);
}

class HeadersBlocFetchDoneState extends HeadersBlocState {
  final HeadersForGroup headers;

  HeadersBlocFetchDoneState(this.headers);
}

class HeadersBlocSavedState extends HeadersBlocState {}

/// Something changes in [header].
class HeadersBlocHeaderChangedState extends HeadersBlocState {
  final Header header;

  HeadersBlocHeaderChangedState(this.header);
}

/// We have a list of headers to be displayed.
class HeadersBlocLoadedState extends HeadersBlocState {
  final HeadersForGroup _headersForGroup;

  String get groupName => _headersForGroup.groupName;
  int get firstArticleNumber => _headersForGroup.firstArticleNumber;
  int get lastArticleNumber => _headersForGroup.lastArticleNumber;
  List<Header> get headers => _headersForGroup.headers;

  HeadersBlocLoadedState(this._headersForGroup);
}

class HeadersBloc extends Bloc<HeadersBlocEvent, HeadersBlocState> {
  final NewsService _newsService;
  // String groupName = '';
  final log = Loggy("HeadersBloc");

  /// We build a list of headers here for the current [groupName].
  List<Header> _loadedHeaders = [];

  // Holding area for fetched headers
  List<Header> _fetchedHeaders = [];

  HeadersBloc(this._newsService) : super(HeadersBlocInitialState()) {}

  @override
  Stream<HeadersBlocState> mapEventToState(HeadersBlocEvent event) async* {
    if (event is HeadersBlocLoadEvent) {
      yield* _loadHeadersForGroup(event.groupName);
    } else if (event is HeadersBlocSaveEvent) {
      yield* _saveHeadersForGroup(event.headers);
    } else if (event is HeadersForGroupFetchEvent) {
      yield* _fetchHeaders(event.groupName, event.criteria);
    } else if (event is HeadersBlocHeaderFetchedEvent) {
      yield* _addFetchedHeader(event.header);
    } else if (event is HeadersBlocHeaderFetchDoneEvent) {
      yield* _handleFetchedHeaders(event.groupName);
    } else if (event is HeadersBlocHeaderChangedEvent) {
      yield HeadersBlocHeaderChangedState(event.header);
    } else {
      throw UnimplementedError("Event = $event");
    }
  }

  Stream<HeadersBlocState> _saveHeadersForGroup(
      HeadersForGroup headers) async* {
    final file = await headersFile(headers.groupName);

    final jsonString =
        jsonEncode(headers.headers.map((h) => h.toJson()).toList());
    await file.writeAsString(jsonString);

    yield HeadersBlocSavedState();
  }

  Stream<HeadersBlocState> _loadHeadersForGroup(String groupName) async* {
    yield HeadersBlocLoadingState(groupName);

    // Read from a file name with groupName, if there is one.

    final file = await headersFile(groupName);

    if (file.existsSync()) {
      final json = jsonDecode(await file.readAsString());
      // final l = json.map<ThreadedHeader>((h) {
      //   return ThreadedHeader.from(Header.fromJson(h));
      // }).toList();
      _loadedHeaders = json.map<Header>((h) {
        return ArticleHeader.fromJson(h);
      }).toList();
    } else {
      _loadedHeaders = []; // Nothing saved
    }

    yield HeadersBlocLoadedState(HeadersForGroup(groupName, _loadedHeaders));
  }

  /// Return the full path for storing headers for [groupName].
  Future<File> headersFile(String groupName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return Future.value(File(join(appDocDir.path, "$groupName.headers")));
  }

  /// Fetch headers meeting [criteria] from server using [NewsService].
  Stream<HeadersBlocLoadingState> _fetchHeaders(
      String groupName, FetchCriteria criteria) async* {
    log.debug("_loadHeaders criteria=$criteria");
    final bloc = this;

    final headerSubscription = _newsService
        .fetchHeadersForGroup(HeadersForGroupRequested(groupName, criteria))
        .listen((state) {
      if (state is NewsServiceGroupStatsState) {
        log.debug("Stats for group=${state.groupName}"
            " estimatedCount=${state.estimatedCount}"
            " low=${state.lowWaterMark}"
            " high=${state.highWaterMark}");
      } else if (state is NewsServiceHeaderFetchedState) {
        bloc.add(HeadersBlocHeaderFetchedEvent(state.header));
      } else if (state is NewsServiceHeadersFetchDoneState) {
        bloc.add(HeadersBlocHeaderFetchDoneEvent(state.groupName));
      }
    });

    yield HeadersBlocLoadingState(groupName);
  }

  /// We received a header from server, add to the collection and display?
  Stream<HeadersBlocState> _addFetchedHeader(Header header) async* {
    _fetchedHeaders.add(header);
  }

  /// Deal with fetched headers
  Stream<HeadersBlocState> _handleFetchedHeaders(String groupName) async* {
    //!!!! For now just convert to threaded header and replace loaded
    // TODO Merge fetched headers
    // TODO Threading
    // TODO Cleanup expired headers using low article number from (LIST)GROUP

    _loadedHeaders = _fetchedHeaders;
    _fetchedHeaders = [];

    yield HeadersBlocFetchDoneState(HeadersForGroup(groupName, _loadedHeaders));
  }
}
