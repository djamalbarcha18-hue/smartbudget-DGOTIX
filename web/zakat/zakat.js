// The zakat calculator on /zakat/. The rules are the app's own
// (lib/features/zakat/domain/zakat_calculator.dart): nisab is 85 g of gold or
// 595 g of silver, the rate is 2.5% on the net wealth, and it is due only once
// the hawl (a full lunar year) has passed. test/web_zakat_page_test.dart runs
// this file and the app's engine on the same inputs and requires the same
// answer.
(function (root) {
  'use strict';

  var GOLD_NISAB_GRAMS = 85;
  var SILVER_NISAB_GRAMS = 595;
  var RATE = 0.025;

  // "١٢٣٫٥" and "1,234.5" and "1 234" all read as numbers; nothing else does.
  function parseAmount(text) {
    if (typeof text === 'number') return isFinite(text) && text >= 0 ? text : 0;
    var s = String(text == null ? '' : text)
      .replace(/[٠-٩]/g, function (d) { return String(d.charCodeAt(0) - 0x0660); })
      .replace(/[۰-۹]/g, function (d) { return String(d.charCodeAt(0) - 0x06f0); })
      .replace(/[٫]/g, '.')
      .replace(/[٬,،\s]/g, '');
    var n = parseFloat(s);
    return isFinite(n) && n > 0 ? n : 0;
  }

  // Whole minor units (hundredths), as the app counts, so both agree to the cent.
  function minor(x) { return Math.round(x * 100); }

  function computeZakat(i) {
    var goldPrice = parseAmount(i.goldPrice);
    var silverPrice = parseAmount(i.silverPrice);
    var nisabGold = minor(GOLD_NISAB_GRAMS * goldPrice);
    var nisabSilver = minor(SILVER_NISAB_GRAMS * silverPrice);
    var standard = i.standard === 'silver' ? 'silver' : 'gold';
    var nisab = standard === 'silver' ? nisabSilver : nisabGold;

    var assets = minor(parseAmount(i.cash)) + minor(parseAmount(i.metals)) +
      minor(parseAmount(i.trade)) + minor(parseAmount(i.receivables));
    var liabilities = minor(parseAmount(i.liabilities));
    var net = Math.max(0, assets - liabilities);

    var nisabKnown = nisab > 0;
    var reached = nisabKnown && net >= nisab;
    var hawl = i.hawlComplete === true;
    var owed = reached ? Math.round(net * RATE) : 0; // if the hawl is complete
    var due = hawl ? owed : 0;

    // Why the answer is what it is, for the page to say in words.
    var state = !nisabKnown ? 'needPrice'
      : !reached ? 'belowNisab'
      : !hawl ? 'waitHawl'
      : 'due';

    return {
      assets: assets / 100,
      liabilities: liabilities / 100,
      net: net / 100,
      nisab: nisab / 100,
      state: state,
      due: due / 100,
      // What it would be once the hawl completes, if the wealth stays as is.
      ifHawl: owed / 100
    };
  }

  var api = { computeZakat: computeZakat, parseAmount: parseAmount };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.sbZakat = api;
})(typeof window !== 'undefined' ? window : this);
