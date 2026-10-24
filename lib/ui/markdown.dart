import 'package:flutter/material.dart';

import 'theme.dart';

class MiniMarkdown extends StatelessWidget {
  const MiniMarkdown(this.text, {super.key});
  final String text;

  static List<InlineSpan> inline(String s, [TextStyle base = const TextStyle()]) {
    final out = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    var i = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > i) out.add(TextSpan(text: s.substring(i, m.start), style: base));
      if (m[1] != null) {
        out.add(TextSpan(text: m[1], style: base.copyWith(fontWeight: FontWeight.w600, color: Tx.ink)));
      } else {
        out.add(TextSpan(text: m[2], style: base.copyWith(fontStyle: FontStyle.italic)));
      }
      i = m.end;
    }
    if (i < s.length) out.add(TextSpan(text: s.substring(i), style: base));
    return out;
  }

  static Widget rich(String s, {TextStyle? style}) =>
      Text.rich(TextSpan(children: inline(s, style ?? TextStyle(height: 1.5, color: Tx.text, fontSize: 15))));

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final blocks = <Widget>[];
    final li = RegExp(r'^\s*(-|\d+\.) ');
    var i = 0;
    while (i < lines.length) {
      final l = lines[i];
      if (RegExp(r'^\s*\|').hasMatch(l)) {
        final rows = <List<String>>[];
        while (i < lines.length && RegExp(r'^\s*\|').hasMatch(lines[i])) {
          final r = lines[i++].trim();
          if (RegExp(r'^\|[\s:|-]+\|$').hasMatch(r)) continue;
          rows.add(r.replaceAll(RegExp(r'^\||\|$'), '').split('|').map((c) => c.trim()).toList());
        }
        blocks.add(_table(rows));
      } else if (li.hasMatch(l)) {
        final ordered = RegExp(r'^\s*\d').hasMatch(l);
        var n = 0;
        while (i < lines.length && li.hasMatch(lines[i])) {
          n++;
          final item = lines[i++].replaceFirst(li, '');
          blocks.add(Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 22, child: Text(ordered ? '$n.' : '•', style: TextStyle(color: Tx.muted, height: 1.5))),
              Expanded(child: rich(item)),
            ]),
          ));
        }
      } else {
        if (l.trim().isNotEmpty) {
          blocks.add(Padding(padding: const EdgeInsets.only(bottom: 10), child: rich(l)));
        }
        i++;
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }

  Widget _table(List<List<String>> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final cols = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    TableRow row(List<String> r, bool head) => TableRow(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: head ? Tx.line2 : Tx.line))),
          children: [
            for (var c = 0; c < cols; c++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: head
                    ? Text((c < r.length ? r[c] : '').toUpperCase(),
                        style: Tx.kicker.copyWith(fontSize: 10.5, letterSpacing: 0.8))
                    : rich(c < r.length ? r[c] : '', style: TextStyle(fontSize: 14, color: Tx.text, height: 1.35)),
              ),
          ],
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 300),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [row(rows.first, true), for (final r in rows.skip(1)) row(r, false)],
          ),
        ),
      ),
    );
  }
}
