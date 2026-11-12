// Shows Google's «Continue with Google» button (web/google_signin.html) and
// hands the ID token back to the app page that framed this one. Only a page
// on this same site can receive it.
(function () {
  var params = new URLSearchParams(location.search);
  var clientId = params.get('client_id') || '';
  var nonce = params.get('nonce') || '';
  var light = params.get('theme') === 'light';
  var lang = params.get('lang') || '';
  var width = parseInt(params.get('width') || '0', 10);

  function send(msg) {
    if (window.parent === window) return;
    msg.source = 'sb-google';
    window.parent.postMessage(msg, location.origin);
  }

  // Called by Google's script once it has loaded.
  window.onGoogleLibraryLoad = function () {
    var id = window.google && window.google.accounts && window.google.accounts.id;
    if (!clientId || !nonce || !id) {
      send({ type: 'error' });
      return;
    }
    id.initialize({
      client_id: clientId,
      nonce: nonce,
      ux_mode: 'popup',
      auto_select: false,
      itp_support: true,
      callback: function (r) {
        if (r && r.credential) {
          send({ type: 'credential', token: r.credential });
        } else {
          send({ type: 'error' });
        }
      },
    });
    var options = {
      type: 'standard',
      theme: light ? 'outline' : 'filled_black',
      size: 'large',
      text: 'continue_with',
      shape: 'rectangular',
      logo_alignment: 'center',
    };
    if (width >= 200) options.width = Math.min(width, 400);
    if (lang) options.locale = lang;
    id.renderButton(document.getElementById('button'), options);
    send({ type: 'ready' });
  };
})();
