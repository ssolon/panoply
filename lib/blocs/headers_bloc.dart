import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:panoply/models/header.dart';
import 'package:panoply/services/news_service.dart';

abstract class HeadersBlocEvent {} //TODO Equatable?

/// Load headers for [groupName].
class HeadersBlocLoadEvent extends HeadersBlocEvent {
  final String groupName;

  HeadersBlocLoadEvent(this.groupName);
}

/// Fetch headers based on [criteria] from the server
class HeadersForGroupFetchEvent extends HeadersBlocEvent {
  final FetchCriteria criteria;

  HeadersForGroupFetchEvent(this.criteria);
}

/// [header] was fetched from the nntp server.
class HeadersBlocHeaderFetchedEvent extends HeadersBlocEvent {
  final Header header;

  HeadersBlocHeaderFetchedEvent(this.header);
}

/// Finished fetching headers from NewsService
class HeadersBlocHeaderFetchDoneEvent extends HeadersBlocEvent {}

abstract class HeadersBlocState {}

class HeadersBlocInitialState extends HeadersBlocState {}

class HeadersBlocLoadingState extends HeadersBlocState {
  final String groupName;

  HeadersBlocLoadingState(this.groupName);
}

/// We have a list of headers to be displayed.
class HeadersBlocLoadedState extends HeadersBlocState {
  final String groupName;
  final List<Header> headers;

  HeadersBlocLoadedState(this.groupName, this.headers);
}

class HeadersBloc extends Bloc<HeadersBlocEvent, HeadersBlocState> {
  final NewsService _newsService;
  String groupName = '';
  final log = Loggy("HeadersBloc");

  /// We build a list of headers here for the current [groupName].
  List<ThreadedHeader> _loadedHeaders = [];

  // Holding area for fetched headers
  List<Header> _fetchedHeaders = [];

  HeadersBloc(this._newsService) : super(HeadersBlocInitialState()) {}

  @override
  Stream<HeadersBlocState> mapEventToState(HeadersBlocEvent event) async* {
    if (event is HeadersBlocLoadEvent) {
      groupName = event.groupName;
      yield HeadersBlocLoadingState(groupName);
      //TODO Load headers from persistent store into [_loadedHeaders]
      _loadedHeaders = []; //TODO persistence
      yield HeadersBlocLoadedState(groupName, _loadedHeaders);
    } else if (event is HeadersForGroupFetchEvent) {
      yield* _fetchHeaders(event.criteria);
    } else if (event is HeadersBlocHeaderFetchedEvent) {
      yield* _addFetchedHeader(event.header);
    } else if (event is HeadersBlocHeaderFetchDoneEvent) {
      yield* _handleFetchedHeaders();
    } else {
      throw UnimplementedError("Event = $event");
    }
  }

  /// Fetch headers meeting [criteria] from server using [NewsService].
  Stream<HeadersBlocLoadingState> _fetchHeaders(FetchCriteria criteria) async* {
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
        bloc.add(HeadersBlocHeaderFetchDoneEvent());
      }
    });

    yield HeadersBlocLoadingState(groupName);
  }

  /// We received a header from server, add to the collection and display?
  Stream<HeadersBlocState> _addFetchedHeader(Header header) async* {
    _fetchedHeaders.add(header);
  }

  /// Deal with fetched headers
  Stream<HeadersBlocState> _handleFetchedHeaders() async* {

    //!!!! For now just convert to threaded header and replace loaded
    // TODO Merge fetched headers
    // TODO Threading
    // TODO Cleanup expired headers using low article number from (LIST)GROUP

    _loadedHeaders =
        _fetchedHeaders.map((h) => ThreadedHeader.from(h)).toList();
    _fetchedHeaders = [];

    yield HeadersBlocLoadedState(groupName, _loadedHeaders);
  }
}
