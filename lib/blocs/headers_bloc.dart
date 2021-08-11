

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:panoply/models/header.dart';

abstract class HeadersBlocEvent {} //TODO Equatable?
class HeadersBlocLoadEvent extends HeadersBlocEvent {
  final String groupName;
  HeadersBlocLoadEvent(this.groupName);
}

abstract class HeadersBlocState {}

class HeadersBlocInitialState extends HeadersBlocState {}

class HeadersBlocLoadingState extends HeadersBlocState {
  final String groupName;
  HeadersBlocLoadingState(this.groupName);
}

class HeadersBlocLoadedState extends HeadersBlocState {
  final String groupName;
  final List<ThreadedHeader> headers;

  HeadersBlocLoadedState(this.groupName, this.headers);
}

class HeadersBloc extends Bloc<HeadersBlocEvent, HeadersBlocState> {

  HeadersBloc(): super(HeadersBlocInitialState()) {}

  @override
  Stream<HeadersBlocState> mapEventToState(HeadersBlocEvent event) async* {
    if (event is HeadersBlocLoadEvent) {
      yield HeadersBlocLoadingState(event.groupName);
      yield HeadersBlocLoadedState(event.groupName, headersFor(event.groupName));
    } else {
      throw UnimplementedError("Event = $event");
    }
  }

  /// Return a list of overviews for [groupName].
  /// TODO Stream this information to use with an on demand list view?
  List<ThreadedHeader> headersFor(String groupName) {

    return [
      ThreadedHeader(1, '$groupName-1', 'from1', 'date1', 'msgId1', 'references1', 10, 1, 'xref1', []),
      ThreadedHeader(2, '$groupName-2', 'from2', 'date2', 'msgId2', 'references2', 20, 2, 'xref2', []),
      ThreadedHeader(3, '$groupName-3', 'from3', 'date3', 'msgId3', 'references3', 30, 3, 'xref3', []),
      ThreadedHeader(4, '$groupName-4', 'from4', 'date4', 'msgId4', 'references4', 40, 4, 'xref4', []),
      ThreadedHeader(5, '$groupName-5', 'from5', 'date5', 'msgId5', 'references5', 50, 5, 'xref5', []),
    ];
  }


}


