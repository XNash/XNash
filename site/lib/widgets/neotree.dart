import 'package:flutter/material.dart';

import '../data/projects.dart';
import '../state/app_state.dart';
import 'style.dart';

class NeoTree extends StatelessWidget {
  final AppState state;
  final void Function(int index) onSelect;
  const NeoTree({super.key, required this.state, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = state.themeController.theme;
    return Container(
      width: 240,
      color: t.bgDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text('\u{f07b}  ~/projects',
                style: mono(t.fgDim, size: 12, weight: FontWeight.w700)),
          ),
          ...List.generate(kBuffers.length, (i) {
            final b = kBuffers[i];
            final active = i == state.bufferIndex;
            final connector = i == kBuffers.length - 1 ? '└─' : '├─';
            return InkWell(
              hoverColor: t.bgHighlight,
              onTap: () {
                state.openBuffer(i);
                onSelect(i);
              },
              child: Container(
                width: double.infinity,
                color: active ? t.bgHighlight : t.bgDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '$connector ', style: mono(t.muted, size: 12)),
                    TextSpan(
                        text: '${b.icon} ',
                        style: mono(active ? t.accent : t.blue, size: 12)),
                    TextSpan(
                        text: b.fileName,
                        style: mono(active ? t.accent : t.fg, size: 12)),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
