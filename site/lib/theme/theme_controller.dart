import 'package:flutter/foundation.dart';
import '../platform/web_io.dart' as io;
import 'app_theme.dart';
import 'themes.dart';

const _storageKey = 'xnash.theme';

class ThemeController extends ChangeNotifier {
  final void Function(String) _save;
  late String _name;

  ThemeController({String? Function()? load, void Function(String)? save})
      : _save = save ?? ((v) => io.storageSet(_storageKey, v)) {
    final stored = (load ?? () => io.storageGet(_storageKey))();
    _name = kThemes.containsKey(stored) ? stored! : 'aether';
  }

  String get name => _name;
  AppTheme get theme => kThemes[_name]!;

  bool setTheme(String name) {
    if (!kThemes.containsKey(name)) return false;
    if (name != _name) {
      _name = name;
      _save(name);
      notifyListeners();
    }
    return true;
  }

  void cycle() {
    final names = kThemes.keys.toList();
    setTheme(names[(names.indexOf(_name) + 1) % names.length]);
  }
}
