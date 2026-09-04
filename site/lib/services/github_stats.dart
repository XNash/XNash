import 'dart:convert';

import 'package:http/http.dart' as http;

class RepoStats {
  final int stars;
  final String pushedAt; // YYYY-MM-DD
  const RepoStats(this.stars, this.pushedAt);
}

class GithubStats {
  final http.Client _client;
  GithubStats({http.Client? client}) : _client = client ?? http.Client();

  Future<RepoStats> fetch(String repo, RepoStats fallback) async {
    try {
      final res = await _client
          .get(Uri.parse('https://api.github.com/repos/XNash/$repo'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return fallback;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final stars = body['stargazers_count'] as int;
      final pushed = (body['pushed_at'] as String).split('T').first;
      return RepoStats(stars, pushed);
    } catch (_) {
      return fallback;
    }
  }
}
