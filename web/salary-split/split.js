// The salary-split calculator on /salary-split/. It is the app's own
// no-history rule (lib/features/salary_split/domain/salary_split.dart):
// needs 50% and wants 30% (each rounded down, in hundredths), and savings
// are what is left, so the three always add up to the income to the cent.
// test/web_salary_page_test.dart runs this file and the app's engine on the
// same incomes and requires the same three amounts.
(function (root) {
  'use strict';

  var NEEDS = 0.50;
  var WANTS = 0.30;

  // "١٢٣٫٥", "1,234.5" and "1 234" all read as numbers; nothing else does.
  function parseAmount(text) {
    if (typeof text === 'number') return isFinite(text) && text > 0 ? text : 0;
    var s = String(text == null ? '' : text)
      .replace(/[٠-٩]/g, function (d) { return String(d.charCodeAt(0) - 0x0660); })
      .replace(/[۰-۹]/g, function (d) { return String(d.charCodeAt(0) - 0x06f0); })
      .replace(/[٫]/g, '.')
      .replace(/[٬,،\s]/g, '');
    var n = parseFloat(s);
    return isFinite(n) && n > 0 ? n : 0;
  }

  function splitSalary(i) {
    var inc = Math.round(parseAmount(i.income) * 100);     // hundredths
    var needs = Math.floor(inc * NEEDS);
    var wants = Math.floor(inc * WANTS);
    var save = inc - needs - wants;                         // the rest
    var actual = Math.round(parseAmount(i.actualNeeds) * 100);
    return {
      hasIncome: inc > 0,
      income: inc / 100,
      needs: needs / 100,
      wants: wants / 100,
      savings: save / 100,
      savingsPerYear: (save * 12) / 100,
      // The share of the income the reader's real basic costs already take,
      // when they said what those are (0 when they did not).
      actualNeedsPercent: inc > 0 && actual > 0 ? (actual / inc) * 100 : 0
    };
  }

  var api = { splitSalary: splitSalary, parseAmount: parseAmount };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.sbSalary = api;
})(typeof window !== 'undefined' ? window : this);
