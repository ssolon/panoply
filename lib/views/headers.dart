import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:panoply/blocs/headers_bloc.dart';
import 'package:panoply/models/header.dart';
import 'package:panoply/views/fetch_criteria.dart';
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
  LinkedList<HeaderListEntry> visibleHeaders = LinkedList<HeaderListEntry>();
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
        loggy.debug("build state=$state");
        if (state is HeadersBlocLoadedState) {
          if (state.headersForGroup.groupName != groupName) { // Stale state
            return _displayLoading(groupName);
          }
          else {
            currentHeaders = state.headersForGroup;
            visibleHeaders = _makeVisibleHeaders();
            return _buildHeaderList();
          }
        }
        else if (state is HeadersBlocFetchingState) {
          return _displayFetching(groupName);
        } else if (state is HeadersBlocErrorFetchingState) {
          return _displayError('fetching headers', state);
        } else if (state is HeadersBlocFetchDoneState) {
          currentHeaders = state.headers;
          _saveCurrentHeaders(context);
          visibleHeaders = _makeVisibleHeaders();
          return _buildHeaderList();
        } else if (state is HeadersBlocLoadingState) {
          return _displayLoading(state.groupName);
        } else if (state is HeadersBlocHeaderChangedState) {
          return _buildHeaderList();
        } else if (state is HeadersBlocSavedState) {
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
        onPressed: () => _fetchHeaders(context),
        child: const Icon(Icons.download),
      ),
    );
  }

  void _fetchHeaders(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text("Fetch $groupName"),
          children: [
            FetchCriteriaView(key:fetchCriteriaViewStateKey),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.pop(context);
                    }
                ),
                TextButton(
                  child: Text("Fetch"),
                  onPressed: () => _doFetchHeadersFromViewCriteria(context),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  /// Get a criteria object from the view and have the headers fetched
  void _doFetchHeadersFromViewCriteria(BuildContext context) {
    final criteriaState = fetchCriteriaViewStateKey.currentState as CriteriaState?;
    final criteria = criteriaState?.getCriteria()
        ?? FetchCriteria(FetchOp.lastNHeaders, numberOfHeaders: 10);
    BlocProvider.of<HeadersBloc>(context, listen: false)
        .add(HeadersForGroupFetchEvent(currentHeaders.groupName, criteria));
    Navigator.pop(context);
  }

  Widget _displayError(String action, errorState) {
    return Center(
        child: Text("Error $action:${errorState.error}"),
    );
  }

  Widget _displayLoading(String groupName) {
    return Center(child: Text("Loading ${groupName}... "));
  }

  Widget _displayFetching(String groupName) {
    return Center(child: Text("Fetching headers for ${groupName}... "));
  }

  Widget _buildHeaderList() {
    return ListView(
        children: visibleHeaders
            .where( (e) => !e.header.isChild) // Only top items
            .expand((e) => _buildHeaderListItem(context, e))
            .toList());
  }

  Iterable<Widget> _buildHeaderListItem(
      BuildContext context,
      HeaderListEntry headerEntry,
      [double marginOffset = 0.0]) sync* {

    final header = headerEntry.header;

    final tile = ListTile(
      key: Key(header.msgId),
      leading: _articleIcon(header),
      title: _articleSubject(header),
      subtitle: Text("from ${header.from} at ${header.date}"),
      trailing: _articleExpander(context, headerEntry),
      selected: currentlySelectedHeader == header,
      onTap: () async {
        final selectedEntry = await Navigator.push(context,
            MaterialPageRoute(
                builder: (context) => ArticlePage(headerEntry)));

        //TODO make sure the selected entry is visible
        currentlySelectedHeader = selectedEntry?.header;

        // This will also trigger a build and display the (newly?) selected
        _saveCurrentHeaders(context); // Save any changes made by article view
      },
    );

    yield marginOffset == 0
        ? tile
        : Container(
        padding: EdgeInsets.only(left: marginOffset),
        child: tile);

    if (headerEntry.showChildren) {
      yield* header.children.expand( (h) =>
        _buildHeaderListItem(context, childEntryFor(h, headerEntry),
            marginOffset + 20.0)
      );
    }
  }

  /// Return the listEntry for [header] which should be a child of the header
  /// [parentEntry]. Since we've linearized the hierarchy it should be further
  /// down the list.
  HeaderListEntry childEntryFor(Header header, HeaderListEntry parentEntry) {
    final headerMsgId = header.msgId;
    var check = parentEntry.next;

    while (check != null) {
      if (check.header.msgId == headerMsgId) {
        return check;
      }
      check = check.next;
    }

    // Should never happen
    throw Exception("Couldn't find headerEntry for parentEntry=$parentEntry ");
  }

  Icon _articleIcon(Header header) {
    return header.isRead
        ? const Icon(Icons.mark_email_read_outlined)
        : const Icon(Icons.mark_email_unread_outlined);
  }

  Widget _articleSubject(Header header) {

    // Unread count that doesn't include this top entry. How pan does it.
    final unreadCount = _countUnread(header) - _unread(header);

    return Text(
      header.subject + ((unreadCount > 0) ? " ($unreadCount)" : ""),
      style: header.isRead
          ? const TextStyle(fontWeight: FontWeight.normal)
          : const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  int _unread(Header header) => header.isRead ? 0 : 1;

  int _countUnread(Header header) {
    return header.children.fold(
        _unread(header),
        (int prev, Header h) => prev + _countUnread(h));
  }

  Widget? _articleExpander(BuildContext context, HeaderListEntry headerEntry) {
    if (headerEntry.header.children.isEmpty) {
      return null;
    }

    return IconButton(
      onPressed: () {
        headerEntry.showChildren = !headerEntry.showChildren;
        _headerChanged(headerEntry.header);
      },
      icon: Icon(
          headerEntry.showChildren ? Icons.expand_less : Icons.expand_more
      ),
    );
  }

  void _headerChanged(Header header) {
    Provider.of<HeadersBloc>(context, listen: false)
        .add(HeadersBlocHeaderChangedEvent(header));
  }

  void _saveCurrentHeaders(BuildContext context) {
    Provider.of<HeadersBloc>(context, listen: false)
        .add(HeadersBlocSaveEvent(currentHeaders));
  }

  /// Create a linked list of headers that have been sorted, filtered, whatever
  /// and represent what should be shown on the screen and thus iterated through
  /// on the article page.
  LinkedList<HeaderListEntry> _makeVisibleHeaders() {
    final result = LinkedList<HeaderListEntry>();

    //TODO Filtering and sorting
    currentHeaders.thread(); //!!!! TODO this on loading somewhere else
    final rootHeaders = currentHeaders.headers.values.where( (h) => !h.isChild);

    _addHeaderEntries(result, rootHeaders);
    return result;
  }

  /// Linearize all the headers so we can next/previous navigate through them.
  /// The builder will have to handle the hierarchical display based on the
  /// actual header contents.
  void _addHeaderEntries(LinkedList<HeaderListEntry> l, Iterable<Header> i) {
    for (final h in i) {
      //TODO Filtering/sorting
      l.add(HeaderListEntry(h, h.isChild)); // children start shown
      if (h.children.isNotEmpty) {
        _addHeaderEntries(l, h.children);
      }
    }
  }
}

