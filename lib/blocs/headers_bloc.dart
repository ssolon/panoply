import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math';

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

class HeadersBlocErrorFetchingEvent extends HeadersBlocEvent {
  final String groupName;
  final error;

  HeadersBlocErrorFetchingEvent(this.groupName, this.error);
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

class HeadersBlocFetchingState extends HeadersBlocState {
  final String groupName;

  HeadersBlocFetchingState(this.groupName);
}

class HeadersBlocFetchDoneState extends HeadersBlocState {
  final HeadersForGroup headers;

  HeadersBlocFetchDoneState(this.headers);
}

class HeadersBlocErrorFetchingState extends HeadersBlocState {
  final String groupName;
  final error;

  HeadersBlocErrorFetchingState(this.groupName, this.error);
}

class HeadersBlocSavedState extends HeadersBlocState {}

/// Something changes in [header].
class HeadersBlocHeaderChangedState extends HeadersBlocState {
  final Header header;

  HeadersBlocHeaderChangedState(this.header);
}

/// We have a list of headers to be displayed.
class HeadersBlocLoadedState extends HeadersBlocState {
  final HeadersForGroup headersForGroup;

  HeadersBlocLoadedState(this.headersForGroup);
}

class HeadersBloc extends Bloc<HeadersBlocEvent, HeadersBlocState> {
  final NewsService _newsService;
  // String groupName = '';
  final log = Loggy("HeadersBloc");

  /// We build a list of headers here for the current [groupName].
  HeadersForGroup _loadedHeaders = HeadersForGroup.empty('');

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
    } else if (event is HeadersBlocErrorFetchingEvent) {
      yield HeadersBlocErrorFetchingState(event.groupName, event.error);
    } else {
      throw UnimplementedError("Event = $event");
    }
  }

  Stream<HeadersBlocState> _saveHeadersForGroup(
      HeadersForGroup headers) async* {
    final file = await headersFile(headers.groupName);

    final jsonString = jsonEncode(headers.toJson());
    await file.writeAsString(jsonString);

    yield HeadersBlocSavedState();
  }

  Stream<HeadersBlocState> _loadHeadersForGroup(String groupName) async* {
    yield HeadersBlocLoadingState(groupName);

    // Read from a file name with groupName, if there is one.

    final file = await headersFile(groupName);

    if (file.existsSync()) {
      final jsonString = await file.readAsString();
      _loadedHeaders = restoreFromJson(groupName, jsonString);
    } else {
      _loadedHeaders = HeadersForGroup.empty(groupName); // Nothing was saved
    }

    yield HeadersBlocLoadedState(_loadedHeaders);
  }

  /// Create and HeadersForGroup object for [groupName] from [jsonString].
  HeadersForGroup restoreFromJson(String groupName, String jsonString) {
    final decoded = jsonDecode(jsonString);
    return HeadersForGroup.fromJson(groupName, decoded);
  }

  /// Return the full path for storing headers for [groupName].
  Future<File> headersFile(String groupName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return Future.value(File(join(appDocDir.path, "$groupName.headers")));
  }

  /// Fetch headers meeting [criteria] from server using [NewsService].
  Stream<HeadersBlocFetchingState> _fetchHeaders(
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
      } else if (state is NewsServiceHeaderFetchErrorState) {
        bloc.add(HeadersBlocErrorFetchingEvent(groupName, state.error));
      }
    });
    yield HeadersBlocFetchingState(groupName);
  }

  /// We received a header from server, add to the collection and display?
  Stream<HeadersBlocState> _addFetchedHeader(Header header) async* {
    _fetchedHeaders.add(header);
  }

  /// Deal with fetched headers
  Stream<HeadersBlocState> _handleFetchedHeaders(String groupName) async* {
    // TODO Threading
    // TODO Cleanup expired headers using low article number from (LIST)GROUP

    final result = _loadedHeaders.mergeHeaders(_fetchedHeaders);
    _fetchedHeaders = [];
    yield HeadersBlocFetchDoneState(result);
  }

 }
