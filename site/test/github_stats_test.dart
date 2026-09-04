import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xnash_portfolio/services/github_stats.dart';

const fb = RepoStats(1, '2026-01-01');

void main() {
  test('parses stars and pushed date', () async {
    final svc = GithubStats(client: MockClient((req) async {
      expect(req.url.toString(), 'https://api.github.com/repos/XNash/heaplens');
      return http.Response(
        jsonEncode({'stargazers_count': 7, 'pushed_at': '2026-07-28T08:02:34Z'}),
        200,
      );
    }));
    final s = await svc.fetch('heaplens', fb);
    expect(s.stars, 7);
    expect(s.pushedAt, '2026-07-28');
  });

  test('falls back on 403', () async {
    final svc = GithubStats(
        client: MockClient((_) async => http.Response('rate limited', 403)));
    final s = await svc.fetch('heaplens', fb);
    expect(s.stars, fb.stars);
    expect(s.pushedAt, fb.pushedAt);
  });

  test('falls back on garbage body', () async {
    final svc = GithubStats(
        client: MockClient((_) async => http.Response('<html>', 200)));
    final s = await svc.fetch('heaplens', fb);
    expect(s.stars, fb.stars);
    expect(s.pushedAt, fb.pushedAt);
  });
}
