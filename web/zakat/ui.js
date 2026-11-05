// Wires the form on /zakat/ to the calculator (zakat.js). Nothing is sent
// anywhere: the sum is done here, in the page.
(function () {
  'use strict';
  var z = window.sbZakat;
  var form = document.getElementById('zakat-form');
  var out = document.getElementById('result');
  var std = document.getElementById('standard');
  var silverRow = document.getElementById('silver-row');
  if (!z || !form || !out) return;

  function val(id) { return document.getElementById(id).value; }
  function money(n) {
    var unit = val('unit').trim();
    var txt = n.toLocaleString('en-US', { maximumFractionDigits: 2 });
    return unit ? txt + ' ' + unit : txt;
  }

  function sayState(r) {
    switch (r.state) {
      case 'needPrice':
        return ['neutral', 'أدخل سعر غرام الذهب (أو الفضة) لنحسب النصاب.', ''];
      case 'belowNisab':
        return ['ok', 'لا زكاة عليك الآن.',
          'صافي مالك ' + money(r.net) + ' أقل من النصاب ' + money(r.nisab) + '.'];
      case 'waitHawl':
        return ['wait', 'بلغ مالك النصاب، لكن لم يحُل الحول بعد.',
          'صافي مالك ' + money(r.net) + ' والنصاب ' + money(r.nisab) +
          '. تجب الزكاة عند تمام سنة هجرية كاملة، وقدرها عندئذ نحو ' +
          money(r.ifHawl) + ' إن بقي المال كما هو.'];
      default:
        return ['due', 'زكاتك الواجبة: ' + money(r.due),
          '2.5% من صافي مالك ' + money(r.net) + ' (النصاب ' + money(r.nisab) + ').'];
    }
  }

  function run() {
    var r = z.computeZakat({
      standard: std.value,
      goldPrice: val('gold'),
      silverPrice: val('silver'),
      cash: val('cash'),
      metals: val('metals'),
      trade: val('trade'),
      receivables: val('receivables'),
      liabilities: val('liabilities'),
      hawlComplete: document.getElementById('hawl').checked
    });
    var s = sayState(r);
    out.className = 'result ' + s[0];
    out.hidden = false;
    out.querySelector('.headline').textContent = s[1];
    out.querySelector('.detail').textContent = s[2];
  }

  function syncStandard() { silverRow.hidden = std.value !== 'silver'; }

  std.addEventListener('change', function () { syncStandard(); run(); });
  form.addEventListener('input', run);
  form.addEventListener('submit', function (e) { e.preventDefault(); run(); });
  syncStandard();
})();
