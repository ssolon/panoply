

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

abstract class HeadersBlocState {}

class HeadersBlocInitialState extends HeadersBlocState {}

class HeadersBlocLoadingState extends HeadersBlocState {
  final String groupName;
  HeadersBlocLoadingState(this.groupName);
}

class HeadersBlocLoadedState extends HeadersBlocState {
  final String groupName;
  //!!! final List<ThreadedHeader> headers;
  final List<Header> headers;

  HeadersBlocLoadedState(this.groupName, this.headers);
}

class HeadersBloc extends Bloc<HeadersBlocEvent, HeadersBlocState> {
  final NewsService _newsService;
  String groupName = '';
  final log = Loggy("HeadersBloc");

  HeadersBloc(this._newsService): super(HeadersBlocInitialState()) {}

  @override
  Stream<HeadersBlocState> mapEventToState(HeadersBlocEvent event) async* {
    if (event is HeadersBlocLoadEvent) {
      groupName = event.groupName;
      yield HeadersBlocLoadingState(groupName);
      yield HeadersBlocLoadedState(groupName, headersFor(groupName));
    }
    else if (event is HeadersForGroupFetchEvent) {
      yield* _loadHeaders(event.criteria);
    }
    else {
      throw UnimplementedError("Event = $event");
    }
  }

  /// Load headers meeting [criteria] from server using service.
  Stream<HeadersBlocLoadedState> _loadHeaders(FetchCriteria criteria) async* {
    List <Header> result = [];

    log.debug("_loadHeaders criteria=$criteria");

    _newsService
        .fetchHeadersForGroup(HeadersForGroupRequested(groupName, criteria))
        .listen((state) {
      // TODO yield the finished, merged, collection on done
      //!!!! For now just return them as is.
      log.debug("Listen state=$state");
      if (state is NewsServiceHeaderFetchedState) {
        result.add(state.header);
      }
    });

    yield HeadersBlocLoadedState(groupName, result);

  }
  /// Return a list of overviews for [groupName].
  /// TODO Stream this information to use with an on demand list view?
  List<ThreadedHeader> headersFor(String groupName) {

    return [];
    //   ThreadedHeader(1, '$groupName-1', 'from1', 'date1', 'msgId1', 'references1', 10, 1, 'xref1', []),
    //   ThreadedHeader(2, '$groupName-2', 'from2', 'date2', 'msgId2', 'references2', 20, 2, 'xref2', []),
    //   ThreadedHeader(3, '$groupName-3', 'from3', 'date3', 'msgId3', 'references3', 30, 3, 'xref3', []),
    //   ThreadedHeader(4, '$groupName-4', 'from4', 'date4', 'msgId4', 'references4', 40, 4, 'xref4', []),
    //   ThreadedHeader(5, '$groupName-5', 'from5', 'date5', 'msgId5', 'references5', 50, 5, 'xref5', []),
    // ];
  }


}


