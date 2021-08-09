import 'package:flutter/foundation.dart';
import 'package:panoply/services/nntp_server.dart';

///
/// Communicate with NNTP server and handle the actual news logic.
///

class NewsService extends ChangeNotifier {

  NntpServer? primaryServer;
  String status = 'status';

  String get serverName => primaryServer?.name ?? '????';

  NewsService(this.primaryServer);


}