import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:panoply/blocs/overviews_bloc.dart';
import 'package:panoply/services/news_service.dart';
import 'package:panoply/views/server_status.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class HeaderList extends StatefulWidget {
  const HeaderList({Key? key, required this.group}) : super(key: key);

  final String group;

  @override
  State<HeaderList> createState() => _HeaderListState(group);
}

class _HeaderListState extends State<HeaderList> with UiLoggy {
  String group;

  _HeaderListState(this.group);

  @override
  Widget build(BuildContext context) {
    // var service = Provider.of<NewsService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group),
      ),
      body: Container(
      child: BlocBuilder<OverviewsBloc, OverviewsBlocState>(
          builder: (context, state) {
            if (state is OverviewsBlocLoadedState) {
              return ListView(
                  children: state.overviews
                      .map((i) => _buildOverviewListItem(context, i))
                      .toList(growable: false)
              );
            } else {
              return Center(child: Text("Loading... ($state)"));
            }
          })
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(kBodyEdgeInsets),
        child: const ServerStatus(),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Fetch headers',
        onPressed: () {  },
        child: const Icon(Icons.download),
      ),
    );
  }

  Widget _buildOverviewListItem(context, overviewItem) {
    return ListTile (
      title: Text(overviewItem.subject),
    );
  }
}
