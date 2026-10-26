{{flutter_js}}
{{flutter_build_config}}

// Started without Flutter's service worker settings: its service worker is
// deprecated and now only unregisters itself and reloads the page, which
// replaced the app's own offline copy (web/sw.js, registered by offline.js).
// That broke offline use and let a page meant for the stored copy (a shared
// bank message) go to the network.
_flutter.loader.load();
