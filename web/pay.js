// Opens Paddle's checkout for the transaction the server prepared
// (web/pay.html?_ptxn=txn_...&token=...). Paddle.js reads _ptxn itself; this
// only starts Paddle.js with the public client-side token, in the sandbox for a
// test token, and brings the buyer back to the app's Plans page afterwards.
(function () {
  var params = new URLSearchParams(location.search);
  var token = params.get('token') || '';
  var back = new URL('./#/plans', location.href).href;
  var status = document.getElementById('status');

  function fail() {
    document.getElementById('spin').style.display = 'none';
    status.textContent =
      'تعذّر فتح صفحة الدفع. ارجع وحاول مرة أخرى. · The checkout could not be opened. Go back and try again.';
  }

  if (!/^(test|live)_[A-Za-z0-9]+$/.test(token) || !params.get('_ptxn') ||
      typeof window.Paddle === 'undefined') {
    fail();
    return;
  }
  try {
    if (token.indexOf('test_') === 0) window.Paddle.Environment.set('sandbox');
    window.Paddle.Initialize({
      token: token,
      checkout: {
        settings: {
          displayMode: 'overlay',
          locale: (navigator.language || '').toLowerCase().indexOf('ar') === 0 ? 'ar' : 'en',
          successUrl: back,
          allowLogout: false,
        },
      },
      eventCallback: function (e) {
        if (e && e.name === 'checkout.closed') location.replace(back);
      },
    });
  } catch (_) {
    fail();
  }
})();
