# Invoice reader

Reads a receipt photo into the fields a budget needs, and checks them.

```
photo ─ image_picker (1280 px wide, up to 4096 px tall, JPEG 80)
      ─ SHA-256 ─ already read on this device? → answer from memory (no call)
      ─ cleanup (conservative): crop to the receipt, gray, stretch faded
        print; receipts taller than 3.2 × their width cut into ≤ 3
        overlapping strips. Web: the browser's own image engine
        (receipt_image_native_web.dart, ~120 ms); mobile: Dart in a
        background isolate (receipt_image_prep.dart)
      ─ receipt-scan v2: ONE Gemini call per image (strips in parallel,
        merged by _shared/invoice_merge.ts, counted as one scan), thinking
        off, structured JSON with short keys: header, item lines, totals;
        amounts copied as printed
      ─ offline (Android, no network / no cloud quota): ML Kit Latin text
        recognition → OfflineReceiptParser → the same short-key reading
      ─ InvoiceAnalyzer (on the device, pure Dart, unit tested):
          number format of the whole invoice ("1 250,50", "1,250.50",
          "1.250" decided by the other amounts or by the arithmetic),
          qty × unit = line, Σ lines = subtotal, subtotal − discount + tax =
          total (or tax already included), total − paid = due,
          currency from code + printed sign, date sanity,
          confidence per field, review level (verified / warning / review)
      ─ InvoiceReviewSheet: header, items, totals, ✓ Verified / ⚠ Needs
        review; flagged lines can be corrected; "may be a duplicate" hint
      ─ Add expense (prefilled: total, supplier, date, category, and the
        products in the note)
```

- Never invented: a value that is not printed stays null; a missing total is
  calculated and labelled "calculated"; mismatches are shown, never fixed.
- Ignored by the prompt and never returned: logos, addresses, phones, cashier
  names, terminal / authorization / transaction numbers, card numbers (also
  masked server-side and on the device if copied), QR codes, ads.
- The image is not stored anywhere; the device keeps only the last 30
  readings (no images) per user to answer rescans and spot duplicates.
- Thresholds: `ReviewPolicy` (accept ≥ 0.90, review < 0.70).
- Older app versions keep using v1 of the same function (total only).

Files: `lib/features/receipts/` (domain: `invoice_amounts.dart`,
`invoice_analyzer.dart`, `invoice_reading.dart`, `invoice_duplicates.dart`;
data: `gemini_online_engine.dart`, `receipt_scan_cache.dart`; application:
`receipt_scan_controller.dart`; presentation: `invoice_review_sheet.dart`,
`receipt_scan_button.dart`) and `supabase/functions/receipt-scan/index.ts`.

Tests: `test/invoice_amounts_test.dart`, `test/invoice_reader_fixtures_test.dart`
(80 invoices: simple, supermarket, long, French, English, Arabic, mixed, low
quality), `test/invoice_duplicates_test.dart`, `test/invoice_review_sheet_test.dart`.
