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
      // TODO yield the finished, merged, collection on done
      // TODO or piece by piece?
      //!!!! For now just return them as is.
      log.debug("Listen state=$state");
      if (state is NewsServiceHeaderFetchedState) {
        bloc.add(HeadersBlocHeaderFetchedEvent(state.header));
      }
    });

    yield HeadersBlocLoadingState(groupName);
  }

  /// We received a header from server, add to the collection and display?
  Stream<HeadersBlocState> _addFetchedHeader(Header header) async* {
    //!!!! For now just convert to threaded header and append to the list
    final threaded = ThreadedHeader.from(header);
    // TODO Build threading
    _loadedHeaders.add(threaded);
    log.debug("Loaded headers $_loadedHeaders");
    yield HeadersBlocLoadedState(groupName, _loadedHeaders);
  }
}
