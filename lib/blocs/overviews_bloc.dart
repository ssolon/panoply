

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:panoply/models/overview.dart';

abstract class OverviewsBlocEvent {} //TODO Equatable?
class OverviewsBlocLoadEvent extends OverviewsBlocEvent {
  final String groupName;
  OverviewsBlocLoadEvent(this.groupName);
}

abstract class OverviewsBlocState {}

class OverviewsBlocInitialState extends OverviewsBlocState {}

class OverviewsBlocLoadingState extends OverviewsBlocState {
  final String groupName;
  OverviewsBlocLoadingState(this.groupName);
}

class OverviewsBlocLoadedState extends OverviewsBlocState {
  final String groupName;
  final List<ThreadedOverview> overviews;

  OverviewsBlocLoadedState(this.groupName, this.overviews);
}

class OverviewsBloc extends Bloc<OverviewsBlocEvent, OverviewsBlocState> {

  OverviewsBloc(): super(OverviewsBlocInitialState()) {}

  @override
  Stream<OverviewsBlocState> mapEventToState(OverviewsBlocEvent event) async* {
    if (event is OverviewsBlocLoadEvent) {
      yield OverviewsBlocLoadingState(event.groupName);
      yield OverviewsBlocLoadedState(event.groupName, overviewsFor(event.groupName));
    } else {
      throw UnimplementedError("Event = $event");
    }
  }

  /// Return a list of overviews for [groupName].
  /// TODO Stream this information to use with an on demand list view?
  List<ThreadedOverview> overviewsFor(String groupName) {

    return [
      ThreadedOverview(1, '$groupName-1', 'from1', 'date1', 'msgId1', 'references1', 10, 1, 'xref1', []),
      ThreadedOverview(2, '$groupName-2', 'from2', 'date2', 'msgId2', 'references2', 20, 2, 'xref2', []),
      ThreadedOverview(3, '$groupName-3', 'from3', 'date3', 'msgId3', 'references3', 30, 3, 'xref3', []),
      ThreadedOverview(4, '$groupName-4', 'from4', 'date4', 'msgId4', 'references4', 40, 4, 'xref4', []),
      ThreadedOverview(5, '$groupName-5', 'from5', 'date5', 'msgId5', 'references5', 50, 5, 'xref5', []),
    ];
  }


}


