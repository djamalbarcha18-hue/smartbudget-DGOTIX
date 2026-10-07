// Installs the offline support (web/sw.js) once the page has loaded, so the
// app opens and works with no internet afterwards.
if ('serviceWorker' in navigator && (location.protocol === 'https:' ||
    location.hostname === 'localhost' || location.hostname === '127.0.0.1')) {
  window.addEventListener('load', function () {
    navigator.serviceWorker
      .register('sw.js', { scope: './', updateViaCache: 'none' })
      .catch(function () { /* Offline support is a bonus, never an error. */ });
  });
}
