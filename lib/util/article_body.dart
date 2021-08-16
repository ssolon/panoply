/// Utilities for displaying body text as possibly nested paragraphs.

abstract class BodyNode {
  List<String> get text;
}

/// Body of text which holds a list of [BodyNode] in [nodes] and knows
/// how to build itself from an iterable of prefixed (with prefix '>')
/// String from [lines].
class ArticleBody {
  /// The prefix for all the nodes in this body
  final String prefix;

  /// When true lines between line breaks (by default blank lines) will
  /// be joined into a single line of text.
  /// Default: true
  bool fillParagraphs = true;

  /// When true a line with leaving white space (space or tab) will cause a line
  /// break.
  /// Default: false
  bool leadingSpaceAsIs = false;

  List<BodyNode> nodes = [];
  RegExp get prefixRe => RegExp(r'^(>*)(.*)$');

  /// Create a body of text prefixed by [prefix]. Top level should usually
  /// have a prefix of ''.
  ArticleBody(this.prefix);

  String? build(Iterator<String> lines,[String? reprocessLine]) {
    var currentLine = reprocessLine;

    while (true) {

      // Reprocess line, get next line or we're done

      if (currentLine == null) { // need another line

        if (!lines.moveNext()) {
          return null; // Done!
        }
        else {
          currentLine = lines.current;
        }
      }

      final prefixMatch = prefixRe.firstMatch(currentLine);
      assert(prefixMatch != null);
      final currentPrefix = prefixMatch?.group(1) ?? '';
      final prefixCompare = prefix.compareTo(currentPrefix);

      if (prefixCompare > 0) { // higher up -- have parent reprocess
        return currentLine;
      } else if (prefixCompare == 0) { // at this level
        addLine(prefixMatch?.group(2) ?? '');
        currentLine = null;
      } else { // deeper down - new body
        final sub = ArticleBodyNested(ArticleBody(currentPrefix)
          ..fillParagraphs = fillParagraphs
          ..leadingSpaceAsIs = leadingSpaceAsIs);
        nodes.add(sub);
        currentLine = sub.body.build(lines, currentLine);
      }
    }
  }

  /// Fill text to make paragraphs separated by either blank lines,
  /// or lines starting with whitespace ([leadingSpaceAsIs true]).
  ///
  void addLine(String line) {
    if (!fillParagraphs) {
      nodes.add(ArticleBodyTextLine(line));
      return; // no further processing needed
    }

    final bool hasLeadingWhitespace = line.startsWith(' ')||line.startsWith('\t');
    final bool lineIsEmpty = line.trim().isEmpty;
    final bool noNodes = nodes.isEmpty;
    final bool currentNodeIsBody = noNodes ? false : nodes.last is ArticleBodyNested;

    final bool needNewLine = noNodes || currentNodeIsBody;
    final bool asIsLine = (hasLeadingWhitespace && leadingSpaceAsIs);

    final bool breakLine = asIsLine || lineIsEmpty;

    if (needNewLine || breakLine) {
      nodes.add(ArticleBodyTextLine(line));

      // if (asIsLine) {
      //   nodes.add(BodyTextLine('')); // should be it's own line
      // }
    } else { // fill current line
      (nodes.last as ArticleBodyTextLine).add(line);
    }
  }

  List<String> get text {
    return nodes.fold(<String>[], (List<String> prev, node) {
      prev.addAll(node.text);
      return prev;
    });
  }
}

/// Node holding a single chunk of text. Will be a paragraph if
/// [fillParagraphs] is true.
class ArticleBodyTextLine extends BodyNode {
  String line;

  ArticleBodyTextLine(this.line);

  String add(String l) => line += line.isEmpty ? l : (' ' + l);

  List<String> get text => [line];
}

/// Body nested in another body. Always causes a break.
class ArticleBodyNested extends BodyNode {
  final ArticleBody body;

  List<String> get text => body.text;

  ArticleBodyNested(this.body);
}
