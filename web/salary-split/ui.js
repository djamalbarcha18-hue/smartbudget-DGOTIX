// Wires the form on /salary-split/ to the calculator (split.js). Nothing is
// sent anywhere: the sum is done here, in the page.
(function () {
  'use strict';
  var s = window.sbSalary;
  var form = document.getElementById('split-form');
  var out = document.getElementById('result');
  if (!s || !form || !out) return;

  function val(id) { return document.getElementById(id).value; }
  function money(n) {
    var unit = val('unit').trim();
    var txt = n.toLocaleString('en-US', { maximumFractionDigits: 2 });
    return unit ? txt + ' ' + unit : txt;
  }
  function set(id, text) { document.getElementById(id).textContent = text; }

  function run() {
    var r = s.splitSalary({ income: val('income'), actualNeeds: val('actual') });
    out.hidden = !r.hasIncome;
    if (!r.hasIncome) return;
    set('needs', money(r.needs));
    set('wants', money(r.wants));
    set('savings', money(r.savings));
    set('per-year', 'الادخار في السنة: ' + money(r.savingsPerYear));
    var note = document.getElementById('actual-note');
    if (r.actualNeedsPercent > 0) {
      var pct = Math.round(r.actualNeedsPercent);
      note.hidden = false;
      note.textContent = pct > 50
        ? 'احتياجاتك الفعلية تأخذ نحو ' + pct + '% من دخلك، أي أكثر من 50%. ابدأ بخفض الرغبات قبل الادخار، أو انظر في رفع الدخل أو خفض أكبر بند.'
        : 'احتياجاتك الفعلية تأخذ نحو ' + pct + '% من دخلك، وهذا ضمن 50%. جيد.';
    } else {
      note.hidden = true;
    }
  }

  form.addEventListener('input', run);
  form.addEventListener('submit', function (e) { e.preventDefault(); run(); });
})();
