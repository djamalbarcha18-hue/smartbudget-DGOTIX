/// A deliberately small Markdown reader for AI answers (pure Dart, no deps):
/// headings, "- " / "* " / "• " bullets, "1." / "1)" numbered items, bold
/// (`**x**` or `__x__`) and inline `code` (shown as plain text). Everything
/// else is plain text — never raw symbols on screen.
library;

enum MdBlockType { paragraph, heading, bullet, numbered }

class MdSpan {
  const MdSpan(this.text, {this.bold = false});
  final String text;
  final bool bold;
}

class MdBlock {
  const MdBlock(this.type, this.spans, {this.marker = '', this.raw = ''});
  final MdBlockType type;
  final List<MdSpan> spans;

  /// "1." for numbered items; empty otherwise.
  final String marker;

  /// The block's plain text (used to pick its reading direction).
  final String raw;

  /// The visible text without the invisible direction isolates.
  String get plainText => spans
      .map((MdSpan s) => s.text)
      .join()
      .replaceAll(RegExp('[\u2066\u2069]'), '');
}

abstract final class MarkdownLite {
  static final RegExp _heading = RegExp(r'^\s{0,3}#{1,6}\s+(.*)$');
  static final RegExp _bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
  static final RegExp _numbered = RegExp(r'^\s*(\d{1,3})[.)]\s+(.*)$');
  static final RegExp _bold = RegExp(r'\*\*(.+?)\*\*|__(.+?)__');

  static List<MdBlock> parse(String source) {
    final List<MdBlock> out = <MdBlock>[];
    final List<String> para = <String>[];

    void flush() {
      if (para.isEmpty) return;
      final String text = para.join('\n');
      out.add(MdBlock(MdBlockType.paragraph, inline(text), raw: text));
      para.clear();
    }

    for (final String rawLine in source.replaceAll('\r\n', '\n').split('\n')) {
      final String line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        flush();
        continue;
      }
      final RegExpMatch? h = _heading.firstMatch(line);
      final RegExpMatch? b = _bullet.firstMatch(line);
      final RegExpMatch? n = _numbered.firstMatch(line);
      if (h != null) {
        flush();
        final String t = h.group(1)!.trim();
        out.add(MdBlock(MdBlockType.heading, inline(t), raw: t));
      } else if (b != null) {
        flush();
        final String t = b.group(1)!.trim();
        out.add(MdBlock(MdBlockType.bullet, inline(t), raw: t));
      } else if (n != null) {
        flush();
        final String t = n.group(2)!.trim();
        out.add(MdBlock(MdBlockType.numbered, inline(t),
            marker: '${n.group(1)}.', raw: t));
      } else {
        para.add(line.trim());
      }
    }
    flush();
    return out;
  }

  /// Inline formatting: bold runs become bold spans; code backticks and
  /// stray emphasis markers are dropped.
  static List<MdSpan> inline(String text) {
    final List<MdSpan> spans = <MdSpan>[];
    int i = 0;
    for (final RegExpMatch m in _bold.allMatches(text)) {
      if (m.start > i) spans.add(MdSpan(_clean(text.substring(i, m.start))));
      spans.add(MdSpan(_clean(m.group(1) ?? m.group(2) ?? ''), bold: true));
      i = m.end;
    }
    if (i < text.length) spans.add(MdSpan(_clean(text.substring(i))));
    return spans.where((MdSpan s) => s.text.isNotEmpty).toList();
  }

  // A figure with its unit: "$ 2,047", "10%", "96 %", "1,234.50".
  static final RegExp _figure =
      RegExp(r'(\$\s?)?\d[\d,.]*(\s?%)?');

  /// Drops code backticks and wraps every figure in a left-to-right isolate,
  /// so "10%" or "$ 2,047" keep their order inside an Arabic sentence.
  static String _clean(String s) => s
      .replaceAll('`', '')
      .replaceAllMapped(_figure, (Match m) => '\u2066${m[0]}\u2069');

  /// True when the first strong (letter) character is Arabic/Hebrew, so each
  /// paragraph of a mixed-language answer reads in its own direction.
  static bool isRtl(String text) {
    for (final int r in text.runes) {
      if ((r >= 0x0590 && r <= 0x08FF) || (r >= 0xFB1D && r <= 0xFEFC)) {
        return true;
      }
      if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) return false;
    }
    return false;
  }
}
