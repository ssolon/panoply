
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:panoply/blocs/article_bloc.dart';
import 'package:panoply/models/header.dart';

class Article extends StatelessWidget {
  final Header header;

  Article(this.header) : super(key:Key(header.msgId)) ;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
      ),
      body: BlocBuilder<ArticleBloc, ArticleBlocState>(
          builder: (context, state) {
            if (state is ArticleBlocFetchedState) {
              return ListView(
                  children: [
                    _buildHeader(state.header),
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

  Widget _buildHeader(header) {
    return Container(
        child:Text(header.subject),
    );
  }

  Widget _buildBody(body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _makeBody(body).toList(),
    );
  }

  Iterable<Widget> _makeBody(List<String> body) sync* {
    for (final p in buildParagraphs(body)) {
      yield Text(p);
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
}