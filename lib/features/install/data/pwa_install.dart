/// Installing the web app on the home screen (PWA). The web implementation
/// reads the prompt captured in web/index.html; elsewhere nothing applies.
library;

export 'pwa_install_stub.dart' if (dart.library.js_interop) 'pwa_install_web.dart';
