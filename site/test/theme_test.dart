import 'package:flutter_test/flutter_test.dart';
import 'package:xnash_portfolio/theme/theme_controller.dart';
import 'package:xnash_portfolio/theme/themes.dart';

void main() {
  test('defaults to aether', () {
    expect(ThemeController(load: () => null, save: (_) {}).name, 'aether');
  });

  test('restores persisted theme, ignores garbage', () {
    expect(ThemeController(load: () => 'hackerman', save: (_) {}).name,
        'hackerman');
    expect(ThemeController(load: () => 'nope', save: (_) {}).name, 'aether');
  });

  test('setTheme persists and notifies', () {
    String? saved;
    final c = ThemeController(load: () => null, save: (v) => saved = v);
    var notified = false;
    c.addListener(() => notified = true);
    expect(c.setTheme('vantablack'), isTrue);
    expect(saved, 'vantablack');
    expect(notified, isTrue);
    expect(c.theme.name, 'vantablack');
    expect(c.setTheme('bogus'), isFalse);
  });

  test('four themes present', () {
    expect(kThemes.keys,
        containsAll(['aether', 'catppuccin', 'vantablack', 'hackerman']));
  });
}
