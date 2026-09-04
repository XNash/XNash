import 'package:flutter_test/flutter_test.dart';
import 'package:xnash_portfolio/keymap/fuzzy.dart';

void main() {
  const names = [
    'welcome.md',
    'heaplens.rs',
    'xynovim.lua',
    'xyno_scholar.dart',
    'xynorash.ps1',
    'about.md',
  ];

  test('empty query returns all', () {
    expect(fuzzyRank('', names), [0, 1, 2, 3, 4, 5]);
  });

  test('subsequence match', () {
    expect(fuzzyRank('hpl', names), [1]);
  });

  test('xyno matches three, prefix-dense first', () {
    expect(fuzzyRank('xyno', names).toSet(), {2, 3, 4});
    expect(fuzzyRank('xyno', names).first, 2);
  });

  test('case insensitive', () {
    expect(fuzzyRank('XYNO', names).toSet(), {2, 3, 4});
  });

  test('no match', () {
    expect(fuzzyRank('zzz', names), isEmpty);
  });
}
