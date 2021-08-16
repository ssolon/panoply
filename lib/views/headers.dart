import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:panoply/blocs/article_bloc.dart';
import 'package:panoply/blocs/headers_bloc.dart';
import 'package:panoply/models/header.dart';
import 'package:panoply/views/server_status.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'article.dart';

class HeaderList extends StatefulWidget {
  const HeaderList({Key? key, required this.group}) : super(key: key);

  final String group;

  @override
  State<HeaderList> createState() => _HeaderListState(group);
}

class _HeaderListState extends State<HeaderList> with UiLoggy {
  String group;
  String loadedGroup = '';
  List<Header> headers = [];

  _HeaderListState(this.group);

  @override
  Widget build(BuildContext context) {
    if (group != loadedGroup) {
      Provider.of<HeadersBloc>(context).add(HeadersBlocLoadEvent(group));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group),
      ),
      body: Container(child:
          BlocBuilder<HeadersBloc, HeadersBlocState>(builder: (context, state) {
        if (state is HeadersBlocLoadedState) {
          loadedGroup = group;
          headers = state.headers;
          return _buildHeaderList();
        } else if (state is HeadersBlocLoadingState) {
          return Center(child: Text("Loading ${state.groupName}... "));
        } else if (state is HeadersBlocHeaderChangedState) {
          return _buildHeaderList();
        } else {
          return Center(child: Text("Unknown state=$state"));
        }
      })),
      bottomSheet: Container(
        padding: const EdgeInsets.all(kBodyEdgeInsets),
        child: const ServerStatus(),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Fetch headers',
        onPressed: () {
          final criteria =
              FetchCriteria(FetchOp.lastNHeaders, 10); //TODO From user input
          BlocProvider.of<HeadersBloc>(context)
              .add(HeadersForGroupFetchEvent(criteria));
        },
        child: const Icon(Icons.download),
      ),
    );
  }

  Widget _buildHeaderList() {
    return ListView(
        children: headers
            .map((i) => _buildHeaderListItem(context, i))
            .toList());
  }

  Widget _buildHeaderListItem(BuildContext context, Header header) {
    return ListTile(
        title: Text(
          header.subject,
          style: header.isRead
              ? const TextStyle(fontWeight: FontWeight.normal)
              : const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () {
          Provider.of<ArticleBloc>(context, listen: false)
              .add(ArticleBlocFetchBodyEvent(header));
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => Article(header)));
        });
  }
}
