import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'style.dart';

class Statusline extends StatelessWidget {
  final AppState state;
  const Statusline({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final t = state.themeController.theme;
    final total = state.buffer.lines.length;
    final line = state.scrollLines + 1;
    final pct = total <= 1 ? 100 : ((line / total) * 100).round();
    return Container(
      color: t.bgHighlight,
      height: 26,
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          Container(
            color: t.accent,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: Text('NORMAL',
                style: mono(t.bgDark, size: 11, weight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Text('\u{e725} main', style: mono(t.fgDim, size: 11)),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              '${state.buffer.icon} ${state.buffer.fileName}',
              style: mono(t.fg, size: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Text('\u{f043b} ${state.themeController.name}',
              style: mono(t.purple, size: 11)),
          const SizedBox(width: 14),
          Text('☰ $line:1', style: mono(t.fgDim, size: 11)),
          const SizedBox(width: 10),
          Text('$pct%', style: mono(t.fgDim, size: 11)),
        ],
      ),
    );
  }
}
