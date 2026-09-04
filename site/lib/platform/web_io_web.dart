import 'package:web/web.dart' as web;

String? storageGet(String key) {
  try {
    return web.window.localStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

void storageSet(String key, String value) {
  try {
    web.window.localStorage.setItem(key, value);
  } catch (_) {}
}

void openUrl(String url) {
  try {
    web.window.open(url, '_blank');
  } catch (_) {}
}
