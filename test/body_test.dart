import 'package:panoply/util/article_body.dart';
import 'package:test/test.dart';

void main() {


  group('No fill', () {
    group('Simple non-nested', () {
      test('Empty body', () {
        final l0 = List<String>.empty();
        final b0 = ArticleBody('')..fillParagraphs = false;
        b0.build(l0.iterator);

        expect(b0.nodes.length, 0);
      });

      test('One line', () {
        final l1 = ['Line1'];
        final b1 = ArticleBody('')..fillParagraphs = false;
        b1.build(l1.iterator);

        expect(b1.nodes.length, 1);
      });

      test('Two lines', () {
        final l2 = ['Line1', 'Line2'];
        final b2 = ArticleBody('')..fillParagraphs = false;
        b2.build(l2.iterator);

        expect(b2.nodes.length, 2);
        expect(b2.nodes[0].text, ['Line1']);
        expect(b2.nodes[1].text, ['Line2']);
      });

      test('Three lines', () {
        final l3 = ['Line1', 'Line2', 'Line3'];
        final b3 = ArticleBody('')..fillParagraphs = false;
        b3.build(l3.iterator);

        expect(b3.nodes.length, 3);
        expect(b3.nodes[0].text, ['Line1']);
        expect(b3.nodes[1].text, ['Line2']);
        expect(b3.nodes[2].text, ['Line3']);
      });
    });

    group('Nested', () {
      test('One nested 0', () {
        final l = ['Line1', '>nested line1'];
        final b = ArticleBody('')..fillParagraphs = false;
        b.build(l.iterator);

        expect(b.nodes.length, 2);
        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text, ['nested line1']);
      });

      test('One nested 1', () {
        final l = ['Line1', '>nested line1', 'Line2'];
        final b = ArticleBody('')..fillParagraphs = false;
        b.build(l.iterator);

        expect(b.nodes.length, 3);
        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text, ['nested line1']);
        expect(b.nodes[2].text, ['Line2']);
      });

      test('Two nested 1', () {
        final l = ['Line1', '>nested line1a', '>nested line1b', 'Line2'];
        final b = ArticleBody('')..fillParagraphs = false;
        b.build(l.iterator);

        expect(b.nodes.length, 3);
        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text, ['nested line1a', 'nested line1b']);
        expect(b.nodes[2].text, ['Line2']);
      });

      test('Three nested 1', () {
        final l = [
          'Line1',
          '>nested line1a',
          '>nested line1b',
          '>nested line1c',
          'Line2'
        ];
        final b = ArticleBody('')..fillParagraphs = false;
        b.build(l.iterator);

        expect(b.nodes.length, 3);
        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text,
            ['nested line1a', 'nested line1b', 'nested line1c']);
        expect(b.nodes[2].text, ['Line2']);
      });

      test('Three nested 2', () {
        final l = ['Line1',
          '>nested line1a', '>nested line1b', '>nested line1c',
          'Line2', '>nested 2a'];
        final b = ArticleBody('')..fillParagraphs = false;
        b.build(l.iterator);

        expect(b.nodes.length, 4);
        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text,
            ['nested line1a', 'nested line1b', 'nested line1c']);
        expect(b.nodes[2].text, ['Line2']);
        expect(b.nodes[3].text, ['nested 2a']);
      });

      test('Three nested 2 nested', () {
        final l = [
          'Line1',
          '>nested line1a',
          '>nested line1b',
          '>nested line1c',
          'Line2',
          '>nested 2a',
          '>>nested 2aa',
          '>>>nested 2aaa',
          '>>>nested 2aab',
          '>>nested 2ab',
          '>nested 2b',
          'Line 3'
        ];
        final b = ArticleBody('')..fillParagraphs = false;
        b.build(l.iterator);

        expect(b.nodes.length, 5);
        expect(b.nodes[0].runtimeType, ArticleBodyTextLine);

        expect(b.nodes[1].runtimeType, ArticleBodyNested);
        final bodysub1 = (b.nodes[1] as ArticleBodyNested).body;
        expect(bodysub1.nodes.length, 3);
        expect(bodysub1.nodes[0].runtimeType, ArticleBodyTextLine);
        expect(bodysub1.nodes[0].text, ['nested line1a']);
        expect(bodysub1.nodes[1].text, ['nested line1b']);
        expect(bodysub1.nodes[2].text, ['nested line1c']);

        expect(b.nodes[2].runtimeType, ArticleBodyTextLine);

        expect(b.nodes[3].runtimeType, ArticleBodyNested);
        final bodysub2 = (b.nodes[3] as ArticleBodyNested).body;
        expect(bodysub2.nodes.length, 3);
        expect(bodysub2.nodes[0].runtimeType, ArticleBodyTextLine);
        expect(bodysub2.nodes[0].text, ['nested 2a']);
        expect(bodysub2.nodes[1].runtimeType, ArticleBodyNested);
        expect(bodysub2.nodes[2].text, ['nested 2b']);

        final bodysub3 = (bodysub2.nodes[1] as ArticleBodyNested).body;
        expect(bodysub3.nodes.length, 3);
        expect(bodysub3.nodes[0].runtimeType, ArticleBodyTextLine);
        expect(bodysub3.nodes[0].text, ['nested 2aa']);
        expect(bodysub3.nodes[1].runtimeType, ArticleBodyNested);
        expect(bodysub3.nodes[2].runtimeType, ArticleBodyTextLine);
        expect(bodysub3.nodes[2].text, ['nested 2ab']);

        final bodysub4 = (bodysub3.nodes[1] as ArticleBodyNested).body;
        expect(bodysub4.nodes.length, 2);
        expect(bodysub4.nodes[0].runtimeType, ArticleBodyTextLine);
        expect(bodysub4.nodes[0].text, ['nested 2aaa']);
        expect(bodysub4.nodes[1].runtimeType, ArticleBodyTextLine);
        expect(bodysub4.nodes[1].text, ['nested 2aab']);

        expect(b.nodes[4].runtimeType, ArticleBodyTextLine);

        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text,
            ['nested line1a', 'nested line1b', 'nested line1c']);
        expect(b.nodes[2].text, ['Line2']);
        // expect(b.nodes[3].text, ['nested 2a']);
      });
    });
  });

  group('Fill paragraphs (default)', () {
    group('Simple non-nested', () {
      test('Empty body', () {
        final l0 = List<String>.empty();
        final b0 = ArticleBody('');
        b0.build(l0.iterator);

        expect(b0.nodes.length, 0);
      });

      test('One line', () {
        final l1 = ['Line1'];
        final b1 = ArticleBody('');
        b1.build(l1.iterator);

        expect(b1.nodes.length, 1);
      });

      test('Two lines', () {
        final l2 = ['Line1', 'Line2'];
        final b2 = ArticleBody('');
        b2.build(l2.iterator);

        expect(b2.nodes.length, 1);
        expect(b2.nodes[0].text, ['Line1 Line2']);
      });

      test('Three lines', () {
        final l3 = ['Line1', 'Line2', 'Line3'];
        final b3 = ArticleBody('');
        b3.build(l3.iterator);

        expect(b3.nodes.length, 1);
        expect(b3.nodes[0].text, ['Line1 Line2 Line3']);
      });
    });

    group('Nested', () {
      test('One nested 0', () {
        final l = ['Line1', '>nested line1'];
        final b = ArticleBody('');
        b.build(l.iterator);

        expect(b.nodes.length, 2);
        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text, ['nested line1']);
      });

      test('One nested 1', () {
        final l = ['Line1', '>nested line1', 'Line2'];
        final b = ArticleBody('');
        b.build(l.iterator);

        expect(b.nodes.length, 3);
        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text, ['nested line1']);
        expect(b.nodes[2].text, ['Line2']);
      });

      test('Two nested 1', () {
        final l = ['Line1', '>nested line1a', '>nested line1b', 'Line2'];
        final b = ArticleBody('');
        b.build(l.iterator);

        expect(b.nodes.length, 3);
        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text, ['nested line1a nested line1b']);
        expect(b.nodes[2].text, ['Line2']);
      });

      test('Three nested 1', () {
        final l = [
          'Line1',
          '>nested line1a',
          '>nested line1b',
          '>nested line1c',
          'Line2'
        ];
        final b = ArticleBody('');
        b.build(l.iterator);

        expect(b.nodes.length, 3);
        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text, ['nested line1a nested line1b nested line1c']);
        expect(b.nodes[2].text, ['Line2']);
      });

      test('Three nested 2', () {
        final l = ['Line1',
          '>nested line1a', '>nested line1b', '>nested line1c',
          'Line2', '>nested 2a'];
        final b = ArticleBody('');
        b.build(l.iterator);

        expect(b.nodes.length, 4);
        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text,
            ['nested line1a nested line1b nested line1c']);
        expect(b.nodes[2].text, ['Line2']);
        expect(b.nodes[3].text, ['nested 2a']);
      });

      test('Three nested 2 nested', () {
        final l = [
          'Line1',
          '>nested line1a',
          '>nested line1b',
          '>nested line1c',
          'Line2',
          '>nested 2a',
          '>>nested 2aa',
          '>>>nested 2aaa',
          '>>>nested 2aab',
          '>>nested 2ab',
          '>nested 2b',
          'Line 3'
        ];
        final b = ArticleBody('');
        b.build(l.iterator);

        expect(b.nodes.length, 5);
        expect(b.nodes[0].runtimeType, ArticleBodyTextLine);

        expect(b.nodes[1].runtimeType, ArticleBodyNested);
        final bodysub1 = (b.nodes[1] as ArticleBodyNested).body;
        expect(bodysub1.nodes.length, 1);
        expect(bodysub1.nodes[0].runtimeType, ArticleBodyTextLine);
        expect(bodysub1.nodes[0].text, ['nested line1a nested line1b nested line1c']);

        expect(b.nodes[2].runtimeType, ArticleBodyTextLine);

        expect(b.nodes[3].runtimeType, ArticleBodyNested);
        final bodysub2 = (b.nodes[3] as ArticleBodyNested).body;
        expect(bodysub2.nodes.length, 3);
        expect(bodysub2.nodes[0].runtimeType, ArticleBodyTextLine);
        expect(bodysub2.nodes[0].text, ['nested 2a']);
        expect(bodysub2.nodes[1].runtimeType, ArticleBodyNested);
        expect(bodysub2.nodes[2].text, ['nested 2b']);

        final bodysub3 = (bodysub2.nodes[1] as ArticleBodyNested).body;
        expect(bodysub3.nodes.length, 3);
        expect(bodysub3.nodes[0].runtimeType, ArticleBodyTextLine);
        expect(bodysub3.nodes[0].text, ['nested 2aa']);
        expect(bodysub3.nodes[1].runtimeType, ArticleBodyNested);
        expect(bodysub3.nodes[2].runtimeType, ArticleBodyTextLine);
        expect(bodysub3.nodes[2].text, ['nested 2ab']);

        final bodysub4 = (bodysub3.nodes[1] as ArticleBodyNested).body;
        expect(bodysub4.nodes.length, 1);
        expect(bodysub4.nodes[0].runtimeType, ArticleBodyTextLine);
        expect(bodysub4.nodes[0].text, ['nested 2aaa nested 2aab']);

        expect(b.nodes[4].runtimeType, ArticleBodyTextLine);

        expect(b.nodes[0].text, ['Line1']);
        expect(b.nodes[1].text, ['nested line1a nested line1b nested line1c']);
        expect(b.nodes[2].text, ['Line2']);
      });
    });

    group('Leading space asIs', () {
      test("No nesting", () {
        final l = ['Line1', ' As is 1', '', 'Line2', 'Line 3', ' As is 2', '\tAs is 3', '', 'Line4'];
        final b = ArticleBody('')..leadingSpaceAsIs = true;
        b.build(l.iterator);

        expect(b.nodes.length, 6);
      });

      test("Nesting", () {
        final l = ['Line1', ' As is 1', '', 'Line2', 'Line3',
          '>subLine3', '> As is 2', '>\tAs is 3', '', 'Line4'];
        final b = ArticleBody('')..leadingSpaceAsIs = true;
        b.build(l.iterator);

        expect(b.nodes.length, 5);

        expect(b.nodes[0].runtimeType, ArticleBodyTextLine);
        expect(b.nodes[0].text, ['Line1']);

        expect(b.nodes[1].runtimeType, ArticleBodyTextLine);
        expect(b.nodes[1].text, [' As is 1']);

        expect(b.nodes[2].runtimeType, ArticleBodyTextLine);
        expect(b.nodes[2].text, ['Line2 Line3']);

        final b3 = (b.nodes[3] as ArticleBodyNested).body;
        expect(b3.nodes.length, 3);
        expect(b3.nodes[0].text, ['subLine3']);
        expect(b3.nodes[1].text, [' As is 2']);
        expect(b3.nodes[2].text, ['\tAs is 3']);

        expect(b.nodes[4].runtimeType, ArticleBodyTextLine);
        expect(b.nodes[4].text, ['Line4']);
      });

    });
  });
}