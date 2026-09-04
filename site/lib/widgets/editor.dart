import 'dart:async';

import 'package:flutter/material.dart';

import '../models/project.dart';
import '../platform/web_io.dart' as io;
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'style.dart';

const double kLineExtent = 22;

class EditorPane extends StatefulWidget {
  final AppState state;
  const EditorPane({super.key, required this.state});

  @override
  State<EditorPane> createState() => _EditorPaneState();
}

class _EditorPaneState extends State<EditorPane> {
  final _scroll = ScrollController();
  int _lastLine = 0;
  int _lastBuffer = 0;
  bool _cursorOn = true;
  Timer? _blink;

  @override
  void initState() {
    super.initState();
    _lastBuffer = widget.state.bufferIndex;
    _lastLine = widget.state.scrollLines;
    widget.state.addListener(_onState);
    _blink = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _cursorOn = !_cursorOn);
    });
  }

  @override
  void dispose() {
    _blink?.cancel();
    widget.state.removeListener(_onState);
    _scroll.dispose();
    super.dispose();
  }

  void _onState() {
    final s = widget.state;
    if (!_scroll.hasClients) return;
    if (s.bufferIndex != _lastBuffer) {
      _lastBuffer = s.bufferIndex;
      _lastLine = s.scrollLines;
      _scroll.jumpTo(0);
      return;
    }
    if (s.scrollLines != _lastLine) {
      _lastLine = s.scrollLines;
      final target = (s.scrollLines * kLineExtent)
          .clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
    }
  }

  TextStyle _tokStyle(Tok tok, AppTheme t) => switch (tok) {
        Tok.comment => mono(t.muted, style: FontStyle.italic),
        Tok.keyword => mono(t.purple),
        Tok.string => mono(t.green),
        Tok.fn => mono(t.blue),
        Tok.type => mono(t.yellow),
        Tok.plain => mono(t.fg),
        Tok.punct => mono(t.fgDim),
        Tok.heading => mono(t.accent, weight: FontWeight.w700),
        Tok.link => mono(t.cyan, decoration: TextDecoration.underline),
      };

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final t = s.themeController.theme;
    final b = s.buffer;

    final lines = [...b.lines];
    if (b.repo != null) {
      final stats = s.stats[b.repo];
      final stars = stats?.stars ?? b.fallbackStars;
      final pushed = stats?.pushedAt ?? b.fallbackPushed;
      lines.add(const CodeLine([Span(' ', Tok.plain)]));
      lines.add(CodeLine([
        Span('★ $stars', Tok.type),
        Span(' · last push $pushed', Tok.comment),
      ]));
    }
    const tildes = 8;

    return Container(
      color: t.bg,
      child: ListView.builder(
        controller: _scroll,
        itemExtent: kLineExtent,
        itemCount: lines.length + tildes,
        itemBuilder: (_, i) {
          if (i >= lines.length) {
            return Row(children: [
              SizedBox(
                width: 56,
                child: Text('~  ',
                    textAlign: TextAlign.right, style: mono(t.lineNr)),
              ),
            ]);
          }
          final line = lines[i];
          final isCursorLine = i == s.scrollLines;
          return Container(
            color: isCursorLine
                ? t.bgHighlight.withValues(alpha: 0.55)
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 56,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text('${i + 1}',
                        textAlign: TextAlign.right,
                        style: mono(isCursorLine ? t.accent : t.lineNr)),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        for (final span in line.spans)
                          span.url == null
                              ? TextSpan(
                                  text: span.text,
                                  style: _tokStyle(span.tok, t))
                              : WidgetSpan(
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => io.openUrl(span.url!),
                                      child: Text(span.text,
                                          style: _tokStyle(span.tok, t)),
                                    ),
                                  ),
                                ),
                        if (isCursorLine)
                          TextSpan(
                            text: '▊',
                            style: mono(t.fg.withValues(
                                alpha: _cursorOn ? 0.9 : 0.0)),
                          ),
                      ],
                    ),
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
