import 'package:flutter/material.dart';

import '../core/util.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'exercise_view.dart';

class Practice extends StatefulWidget {
  const Practice({
    super.key,
    required this.exercises,
    this.input,
    this.exam = false,
    this.optional = false,
    this.onFinished,
    this.onProgress,
  });
  final List<Json> exercises;
  final Json? input;
  final bool exam, optional;
  final void Function(double score, int total, List<double?> results)? onFinished;
  final void Function(double score, int answered)? onProgress;

  @override
  State<Practice> createState() => PracticeState();
}

class PracticeState extends State<Practice> {
  static const wide = {'matching', 'categorize', 'roleplay', 'writing', 'pronunciation'};
  late List<double?> results;
  int round = 0;

  @override
  void initState() {
    super.initState();
    results = List<double?>.filled(widget.exercises.length, null);
  }

  double get score => results.fold(0.0, (a, r) => a + (r ?? 0.0));
  int get answered => results.where((r) => r != null).length;

  void restart() => setState(() {
        round++;
        results = List<double?>.filled(widget.exercises.length, null);
        widget.onProgress?.call(0, 0);
      });

  Widget _card(int i) {
    final e = widget.exercises[i];
    return CardBox(
      borderColor: results[i] == null ? Tx.line : Tx.line2,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NumberDot(i + 1),
        const SizedBox(width: 12),
        Expanded(
          child: ExerciseView(
            key: ValueKey('$round-$i'),
            ex: e,
            input: widget.input,
            exam: widget.exam,
            optional: widget.optional,
            onDone: (s) {
              if (results[i] != null) return;
              setState(() => results[i] = s);
              widget.onProgress?.call(score, answered);
              if (answered == results.length) widget.onFinished?.call(score, results.length, results);
            },
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.exercises.length;
    return LayoutBuilder(builder: (context, box) {
      final two = box.maxWidth >= 720;
      final half = (box.maxWidth - 12) / 2;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!widget.optional) ...[
          ScorePanel(score: score, total: n, answered: answered, onRestart: restart),
          const SizedBox(height: 14),
        ],
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (var i = 0; i < n; i++)
            SizedBox(
              width: two && !wide.contains(widget.exercises[i]['type']) ? half : box.maxWidth,
              child: _card(i),
            ),
        ]),
      ]);
    });
  }
}
