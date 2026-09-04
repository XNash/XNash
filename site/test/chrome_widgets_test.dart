import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xnash_portfolio/services/github_stats.dart';
import 'package:xnash_portfolio/state/app_state.dart';
import 'package:xnash_portfolio/theme/theme_controller.dart';
import 'package:xnash_portfolio/widgets/bufferline.dart';
import 'package:xnash_portfolio/widgets/neotree.dart';
import 'package:xnash_portfolio/widgets/statusline.dart';

AppState makeState() => AppState(
      theme: ThemeController(load: () => null, save: (_) {}),
      github: GithubStats(
          client: MockClient((_) async => http.Response('nope', 403))),
    );

Widget host(AppState s, Widget child) => MaterialApp(
      home: Scaffold(
        body: AnimatedBuilder(
          animation: s,
          builder: (_, _) => Column(children: [child]),
        ),
      ),
    );

void main() {
  testWidgets('bufferline shows tabs and switches on tap', (tester) async {
    final s = makeState();
    await tester.pumpWidget(host(s, Bufferline(state: s)));
    expect(find.text('xynovim.lua'), findsOneWidget);
    await tester.tap(find.text('heaplens.rs'));
    await tester.pump();
    expect(s.bufferIndex, 1);
  });

  testWidgets('neotree lists files and opens on tap', (tester) async {
    final s = makeState();
    await tester.pumpWidget(host(
        s, Expanded(child: NeoTree(state: s, onSelect: (_) {}))));
    final row = find.textContaining('xyno_scholar.dart', findRichText: true);
    expect(row, findsOneWidget);
    await tester.tap(row);
    await tester.pump();
    expect(s.bufferIndex, 3);
  });

  testWidgets('statusline shows mode, branch, theme', (tester) async {
    final s = makeState();
    await tester.pumpWidget(host(s, Statusline(state: s)));
    expect(find.text('NORMAL'), findsOneWidget);
    expect(find.textContaining('main'), findsOneWidget);
    expect(find.textContaining('aether'), findsOneWidget);
  });
}
