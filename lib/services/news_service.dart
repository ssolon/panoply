import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:panoply/models/overview.dart';
import 'package:panoply/services/nntp_server.dart';

///
/// Communicate with NNTP server and handle the actual news logic.
///

abstract class NewsServiceEvent {}

class OverviewsForRequested extends NewsServiceEvent {
  final String groupName;
  OverviewsForRequested(this.groupName);
}

abstract class NewsServiceState {}

/// Initial state
class NewsServiceInitialState extends NewsServiceState {}

class NewsServiceStartLoadingOverviewsState extends NewsServiceState {
  final String groupName;
  NewsServiceStartLoadingOverviewsState(this.groupName);
}

class NewsServiceDoneLoadingOverviewsState extends NewsServiceState {
  final String groupName;
  final NntpServer server;
  final int count;
  final List<ThreadedOverview> overViews;

  NewsServiceDoneLoadingOverviewsState(
      this.groupName,
      this.server,
      this.count,
      this.overViews);
}

class NewsService extends Bloc<NewsServiceEvent, NewsServiceState> {

  NntpServer? primaryServer;
  /// Current status of this service which can be used for a status indicator.
  /// Changes will be cause a notify event.
  String status = 'status';

  /// Name of the currently active server (if any).
  String get serverName => primaryServer?.name ?? '????';

  /// CTOR

  NewsService(this.primaryServer) : super(NewsServiceInitialState());

   @override
  Stream<NewsServiceState> mapEventToState(NewsServiceEvent event) async* {
    // throw UnimplementedError();
  }
}