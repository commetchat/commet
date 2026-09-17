import 'page_reload_native.dart'
    if (dart.library.js_interop) 'page_reload_web.dart' as impl;

/// Reloads the browser page on web. Native has no page, so it does nothing.
void reloadPage() => impl.reloadPage();
