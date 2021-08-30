
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:panoply/blocs/article_bloc.dart';
import 'package:panoply/blocs/headers_bloc.dart';
import 'package:panoply/models/header.dart';
import 'package:panoply/util/article_body.dart';
import 'package:panoply/util/quoted_printable.dart';
import 'package:provider/provider.dart';

class ArticlePage extends StatefulWidget {
  final HeaderListEntry startingEntry;

  ArticlePage(this.startingEntry) : super();

  @override
  State<ArticlePage> createState() => _ArticlePageState(startingEntry);
}

enum PopupMenuAction { showHeaders}

class _ArticlePageState extends State<ArticlePage> {
  HeaderListEntry? currentHeaderEntry;
  HeaderListEntry? nextHeaderEntry;
  bool smartFormatting = true;
  bool get isCurrentRead => currentHeaderEntry?.header.isRead ?? false;
  void set isCurrentRead(bool newIsRead) {
    if (currentHeaderEntry != null) {
      currentHeaderEntry!.header.isRead = newIsRead;
    }
  }

  _ArticlePageState(this.nextHeaderEntry); // Haven't fetched it yet

  @override
  Widget build(BuildContext context) {
    _fetchNextBody(context); // If needed

    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, currentHeaderEntry);
          return false;
        },
        child: Scaffold(
            appBar: AppBar(
              actions: [
                _prevAction(),
                _nextAction(),
                _formatAction(),
                _readAction(),
                _moreActions(context),
              ],
            ),
            body: BlocBuilder<ArticleBloc, ArticleBlocState>(
                builder: (context, state) {
                  if (state is ArticleBlocFetchedState) {
                    if (_staleState(state)) {
                      // Stale state
                      return _displayLoading();
                    }
                    return ListView(
                        padding: const EdgeInsets.all(10.0),
                        //TODO Konstant or setting
                        children: [
                          _buildHeader(state.header, context),
                          Divider(),
                          _buildBody(state.body,
                              state.header.getString('content-transfer-encoding')),
                        ]
                    );
                  } else if (state is ArticleBlockInitialState) {
                    return _displayLoading();
                  } else {
                    return Center(
                        child:
                        Text("Article '${currentHeaderEntry?.header
                            .subject}' is not available")
                    );
                  }
                }
            )
        )
    );
  }

  /// If the state is not for the current article, it's stale and shouldn't
  /// be displayed.
  bool _staleState(ArticleBlocFetchedState state) {
    return state.header.msgId != currentHeaderEntry!.header.msgId;
  }

  /// Display a loading screen while we wait for article to appear.
  Widget _displayLoading() {
    return Center(child: Text("Loading ${currentHeaderEntry!.header.subject}"));
  }
  /// If the nextEntry doesn't match the current one, have the next fetched.
  void _fetchNextBody(context) {
    if (currentHeaderEntry != nextHeaderEntry) {
      currentHeaderEntry = nextHeaderEntry;
      assert(currentHeaderEntry != null);

      if (currentHeaderEntry != null) {
        Provider.of<ArticleBloc>(context, listen: false)
            .add(ArticleBlocFetchArticleEvent(currentHeaderEntry!.header));
      }
    }
  }

  Widget _prevAction() {
    return IconButton(
      icon: const Icon(Icons.navigate_before),
      onPressed: (currentHeaderEntry?.previous != null)
          ? () =>
          setState (() =>
          nextHeaderEntry = currentHeaderEntry?.previous ?? nextHeaderEntry)
          : null,
    );
  }

  Widget _nextAction() {
    return IconButton(
      icon: const Icon(Icons.navigate_next),
      onPressed: (currentHeaderEntry?.next != null)
          ? () =>
          setState (() =>
          nextHeaderEntry = currentHeaderEntry?.next ?? nextHeaderEntry)
          : null,
    );
  }

  Widget _formatAction() {
    return
      smartFormatting
          ? IconButton(
          icon: const Icon(Icons.format_align_left),
          tooltip: 'No reformatting',
          onPressed: (() {
            setState(() => smartFormatting = false);
          })
      )
          : IconButton(
          icon: const Icon(Icons.format_align_justify),
          tooltip: 'Reformat body text',
          onPressed: (() {
            setState(() => smartFormatting = true);
          })
      );
  }

  Widget _readAction() {
    return IconButton(onPressed: () {
      setState(() {
        _markArticleRead(!isCurrentRead);
      });
    },
        icon: isCurrentRead
            ? const Icon(Icons.mark_email_unread_outlined)
            : const Icon(Icons.mark_email_read_outlined)
    );
  }

  Widget _moreActions(BuildContext context) {
    return PopupMenuButton(
      onSelected: (selected) =>
          _popupMenuAction(context, selected as PopupMenuAction),
       itemBuilder: (BuildContext context) {
         return [
           const PopupMenuItem(
               child: Text('Show headers...'),
               value: PopupMenuAction.showHeaders,
               // onTap: () => _showHeadersAction(context)
           ),
         ];
       }
    );
  }

  void _popupMenuAction(BuildContext context, PopupMenuAction action) {
    switch (action) {
      case PopupMenuAction.showHeaders:
        _showHeadersAction(context);
        break;
    }
  }

  void _showHeadersAction(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            // title: Text('Header'),
            content: Stack(
                children:
                [
                  SingleChildScrollView(
                    child: Column(
                      children: (currentHeaderEntry?.header.raw ?? ["empty"])
                          .map((l) => Text(l)).toList(),
                    ),
                  ),
                  Positioned(
                    top: -4, right: -4,
                    child: IconButton(
                      alignment: Alignment.topRight,
                      padding: EdgeInsets.all(0.0),
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ),
                ]
            ),
        );
      });
  }

  void _markArticleRead(bool isRead) {
    if (currentHeaderEntry != null) {
      currentHeaderEntry!.header.isRead = isRead;
      Provider.of<HeadersBloc>(context, listen: false)
          .add(HeadersBlocHeaderChangedEvent(currentHeaderEntry!.header));
    }
  }

  Widget _buildHeader(Header header, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text(header.subject,
            style: header.isRead
                ? const TextStyle(fontWeight: FontWeight.normal)
                : const TextStyle(fontWeight: FontWeight.bold)),
        Text("From: ${header.from} on ${header.date} (${header.number})",
          style: Theme.of(context).textTheme.caption,
        )
      ],
    );
  }

  Widget _buildBody(List<String> bodyLines, String transferEncoding) {
    final lines = transferEncoding == 'quoted-printable'
        ? QuotedPrintable(bodyLines) : bodyLines;

    if (smartFormatting) {
      final body = ArticleBody('', currentHeaderEntry?.header.getString('Content-Transfer-Encoding'));
      body.build(lines.iterator);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _makeBody(body).toList(),
      );
    } else {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map( (l) => Text(l)).toList(),
      );
    }
  }

  Iterable<Widget> _makeBody(body) sync* {
    for (final p in body.nodes) {
      if (p is ArticleBodyTextLine) {
        if (p.line.isEmpty) continue; // Swallow blank lines

        yield Container(
            margin: EdgeInsets.only(left: 4.0), //TODO Konstant or setting
            child: Column (
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.line + '\n'),
                ]
            )
        );
      }
      else if (p is ArticleBodyNested) { // Nested body
        yield Container(
            margin: EdgeInsets.only(left: 3.0), //TODO Konstant or setting
            decoration: const BoxDecoration(
                border: Border(
                    left: BorderSide(width: 2.0, color: Color(0x88888888))
                )
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _makeBody(p.body).toList()
            )
        );
      }
    }
  }

  /// Combine lines of text into paragraphs that were separated by blank
  /// lines. Special handling for lines that look like they're quoted lines
  /// (start with '<') that are not combined.
  Iterable<String> buildParagraphs(List<String> lines) sync* {
    String paragraph = '';
    for (final l in lines) {
      final line = l.trim();

      if (line.startsWith('>')) { // Quoted text handle automagically
        if (paragraph.isNotEmpty) {
          yield paragraph;
        }
        yield line;
        paragraph = '';
      } else if (l.trim().isEmpty) {
        yield paragraph;
        yield '';
        paragraph = '';
      } else {
        paragraph += l.trim() + ' ';
      }
    }

    // Last fragment
    if (paragraph.isNotEmpty) {
      yield paragraph;
    }
  }

  final quotedRE = RegExp(r'^(>+).*$');


}