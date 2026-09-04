import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xnash_portfolio/services/github_stats.dart';
import 'package:xnash_portfolio/state/app_state.dart';
import 'package:xnash_portfolio/theme/theme_controller.dart';
import 'package:xnash_portfolio/widgets/dashboard.dart';

AppState makeState() => AppState(
      theme: ThemeController(load: () => null, save: (_) {}),
      github: GithubStats(
          client: MockClient((_) async => http.Response('nope', 403))),
    );

void main() {
  testWidgets('dashboard lists project entries and opens them',
      (tester) async {
    final s = makeState();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AnimatedBuilder(
          animation: s,
          builder: (_, _) => Dashboard(state: s),
        ),
      ),
    ));
    expect(find.text('heaplens.rs'), findsOneWidget);
    expect(find.text('find project'), findsOneWidget);
    await tester.tap(find.text('xynovim.lua'));
    await tester.pump();
    expect(s.bufferIndex, 2);
  });

  test('welcome-buffer shortcuts: digits, a, t', () {
    final s = makeState();
    s.handleKey('2');
    expect(s.bufferIndex, 2);
    s.openBuffer(0);
    s.handleKey('a');
    expect(s.buffer.fileName, 'about.md');
    s.openBuffer(0);
    s.handleKey('t');
    expect(s.themeController.name, isNot('aether'));
  });
}
