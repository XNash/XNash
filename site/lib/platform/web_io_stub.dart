// Non-web fallback (used by VM tests): no persistence, no window.
String? storageGet(String key) => null;
void storageSet(String key, String value) {}
void openUrl(String url) {}
