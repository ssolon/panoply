import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';
import 'package:panoply/services/news_service.dart';
import 'package:provider/provider.dart';

/// A status bar for our server connection

class ServerStatus extends StatelessWidget {
  const ServerStatus( {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsService> (
      builder: (context, service, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Server: ${service.serverName}"),
            Text(" ${service.status}"),
          ],
        );
      }
    );
  }
}


