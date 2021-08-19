import 'dart:collection';

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
  String groupName;
  HeadersForGroup currentHeaders = HeadersForGroup.empty('????');
  Header? currentlySelectedHeader;

  _HeaderListState(this.groupName);

  @override
  Widget build(BuildContext context) {
    if (currentHeaders.groupName != groupName) {
      Provider.of<HeadersBloc>(context, listen: false)
          .add(HeadersBlocLoadEvent(groupName));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group),
      ),
      body: Container(child:
          BlocBuilder<HeadersBloc, HeadersBlocState>(builder: (context, state) {
            if (state is HeadersBlocLoadedState) {
              if (state.headersForGroup.groupName != groupName) { // Stale state
                return _displayLoading(groupName);
              }
              else {
                currentHeaders = state.headersForGroup;
                return _buildHeaderList();
              }
            } else if (state is HeadersBlocFetchDoneState) {
              Provider.of<HeadersBloc>(context, listen: false)
                  .add(HeadersBlocSaveEvent(state.headers));
              currentHeaders = state.headers; // TODO Combine with above?
              return _buildHeaderList();
            } else if (state is HeadersBlocLoadingState) {
              return _displayLoading(state.groupName);
            } else if (state is HeadersBlocHeaderChangedState) {
              return _buildHeaderList();
            } else if (state is HeadersBlocSavedState) {
              //TODO Some sort of clean/dirty flag to control saving?
              return _buildHeaderList();
            } else if (state is HeadersBlocInitialState) {
              return _displayLoading(groupName);
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
              FetchCriteria(FetchOp.lastNHeaders, 30); //TODO From user input
          BlocProvider.of<HeadersBloc>(context, listen: false)
              .add(HeadersForGroupFetchEvent(currentHeaders.groupName, criteria));
        },
        child: const Icon(Icons.download),
      ),
    );
  }

  Widget _displayLoading(String groupName) {
    return Center(child: Text("Loading ${groupName}... "));
  }

  Widget _buildHeaderList() {
    final visibleHeaders = _makeVisibleHeaders();
    return ListView(
        children: visibleHeaders
            .map((e) => _buildHeaderListItem(context, e))
            .toList());
  }

  Widget _buildHeaderListItem(BuildContext context, HeaderListEntry headerEntry) {
    final header = headerEntry.header;

    return ListTile(
      leading: header.isRead
        ? const Icon(Icons.mark_email_read_outlined)
        : const Icon(Icons.mark_email_unread_outlined),
        title: Text(
          header.subject,
          style: header.isRead
              ? const TextStyle(fontWeight: FontWeight.normal)
              : const TextStyle(fontWeight: FontWeight.bold),
        ),
        selected: currentlySelectedHeader == header,
        onTap: () async {
          final selectedEntry = await Navigator.push(context,
              MaterialPageRoute(builder: (context) => Article(headerEntry)));
          setState(() {
            currentlySelectedHeader = selectedEntry?.header;
          });
        });
  }

  /// Create a linked list of headers that have been sorted, filtered, whatever
  /// and represent what should be shown on the screen and thus iterated through
  /// on the article page.
  /// TODO Threading?
  LinkedList<HeaderListEntry> _makeVisibleHeaders() {
    final result = LinkedList<HeaderListEntry>();

    //TODO Filtering and sorting
    currentHeaders.headers.values.forEach((e) => result.add(HeaderListEntry(e)));
    return result;
  }
}

