import 'package:flutter/material.dart';

import '../data/projects.dart';
import '../state/app_state.dart';
import 'style.dart';

class Bufferline extends StatelessWidget {
  final AppState state;
  final bool showExplorerToggle;
  const Bufferline(
      {super.key, required this.state, this.showExplorerToggle = false});

  @override
  Widget build(BuildContext context) {
    final t = state.themeController.theme;
    return Container(
      color: t.bgDark,
      height: 34,
      child: Row(
        children: [
          if (showExplorerToggle)
            InkWell(
              onTap: state.toggleExplorer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('\u{f0c9}', style: mono(t.fgDim, size: 14)),
              ),
            ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: kBuffers.length,
              itemBuilder: (_, i) {
                final b = kBuffers[i];
                final active = i == state.bufferIndex;
                return InkWell(
                  onTap: () => state.openBuffer(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: active ? t.bg : t.bgDark,
                      border: Border(
                        top: BorderSide(
                          color: active ? t.accent : t.bgDark,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(b.icon,
                            style: mono(active ? t.blue : t.muted, size: 12)),
                        const SizedBox(width: 6),
                        Text(b.fileName,
                            style: mono(active ? t.fg : t.muted, size: 12)),
                        if (active) ...[
                          const SizedBox(width: 6),
                          Text('●', style: mono(t.accent, size: 8)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
