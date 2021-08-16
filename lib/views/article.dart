
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:panoply/blocs/article_bloc.dart';
import 'package:panoply/blocs/headers_bloc.dart';
import 'package:panoply/models/header.dart';
import 'package:panoply/util/article_body.dart';
import 'package:provider/provider.dart';

class Article extends StatefulWidget {
  final Header header;

  Article(this.header) : super(key: Key(header.msgId));

  @override
  State<Article> createState() => _ArticleState(header);
}

class _ArticleState extends State<Article> {
  final Header header;

  _ArticleState(this.header);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () {
            setState(() {
              _markArticleRead(!header.isRead);
            });
          },
              icon: header.isRead
                  ? const Icon(Icons.markunread_outlined)
                  : const Icon(Icons.mark_email_read_outlined)
          ),
        ],
      ),
      body: BlocBuilder<ArticleBloc, ArticleBlocState>(
          builder: (context, state) {
            if (state is ArticleBlocFetchedState) {
              return ListView(
                  padding: const EdgeInsets.all(10.0), //TODO Konstant or setting
                  children: [
                    _buildHeader(state.header, context),
                    Divider(),
                    _buildBody(state.body),
                  ]
              );
            } else {
              return Center(
                  child:
                  Text("Article '${header.subject}' is not available")
              );
            }
          }
        )
      );
  }

  void _markArticleRead(bool isRead) {
    header.isRead = isRead;
    Provider.of<HeadersBloc>(context, listen: false)
        .add(HeadersBlocHeaderChangedEvent(header));
  }

  Widget _buildHeader(Header header, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text(header.subject,
            style: header.isRead
                ? const TextStyle(fontWeight: FontWeight.normal)
                : const TextStyle(fontWeight: FontWeight.bold)),
        Text("From: ${header.from} on ${header.date}",
          style: Theme.of(context).textTheme.caption,
        )
      ],
    );
  }

  Widget _buildBody(bodyLines) {
    final body = ArticleBody('')..fillParagraphs=true;
    body.build(bodyLines.iterator);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _makeBody(body).toList(),
    );
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