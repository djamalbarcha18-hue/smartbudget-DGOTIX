// Runs the Cloudflare Turnstile check for the app's sign-in screens
// (web/turnstile.html) and hands the result back: to the app page that framed
// this one (web), or to the Android app's WebView bridge. Only a page on this
// same site can receive it.
(function () {
  var params = new URLSearchParams(location.search);
  var siteKey = params.get('sitekey') || '';
  var theme = params.get('theme') === 'light' ? 'light' : 'dark';
  var lang = params.get('lang') || 'auto';

  function send(msg) {
    if (window.TurnstileBridge) {
      window.TurnstileBridge.postMessage(JSON.stringify(msg));
    } else if (window.parent !== window) {
      msg.source = 'sb-turnstile';
      window.parent.postMessage(msg, location.origin);
    }
  }

  window.sbTurnstileReady = function () {
    if (!siteKey) {
      send({ type: 'error' });
      return;
    }
    window.turnstile.render('#check', {
      sitekey: siteKey,
      theme: theme,
      language: lang,
      callback: function (token) { send({ type: 'token', token: token }); },
      'error-callback': function () { send({ type: 'error' }); },
      'expired-callback': function () { send({ type: 'expired' }); },
    });
  };
})();
