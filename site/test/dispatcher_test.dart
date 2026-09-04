import 'package:flutter_test/flutter_test.dart';
import 'package:xnash_portfolio/keymap/dispatcher.dart';

void main() {
  final d = KeyDispatcher();

  test('j scrolls down in normal', () {
    expect(d.feed('j', UiMode.normal), const ScrollDown());
  });

  test('gg goes top', () {
    expect(d.feed('g', UiMode.normal), isNull);
    expect(d.feed('g', UiMode.normal), const ScrollTop());
  });

  test('stray key clears pending', () {
    d.feed('g', UiMode.normal);
    expect(d.feed('x', UiMode.normal), isNull);
    expect(d.feed('g', UiMode.normal), isNull);
    d.feed('x', UiMode.normal);
  });

  test('space then f opens finder', () {
    expect(d.feed(' ', UiMode.normal), const OpenWhichKey());
    expect(d.feed('f', UiMode.whichkey), const OpenFinder());
  });

  test('t in whichkey cycles theme', () {
    expect(d.feed('t', UiMode.whichkey), const CycleTheme());
  });

  test('escape closes overlays', () {
    expect(d.feed('Escape', UiMode.finder), const CloseOverlay());
    expect(d.feed('Escape', UiMode.whichkey), const CloseOverlay());
  });

  test('bracket b buffer nav', () {
    expect(d.feed(']', UiMode.normal), isNull);
    expect(d.feed('b', UiMode.normal), const NextBuffer());
    expect(d.feed('[', UiMode.normal), isNull);
    expect(d.feed('b', UiMode.normal), const PrevBuffer());
  });

  test('H and L switch buffers, G goes bottom, colon opens cmdline', () {
    expect(d.feed('H', UiMode.normal), const PrevBuffer());
    expect(d.feed('L', UiMode.normal), const NextBuffer());
    expect(d.feed('G', UiMode.normal), const ScrollBottom());
    expect(d.feed(':', UiMode.normal), const OpenCmdline());
  });

  test('arrows move selection in finder, enter confirms', () {
    expect(d.feed('ArrowDown', UiMode.finder), const MoveSelectionDown());
    expect(d.feed('ArrowUp', UiMode.finder), const MoveSelectionUp());
    expect(d.feed('Enter', UiMode.finder), const ConfirmSelection());
  });
}
