import 'package:flutter/material.dart';

import '../data/projects.dart';
import '../state/app_state.dart';
import 'style.dart';

class TelescopeOverlay extends StatelessWidget {
  final AppState state;
  const TelescopeOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final t = state.themeController.theme;
    final results = state.finderResults;
    final selected =
        results.isEmpty ? -1 : state.finderSelection.clamp(0, results.length - 1);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: t.bgDark,
          border: Border.all(color: t.bgHighlight),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.bgHighlight)),
              ),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '> ', style: mono(t.accent, size: 13)),
                  TextSpan(text: state.finderQuery, style: mono(t.fg, size: 13)),
                  TextSpan(text: '▊', style: mono(t.accent, size: 13)),
                ]),
              ),
            ),
            for (var r = 0; r < results.length; r++)
              InkWell(
                onTap: () => state.openBuffer(results[r]),
                child: Container(
                  width: double.infinity,
                  color: r == selected ? t.bgHighlight : t.bgDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: r == selected ? '> ' : '  ',
                          style: mono(t.accent, size: 12)),
                      TextSpan(
                          text: '${kBuffers[results[r]].icon} ',
                          style: mono(t.blue, size: 12)),
                      TextSpan(
                          text: kBuffers[results[r]].fileName,
                          style: mono(
                              r == selected ? t.fg : t.fgDim, size: 12)),
                    ]),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Text('${results.length}/${kBuffers.length}',
                  style: mono(t.muted, size: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
